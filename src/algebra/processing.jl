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

function splitapply(f, entry::Entry)
    entries = Entry[]
    for I in Iterators.product(shape(entry)...)
        primary, positional, named = map((entry.primary, entry.positional, entry.named)) do tup
            return map(v -> v[I...], tup)
        end
        c = CartesianIndex(tail(I))
        labels = Dict{KeyType, Any}()
        for (k, s) in pairs(entry.labels)
            v = Broadcast.broadcastable(s)
            labels[k] = v[Broadcast.newindex(v, c)]
        end
        input = Entry(entry; primary, positional, named, labels)
        output = f(input)
        isa(output, Entry) ? push!(entries, output) : append!(entries, output)
    end
    return entries
end

assert_equal(a, b) = (@assert(isequal(a, b)); a)
getuniquevalue(v) = reduce(assert_equal, v)

haszerodims(::AbstractArray) = false
haszerodims(::AbstractArray{<:Any, 0}) = true
haszerodims(::Ref) = true
haszerodims(::Tuple) = false

function subgroups(vs, perm, rgs, axs)
    return map(Iterators.product(rgs, CartesianIndices(axs))) do (rg, c)
        v = vs[Broadcast.newindex(vs, c)]
        return haszerodims(v) || rg === (:) ? v : view(v, perm[rg])
    end
end

function group(entry::Entry)
    grouping = foldl(entry.primary, init=()) do acc, v
        return haszerodims(v) ? (acc..., only(v)) : acc
    end
    perm, rgs = permutation_ranges(grouping)
    axs = CartesianIndices(shape(entry))
    primary′, positional, named = map((entry.primary, entry.positional, entry.named)) do tup
        return map(vs -> subgroups(vs, perm, rgs, axs), tup)
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
    axs = shape(layer)
    primary_pairs, positional_list, named_pairs = [], [], []
    for c in (layer.positional, layer.named)
        for (key, val) in pairs(c)
            if isdimsselector(val)
                vs, (f, label) = select(layer.data, val)
                d = only(vs) # multiple dims selectors in same mapping are disallowed
                sz = ntuple(length(axs)) do n
                    return n in d.dims ? length(axs[n]) : 1
                end
                arr = map(fill∘f, CartesianIndices(sz))
            else
                vals = val isa ArrayLike ? val : fill(val)
                labeled_arr = map(vals) do s
                    local vs, (f, label) = select(layer.data, s)
                    return label, map(f, vs...)
                end
                label, arr = map(first, labeled_arr), map(last, labeled_arr)
            end
            labels[key] = label
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
    return Entry(; primary, positional, named, labels)
end

function process(layer::Layer)
    init = group(to_entry(layer))
    res = foldl(process, layer.transformations; init)
    return res isa Entry ? splitapply(identity, res) : res
end

process(v::AbstractArray{Entry}, f) = map(f, v)

process(le::Entry, f) = f(le)
