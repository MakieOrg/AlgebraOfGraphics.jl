## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

function subselect(arr, idxs, c′::CartesianIndex)
    c = Broadcast.newindex(CartesianIndices(tail(axes(arr))), c′)
    return view(arr, idxs, Tuple(c)...)
end

function shape(entry::Entry)
    tup = (entry.primary..., entry.positional..., entry.named...)
    return Broadcast.combine_axes(map(maybewrap, tup)...)
end

function shape(layer::Layer)
    tup = (layer.positional..., layer.named...)
    return Broadcast.combine_axes(map(maybewrap, tup)...)
end

splitapply(entry::Entry) = splitapply(identity, entry)

function splitapply(f, entry::Entry)
    axs = shape(entry)
    grouping = filter(Tuple(entry.primary)) do v
        return v isa AbstractVector
    end
    entries = Entry[]
    foreach(indices_iterator(grouping)) do idxs
        for c in CartesianIndices(tail(axs))
            selector = arr -> subselect(arr, idxs, c)
            positional = map(selector, entry.positional)
            named = map(selector, entry.named)

            primary = map(entry.primary) do arr
                i = if idxs === Colon() || size(arr, 1) == 1
                    firstindex(arr, 1)
                else
                    first(idxs)
                end
                return subselect(arr, i, c)
            end

            labels = copy(entry.labels)
            map!(values(labels)) do l
                w = maybewrap(l)
                return w[Broadcast.newindex(w, c)]
            end

            input = Entry(entry; primary, positional, named, labels)

            # TODO: for analyses returning several entries, rearrange in correct order.
            append!(entries, maybewrap(f(input)))
        end
    end
    return entries
end

## Transform `Layers` into list of `Entry`

function unnest(arr::AbstractArray{<:AbstractArray})
    inner_size = mapreduce(size, assert_equal, arr)
    outer_size = size(arr)
    flattened = reduce(vcat, map(vec, vec(arr)))
    return reshape(flattened, inner_size..., outer_size...)
end

unnest(arr::NTuple{<:Any, <:AbstractArray}) = unnest(collect(arr))

# FIXME: can this be simplified?
"""
    to_entry(layer::Layer)

Convert `layer` to equivalent entry, excluding transformations.
"""
function to_entry(layer::Layer)
    axs = shape(layer)
    labels = Dict{KeyType, Any}()
    primary_pairs, positional_list, named_pairs = [], [], []
    for c in (layer.positional, layer.named)
        for (key, val) in pairs(c)
            ntls = map(maybewrap(val)) do t
                return NameTransformationLabel(layer.data, t)
            end
            labels[key] = map(ntl -> ntl.label, ntls)
            nested = map(ntls) do ntl
                cols = apply_context(layer.data, axs, maybewrap(ntl.name))
                return map(ntl.transformation, cols...)
            end
            v = unnest(nested)
            isdims = any(ntl -> ntl.name isa DimsSelector, ntls)
            isprimary = isdims || !iscontinuous(v)
            if key isa Int
                push!(positional_list, v)
            elseif isprimary
                push!(primary_pairs, key => v)
            else
                push!(named_pairs, key => v)
            end
        end
    end
    primary = NamedTuple(primary_pairs)
    positional = Tuple(positional_list)
    named = NamedTuple(named_pairs)
    return Entry(; primary, positional, named, labels)
end

function process(layer::Layer)
    init = to_entry(layer)
    res = foldl(process, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process(v::AbstractArray{Entry}, f) = map(f, v)

process(le::Entry, f) = f(le)
