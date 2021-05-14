## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return (:,)
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

function validprimaryindices(v, idxs, c::CartesianIndex)
    i = idxs === (:) ? firstindex(v, 1) : clamp(first(idxs), axes(v, 1))
    t = validtailindices(v, c)
    return (i, t...)
end

validtailindices(v, c::CartesianIndex) =
    Tuple(Broadcast.newindex(CartesianIndices(tail(axes(v))), c))

validindices(v, c::CartesianIndex) = Tuple(Broadcast.newindex(v, c))

function subgroup(e::Entry, idxs, c::CartesianIndex)
    primary = map(v -> view(v, validprimaryindices(v, idxs, c)...), e.primary)
    positional = map(v -> view(v, idxs, validtailindices(v, c)...), e.positional)
    named = map(v -> view(v, idxs, validtailindices(v, c)...), e.named)
    labels = copy(e.labels)
    map!(values(labels)) do l
        l′ = Broadcast.broadcastable(l)
        return l′[validindices(l′, c)...]
    end
    return Entry(e; primary, positional, named, labels)
end

allvariables(e::Entry) = (e.primary..., e.positional..., e.named...)
allvariables(l::Layer) = (l.positional..., l.named...)

maybewrap(x::ArrayLike) = x
maybewrap(x) = fill(x)

function shape(x::Union{Entry, Layer})
    vars = map(maybewrap, allvariables(x))
    return Broadcast.combine_axes(vars...)
end

splitapply(entry::Entry) = splitapply(identity, entry)

function splitapply(f, entry::Entry)
    axs = shape(entry)
    grouping = filter(v -> v isa AbstractVector, Tuple(entry.primary))
    entries = Entry[]
    foreach(indices_iterator(grouping)) do idxs
        for c in CartesianIndices(tail(axs))
            # TODO: for analyses returning several entries, rearrange in correct order.
            append!(entries, maybewrap(f(subgroup(entry, idxs, c))))
        end
    end
    return entries
end

## Transform `Layers` into list of `Entry`

assert_equal(a, b) = (@assert(a == b); a)

function unnest(arr::AbstractArray{<:AbstractArray})
    inner_size = mapreduce(size, assert_equal, arr)
    outer_size = size(arr)
    flattened = reduce(vcat, map(vec, vec(arr)))
    return reshape(flattened, inner_size..., outer_size...)
end

unnest(arr::NTuple{<:Any, <:AbstractArray}) = unnest(collect(arr))

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
