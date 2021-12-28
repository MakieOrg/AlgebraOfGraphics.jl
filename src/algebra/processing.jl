## Format for layer after processing

Base.@kwdef struct ProcessedLayer
    plottype::PlotFunc=Any
    primary::NamedArguments=NamedArguments()
    positional::Arguments=Arguments()
    named::NamedArguments=NamedArguments()
    labels::MixedArguments=MixedArguments()
    attributes::NamedArguments=NamedArguments()
end

function Base.get(pl::ProcessedLayer, key::Int, default)
    return key in keys(pl.positional) ? pl.positional[key] : default
end

function Base.get(pl::ProcessedLayer, key::Symbol, default)
    return get(pl.named, key, default)
end

function ProcessedLayer(pl::ProcessedLayer; kwargs...)
    nt = (; pl.plottype, pl.primary, pl.positional, pl.named, pl.labels, pl.attributes)
    return ProcessedLayer(; merge(nt, values(kwargs))...)
end

function unnest(v::AbstractArray)
    return map_pairs(first(v)) do (k, _)
        return [el[k] for el in v]
    end
end

function Base.map(f, pl::ProcessedLayer)
    axs = shape(pl)
    outputs = map(CartesianIndices(axs)) do c
        p = map(v -> getnewindex(v, c), pl.positional)
        n = map(v -> getnewindex(v, c), pl.named)
        return f(p, n)
    end
    positional = unnest(map(first, outputs))
    named = unnest(map(last, outputs))
    return ProcessedLayer(pl; positional, named)
end

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

function group(pl::ProcessedLayer)
    grouping = Tuple(only(v) for v in values(pl.primary) if haszerodims(v))
    perm, rgs = permutation_ranges(grouping)
    axs = shape(pl)
    primary, positional, named = map((pl.primary, pl.positional, pl.named)) do vars
        return map(vs -> subgroups(vs, perm, rgs, axs), vars)
    end
    labels = map(shiftdims, pl.labels)
    return ProcessedLayer(pl; primary, positional, named, labels)
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
    labels = MixedArguments()
    positional, named = map((layer.positional, layer.named)) do tup
        return map_pairs(tup) do (key, value)
            label, arr = getlabeledarray(layer, value)
            insert!(labels, key, label)
            return arr
        end
    end
    primary, named = separate(hascategoricalentry, named)
    return ProcessedLayer(; primary, positional, named, labels)
end

"""
    to_processedlayer(layer::Layer)

Convert `layer` to equivalent pl, excluding transformations.
"""
function to_processedlayer(layer::Layer)
    pl = process_mappings(layer)
    grouped_entry = isnothing(layer.data) ? pl : group(pl)
    primary = map(vs -> map(getuniquevalue, vs), grouped_entry.primary)
    return ProcessedLayer(grouped_entry; primary)
end

process(layer::Layer) = layer.transformation(to_processedlayer(layer))
