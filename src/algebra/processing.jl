## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function permutation_ranges(cols)
    isempty(cols) && return nothing, [:]
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return sortperm(gp), collect(gp)
end

allvariables(e::Entry) = (e.primary..., e.positional..., e.named...)
allvariables(l::Layer) = (l.positional..., l.named...)

function shape(x::Union{Entry, Layer})
    arrays = map(var -> var isa ArrayLike ? var : fill(nothing), allvariables(x))
    return Broadcast.combine_axes(arrays...)
end

assert_equal(a, b) = (@assert(isequal(a, b)); a)
getuniquevalue(v) = reduce(assert_equal, v)

haszerodims(::AbstractArray) = false
haszerodims(::AbstractArray{<:Any, 0}) = true
haszerodims(::Ref) = true
haszerodims(::Tuple) = false

function getnewindex(u, c)
    v = Broadcast.broadcastable(u)
    return v[Broadcast.newindex(v, c)]
end

function subgroups(vs, perm, rgs, axs)
    return map(Iterators.product(rgs, CartesianIndices(axs))) do (rg, c)
        v = getnewindex(vs, c)
        return haszerodims(v) || rg === (:) ? v : view(v, perm[rg])
    end
end

shiftdims(v::AbstractArray) = reshape(v, 1, axes(v)...)
shiftdims(v::Tuple) = shiftdims(collect(v))
shiftdims(v) = v

function group(entry::Entry)
    grouping = foldl(entry.primary, init=()) do acc, v
        return haszerodims(v) ? (acc..., only(v)) : acc
    end
    perm, rgs = permutation_ranges(grouping)
    axs = shape(entry)
    primary′, positional, named = map((entry.primary, entry.positional, entry.named)) do tup
        return map(vs -> subgroups(vs, perm, rgs, axs), tup)
    end
    primary = map(vs -> map(getuniquevalue, vs), primary′)
    labels = copy(entry.labels)
    map!(shiftdims, values(labels))
    return Entry(entry; primary, positional, named, labels)
end

function getlabeledarray(layer::Layer, selector::Union{DimsSelector, Pair{<:DimsSelector}})
    axs = shape(layer)
    vs, (f, label) = select(layer.data, selector)
    d = only(vs) # multiple dims selectors in the same mapping are disallowed
    sz = ntuple(length(axs)) do n
        return n in d.dims ? length(axs[n]) : 1
    end
    arr = map(fill∘f, CartesianIndices(sz))
    return label, arr
end

getlabeledarray(layer::Layer, selector) = getlabeledarray(layer, fill(selector))

function getlabeledarray(layer::Layer, selector::ArrayLike)
    labeled_arr = map(selector) do s
        local vs, (f, label) = select(layer.data, s)
        return label, map(f, vs...)
    end
    return map(first, labeled_arr), map(last, labeled_arr)
end

function separate(nt::NamedTuple)
    continuous_keys = filter(key -> all(iscontinuous, nt[key]), keys(nt))
    continuous = NamedTuple{continuous_keys}(nt)
    return Base.structdiff(nt, continuous), continuous
end

"""
    to_entry(layer::Layer)

Convert `layer` to equivalent entry, excluding transformations.
"""
function to_entry(layer::Layer)
    labels = Dict{KeyType, Any}()
    positional, named′ = map((layer.positional, layer.named)) do tup
        return mapkeys(tup) do key            
            label, arr = getlabeledarray(layer, tup[key])
            labels[key] = label
            return arr
        end
    end
    primary, named = separate(named′)
    return Entry(; primary, positional, named, labels)
end

function process(layer::Layer)
    init = group(to_entry(layer))
    return foldl(|>, layer.transformations; init)
end
