## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function permutation_ranges(cols)
    isempty(cols) && return [:], nothing
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

function splitapply(f, entry::Entry)
    

end

assert_equal(a, b) = (@assert(a == b); a)
getuniquevalue(v) = reduce(assert_equal, v)

function subgroups(v, perm, rgs, axs)
    return map(Iterators.product(rgs, CartesianIndices(axs))) do (rg, c)
        u = v[Broadcast.newindex(v, c)]
        if rg === (:)
            return u
        else
            idxs = [clamp(perm[i], axes(u, 1)) for i in rg]
            return view(u, idxs)
        end
    end
end

function group(entry::Entry)
    grouping = foldl(entry.primary, init=()) do acc, v
        return isempty(size(v)) ? (acc..., only(v)) : acc
    end
    perm, rgs = permutation_ranges(grouping)
    axs = CartesianIndices(shape(entry))
    primary′, positional, named = map((entry.primary, entry.positional, entry.named)) do tup
        return map(v -> subgroups(v, perm, rgs, axs), tup)
    end
    primary = map(vs -> map(getuniquevalue, vs), primary′)
    return Entry(entry; primary, positional, named)
end

"""
    to_entry(layer::Layer)

Convert `layer` to equivalent entry, excluding transformations.
"""
function to_entry(layer::Layer)
    labels = Dict{KeyType, Any}()
    primary_pairs, positional_list, named_pairs = [], [], []
    for c in (layer.positional, layer.named)
        for (key, val) in pairs(c)
            l, arr = getlabeledarray(layer, val)
            labels[key] = l
            if key isa Int
                push!(positional_list, arr)
            elseif all(iscontinuous, arr)
                push!(named_pairs, key => arr)
            else
                push!(primary_pairs, key => arr)
            end
        end
    end
    primary = NamedTuple(primary_pairs)
    positional = Tuple(positional_list)
    named = NamedTuple(named_pairs)
    return group(Entry(; primary, positional, named, labels))
end

function process(layer::Layer)
    init = to_entry(layer)
    res = foldl(process, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process(v::AbstractArray{Entry}, f) = map(f, v)

process(le::Entry, f) = f(le)
