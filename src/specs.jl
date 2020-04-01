abstract type AbstractGraphical end

const GraphicalOrContextual = Union{AbstractGraphical, AbstractContextual}

struct Spec{T} <: AbstractGraphical
    args::Tuple
    kwargs::NamedTuple
end
Spec() = Spec{Any}((), NamedTuple())

spec(args...; kwargs...) = Spec{Any}(args, values(kwargs))
spec(::Type{T}, args...; kwargs...) where {T} = Spec{T}(args, values(kwargs))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge_rec(t1.kwargs, t2.kwargs)
    return Spec{T}(args, kwargs)
end

function Base.:(==)(s1::Spec, s2::Spec)
    return plottype(s1) === plottype(s2) && s1.args == s2.args && s1.kwargs == s2.kwargs
end

struct Layers <: AbstractGraphical
    layers::Vector{Pair{Spec, ContextualMap}}
end
Layers(s::GraphicalOrContextual) = Layers(layers(s))

layers(s::Layers)             = s.layers
layers(s::Spec)               = Pair{Spec, ContextualMap}[s => ContextualMap()]
layers(s::AbstractContextual) = Pair{Spec, ContextualMap}[Spec() => ContextualMap(s)]

Base.:(==)(s1::Layers, s2::Layers) = layers(s1) == layers(s2)

function Base.:*(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    v = Pair{Spec, ContextualMap}[]
    for el1 in l1
        for el2 in l2
            push!(v, merge(first(el1), first(el2)) => last(el1) * last(el2))
        end
    end
    return Layers(v)
end

function Base.:+(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    return Layers(vcat(l1, l2))
end

# plotting tools

function extract_names(d::NamedTuple)
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

"""
    specs(ts::GraphicalOrContextual, palette)

Compute a vector of `OrderedDict{NamedTuple, Spec}` to be passed to the
plotting package. `palette[key]` must return a finite list of options, for
each `key` used as primary (e.g., `color`, `marker`, `linestyle`).
"""
function specs(ts::GraphicalOrContextual, palette, rks = rankdicts(ts))
    serieslist = OrderedDict{NamedTuple, Spec}[]
    for (m, ctxmap) in layers(ts)
        d = OrderedDict{NamedTuple, Spec}()
        scales = Dict{Symbol, Any}()
        for (key, val) in palette
            scales[key] = get(m.kwargs, key, val)
        end
        for (primary, data) in pairs(ctxmap)
            theme = applytheme(scales, primary, rks)
            names, data = extract_names(data)
            sp = merge(m, Spec{Any}(Tuple(positional(data)), (; keyword(data)..., theme...)))
            d[primary] = merge(sp, Spec{Any}((), (; names=names)))
        end
        push!(serieslist, d)
    end
    return serieslist
end

function applytheme(scales, grp::NamedTuple{names}, rks) where names
    res = map(names) do key
        val = grp[key]
        if val isa NamedTuple
            applytheme(to_value(get(scales, key, NamedTuple())), val, rks[key])
        else
            # let's worry about interactivity later
            scale = to_value(get(scales, key, nothing))
            idx = rks[key][val]
            scale === nothing ? idx : scale[mod1(idx, length(scale))]
        end
    end
    return NamedTuple{names}(res)
end

rankdicts(ts::GraphicalOrContextual) = rankdicts(map(last, layers(ts)))
