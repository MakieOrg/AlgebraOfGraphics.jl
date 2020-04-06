abstract type AbstractGraphical end

const GraphicalOrContextual = Union{AbstractGraphical, AbstractContextual}

struct Spec{T} <: AbstractGraphical
    args::Tuple
    kwargs::NamedTuple
end
Spec() = Spec{Any}((), NamedTuple())

Spec(s::Style) = Spec{Any}(split(s.value)...)

spec(args...; kwargs...) = Spec{Any}(args, values(kwargs))
spec(T::Union{Type, Symbol}, args...; kwargs...) = Spec{T}(args, values(kwargs))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge(t1.kwargs, t2.kwargs)
    return Spec{T}(args, kwargs)
end

function Base.:(==)(s1::Spec, s2::Spec)
    return plottype(s1) === plottype(s2) && s1.args == s2.args && s1.kwargs == s2.kwargs
end

Base.hash(a::Spec, h::UInt64) = hash((a.args, a.kwargs), hash(typeof(a), h))

struct Analysis{F} <: AbstractGraphical
    f::F
    kwargs::NamedTuple
end

Analysis(f; kwargs...) = Analysis(f, values(kwargs))

(a::Analysis)(; kwargs...) = Analysis(a.f, merge(a.kwargs, values(kwargs)))

(a::Analysis)(args...; kwargs...) = a.f(args...; merge(a.kwargs, values(kwargs))...)

const LayerDict = OrderedDict{Spec, Vector{Style}}

struct Layers <: AbstractGraphical
    layers::LayerDict
end
Layers(s::GraphicalOrContextual) = Layers(layers(s))
Layers() = Layers(LayerDict())

layers(s::Layers)             = s.layers
layers(s::Analysis)           = layers(Spec{Any}((s,), NamedTuple()))
layers(s::Spec)               = LayerDict(s => [Style()])
layers(s::AbstractContextual) = LayerDict(Spec() => [Style(s)])

Base.:(==)(s1::Layers, s2::Layers) = layers(s1) == layers(s2)

function Base.:*(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    d = LayerDict()
    for (k1, v1) in pairs(l1)
        for (k2, v2) in pairs(l2)
            k = merge(k1, k2)
            v = Style[merge(a, b) for a in v1 for b in v2]
            d[k] = append!(get(d, k, Style[]), v)
        end
    end
    return Layers(d)
end

function Base.:+(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    return Layers(merge(vcat, l1, l2))
end

# pipeline

function compute(s::GraphicalOrContextual)
    acc = LayerDict()
    for (sp, series) in pairs(layers(s))
        acc[sp] = Style[]
        foreach(v -> append!(acc[sp], styles(v)), series)
    end
    # TODO: analysis go here
    # ls = computelayout(s)
    return computescales(Layers(acc))
end

# function computeanalysis(s::GraphicalOrContextual)
#     s′ = Spec{plottype(s)}(Base.tail(s.args), s.kwargs)
#     compute(first(s.args), v) * compute(s′, v)
# end

# computelayout(s::GraphicalOrContextual) = sum(computelayout, layers(s))
# function computelayout((s, v)::Pair{<:Spec, Vector{Style}})
#     list = map(v) do style
#         layout_x = to_value(get(style.value, :layout_x, 1))
#         layout_y = to_value(get(style.value, :layout_y, 1))
#         layout = tuple.(layout_x, layout_y)
#         if layout isa AbstractArray
#             sa = StructArray(vec(layout))
#             return finduniquesorted(sa) do (k, idxs)
#                 map(st.value)
#         end
#     end
#     Layers(LayerDict(s => v))
# end

computescales(s::GraphicalOrContextual) = sum(computescales, layers(s))
function computescales((s, v)::Pair{<:Spec, Vector{Style}})
    scales[] = (; AbstractPlotting.current_default_theme()[:palette]...)
    discrete_scales = map(DiscreteScale, merge(scales[], s.kwargs))
    v′ = [applytheme(discrete_scales, style) for style in v]
    Layers(LayerDict(s => v′))
end

applytheme(scales, style::Style) = Style(applytheme(scales, style.value))

function applytheme(scales, grp::NamedTuple{names}) where names
    res = map(names) do key
        haskey(scales, key) ? attr!(scales[key], grp[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
