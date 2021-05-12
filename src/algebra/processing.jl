## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed∘getvalue, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

adjust_index(ax, idx::Int) = length(ax) == 1 ? 1 : idx
adjust_index(ax, idxs::AbstractArray) = length(ax) == 1 ? one.(idxs) : idxs
adjust_index(ax, idxs::Colon) = idxs

getnewindex(v, i) = v[Broadcast.newindex(v, i)]

function subselect(labeledarray::Labeled, idxs, c::CartesianIndex=CartesianIndex())
    labels, array = getlabel(labeledarray), getvalue(labeledarray)
    I = ntuple(ndims(array)) do n
        i = n == 1 ? idxs : c[n-1]
        return adjust_index(axes(array, n), i)
    end
    return Labeled(getnewindex(labels, c), view(array, I...))
end

splitapply(le::Entry) = splitapply(identity, le)

function splitapply(f, le::Entry)
    positional, named = le.positional, le.named
    axs = Broadcast.combine_axes(map(getvalue, positional)..., map(getvalue, named)...)
    discrete, continuous = separate(named) do lv
        v = getvalue(lv)
        return v isa AbstractVector && !iscontinuous(v)
    end
    list = Entry[]
    foreach(indices_iterator(discrete)) do idxs
        for c in CartesianIndices(tail(axs))
            subpositional, subcontinuous = nested_map((positional, continuous)) do l
                return subselect(l, idxs, c)
            end
            subdiscrete = map(v -> subselect(v, first(idxs)), discrete)
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
    positional, named = nested_map((positional′, named′)) do x
        return map(y -> NameTransformationLabel(data, y), maybewrap(x))
    end
    axs = Broadcast.combine_axes(positional..., named...)
    labeledarrays = nested_map((positional, named)) do ntls
        nested = map(ntls) do ntl
            cols = apply_context(data, axs, maybewrap(ntl.name))
            return map(ntl.transformation, cols...)
        end
        return Labeled(map(ntl -> ntl.label, ntls), unnest(nested))
    end
    return Entry(Any, labeledarrays..., Dict{Symbol, Any}())
end

process_data(layer::Layer) = process_data(layer.data, layer.positional, layer.named)

process_transformations(layers::Layers) = map(process_transformations, layers)

function process_transformations(layer::Layer)
    init = process_data(layer)
    res = foldl(process_transformations, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process_transformations(v::AbstractArray{Entry}, f) = map(f, v)

process_transformations(le::Entry, f) = f(le)
