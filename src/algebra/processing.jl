## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function permutation_ranges(cols)
    isempty(cols) && return nothing, [:]
    grouping_sa = StructArray(map(fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return sortperm(gp), collect(gp)
end

allvariables(e::Entry) = vcat(values(e.primary), values(e.positional), values(e.named))
allvariables(l::Layer) = vcat(values(l.positional), values(l.named))

function shape(x::Union{Entry, Layer})
    arrays = map(var -> var isa ArrayLike ? var : fill(nothing), allvariables(x))
    return Broadcast.combine_axes(arrays...)
end

function assert_equal(a, b)
    if !isequal(a, b)
        msg = "$a and $b must be equal"
        throw(ArgumentError(msg))
    end
    return a
end

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
    grouping = Tuple(only(v) for v in values(entry.primary) if haszerodims(v))
    perm, rgs = permutation_ranges(grouping)
    axs = shape(entry)
    primary, positional, named = map((entry.primary, entry.positional, entry.named)) do vars
        return map(vs -> subgroups(vs, perm, rgs, axs), vars)
    end
    labels = copy(entry.labels)
    map!(shiftdims, values(labels))
    return Entry(entry; primary, positional, named, labels)
end

function ungroup(entry::Entry)

end

function getlabeledarray(layer::Layer, s)
    data, axs = layer.data, shape(layer)
    isdims = s isa DimsSelector || s isa Pair && first(s) isa DimsSelector
    if isdims
        vs, (f, label) = select(data, s)
        d = only(vs) # multiple dims selectors in the same mapping are disallowed
        sz = ntuple(length(axs)) do n
            return n in d.dims ? length(axs[n]) : 1
        end
        arr = map(fill∘f, CartesianIndices(sz))
    elseif isnothing(data)
        vs, (f, label) = select(data, s)
        isprim = any(hascategoricalentry, vs)
        arr = isprim ? map(fill∘f, vs...) : map(x -> map(f, x...), zip(vs...)) 
    else
        selector = s isa AbstractArray ? s : fill(s)
        labeled_arr = map(selector) do s
            local vs, (f, label) = select(data, s)
            return label, map(f, vs...)
        end
        label, arr = map(first, labeled_arr), map(last, labeled_arr)
    end
    return label, arr
end

function process_mappings(layer::Layer)
    labels = Dict{KeyType, Any}()
    positional, named = map((layer.positional, layer.named)) do tup
        return map_pairs(tup) do (key, value)
            label, arr = getlabeledarray(layer, value)
            labels[key] = label
            return arr
        end
    end
    primary = splice_if!(hascategoricalentry, named)
    e = Entry(; primary, positional, named, labels)
    entries = Entry[]
    for c in CartesianIndices(shape(e))
        primary, positional, named = map((e.primary, e.positional, e.named)) do tup
            return map(v -> getnewindex(v, c), tup)
        end
        push!(entries, Entry(e; primary, positional, named))
    end
    return Entries(entries)
end

"""
    to_entries(layer::Layer)

Convert `layer` to equivalent entries, excluding transformations.
"""
function to_entries(layer::Layer)
    entry = process_mappings(layer)
    grouped_entry = isnothing(layer.data) ? entry : group(entry)
    primary = map(vs -> map(getuniquevalue, vs), grouped_entry.primary)
    e = Entry(grouped_entry; primary)
    entries = Entry[]
    for c in CartesianIndices(shape(grouped_entry))
        primary, positional, named = map((e.primary, e.positional, e.named)) do tup
            return map(v -> getnewindex(v, c), tup)
        end
        push!(entries, Entry(e; primary, positional, named))
    end
    return Entries(entries)
end

process(layer::Layer) = layer.transformation(to_entries(layer))
