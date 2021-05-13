## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed∘getvalue, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

function adjust_index(axs::NTuple{N, Any}, c::CartesianIndex) where N
    return ntuple(N) do n
        ax = axs[n]
        return length(ax) == 1 ? only(ax) : c[n]
    end
end

function subselect(labeledarray::Labeled, idxs, c::CartesianIndex)
    labels, array = maybewrap(getlabel(labeledarray)), getvalue(labeledarray)
    label = labels[adjust_index(axes(labels), c)...]
    subarray = view(array, idxs, adjust_index(tail(axes(array)), c)...)
    return Labeled(label, subarray)
end

splitapply(le::Entry) = splitapply(identity, le)

function splitapply(f, le::Entry)
    positional, named = le.positional, le.named
    axs = Broadcast.combine_axes(map(getvalue, positional)..., map(getvalue, named)...)
    discrete, continuous = separate(lv -> !iscontinuous(getvalue(lv)), named)
    grouping = filter(lv -> isa(getvalue(lv), AbstractVector), Tuple(discrete))
    list = Entry[]
    foreach(indices_iterator(grouping)) do idxs
        for c in CartesianIndices(tail(axs))
            subpositional, subcontinuous = nested_map((positional, continuous)) do l
                return subselect(l, idxs, c)
            end
            subdiscrete = map(discrete) do l
                v = getvalue(l)
                i = idxs === Colon() || size(v, 1) == 1 ? firstindex(v, 1) : first(idxs)
                return subselect(l, i, c)
            end
            new_entries = f(Entry(le.plottype, subpositional, subcontinuous, le.attributes))
            for new_entry in maybewrap(new_entries)
                push!(
                    list,
                    Entry(
                        new_entry.plottype,
                        new_entry.positional,
                        merge(subdiscrete, new_entry.named),
                        new_entry.attributes
                    )
                )
            end
        end
    end
    return list
end

## Transform `Layers` into list of `Entry`

nested_map(f, (a, b)::Tuple) = map(f, a), map(f, b)

function unnest(arr::AbstractArray{<:AbstractArray})
    inner_size = mapreduce(size, assert_equal, arr)
    outer_size = size(arr)
    flattened = reduce(vcat, map(vec, vec(arr)))
    return reshape(flattened, inner_size..., outer_size...)
end

unnest(arr::NTuple{<:Any, <:AbstractArray}) = unnest(collect(arr))

function process_data(data, positional′, named′)
    axs = Broadcast.combine_axes(positional′..., named′...)
    labels = Dict{KeyType, Any}()
    primary, positional, named = [], [], []
    for c in (positional′, named′)
        for (key, val) in pairs(c)
            ntls = map(y -> NameTransformationLabel(data, y), val)
            labels[key] = map(ntl -> ntl.label, ntls)
            nested = map(ntls) do ntl
                cols = apply_context(data, axs, maybewrap(ntl.name))
                return map(ntl.transformation, cols...)
            end
            v = unnest(nested)
            if key isa Int
                push!(positional, v)
            elseif any(ntl -> ntl.name isa DimsSelector, ntls) || !iscontinuous(v)
                push!(primary, key => v)
            else
                push!(named, key => v)
            end
        end
    end
    return Entry(Any, (; primary...), Tuple(positional), (; named...), labels)
end

function process_data(layer::Layer)
    positional, named = map(maybewrap, layer.positional), map(maybewrap, layer.named)
    return process_data(layer.data, positional, named)
end

process_transformations(layers::Layers) = map(process_transformations, layers)

function process_transformations(layer::Layer)
    init = process_data(layer)
    res = foldl(process_transformations, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process_transformations(v::AbstractArray{Entry}, f) = map(f, v)

process_transformations(le::Entry, f) = f(le)
