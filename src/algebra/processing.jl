## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function permutation_ranges(cols)
    isempty(cols) && return nothing, [:]
    grouping_sa = StructArray(map(fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return sortperm(gp), collect(gp)
end

concatenate_values(args...) = mapreduce(values, append!, args, init=Any[])

allvariables(pl::ProcessedLayer) = concatenate_values(pl.primary, pl.positional, pl.named)
allvariables(l::Layer) = concatenate_values(l.positional, l.named)

function shape(x::Union{ProcessedLayer, Layer})
    arrays = map(var -> var isa AbstractArray ? var : fill(nothing), allvariables(x))
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

function group(processedlayer::ProcessedLayer)
    grouping = Tuple(only(v) for v in values(processedlayer.primary) if haszerodims(v))
    perm, rgs = permutation_ranges(grouping)
    axs = shape(processedlayer)

    primary = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.primary)
    positional = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.positional)
    named = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.named)

    labels = map(shiftdims, processedlayer.labels)
    return ProcessedLayer(processedlayer; primary, positional, named, labels)
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
        isprim = any(iscategoricalcontainer, vs)
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

function extract_values!(pairs, labels)
    merge!(labels, Dictionary(map(first, pairs)))
    return map(last, pairs)
end

function process_mappings(layer::Layer)
    labels = MixedArguments()
    positional = extract_values!(map(v -> getlabeledarray(layer, v), layer.positional), labels)
    named = extract_values!(map(v -> getlabeledarray(layer, v), layer.named), labels)
    primary, named = separate(iscategoricalcontainer, named)
    return ProcessedLayer(; primary, positional, named, labels)
end
