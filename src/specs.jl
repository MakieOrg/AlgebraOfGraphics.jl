struct Spec{T} <: AbstractElement
    analyses::Tuple
    style::Style
    options::NamedTuple
end
Spec(t::Tuple, style::Style, nt::NamedTuple) = Spec{Any}(t, style, nt)

Spec{T}(t::Tuple=(), nt::NamedTuple=NamedTuple()) where {T} = Spec{T}(t, Style(), nt)
Spec(t::Tuple=(), nt::NamedTuple=NamedTuple()) = Spec{Any}(t, Style(), nt)

Spec(t::AbstractContext) = Spec{Any}((), Style(t), NamedTuple())
Spec(t::Style) = Spec{Any}((), t, NamedTuple())
Spec(s::Spec) = s

spec(args...; kwargs...) = Spec{Any}((), namedtuple(args...; kwargs...))
spec(T::Union{Type, Symbol}, args...; kwargs...) = Spec{T}((), namedtuple(args...; kwargs...))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    analyses = (t1.analyses..., t2.analyses...)
    style = merge(t1.style, t2.style)
    options = merge(t1.options, t2.options)
    return Spec{T}(analyses, style, options)
end

Base.:*(a1::AbstractElement, a2::AbstractElement) = merge(Spec(a1), Spec(a2))

layers(g::AbstractElement) = AlgebraicList([Spec(g)])
layers(g::AlgebraicList) = g

Base.:*(s1::AbstractElement, s2::AlgebraicList) = layers(s1) * s2
Base.:*(s1::AlgebraicList, s2::AbstractElement) = s1 * layers(s2)

const ElementOrList = Union{AbstractElement, AlgebraicList}

Base.:+(s1::ElementOrList, s2::ElementOrList) = layers(s1) + layers(s2)

# pipeline

# Expand pairs and run the analyses
function expand(sp::Spec{T}) where {T}
    analyses, style, options = sp.analyses, sp.style, sp.options
    v = [Spec{T}((), val, merge(options, key)) for (key, val) in pairs(style)]
    list = AlgebraicList(v)
    return foldl(apply, analyses, init=list)
end

# default fallback to apply a callable to a AlgebraicList
# if customized, it must return an AlgebraicList
function apply(f, d::AlgebraicList)::AlgebraicList
    v = map(parent(d)) do layer
        analyses, style, options = layer.analyses, layer.style, layer.options
        T = plottype(layer)
        args, kwargs = split(style.value)
        res = f(args...; kwargs...)
        return layers(Spec{T}(analyses, Style(), options) * res)
    end
    return AlgebraicList(reduce(vcat, v))
end

function run_pipeline(s::ElementOrList)
    nested = [parent(expand(layer)) for layer in layers(s)]
    computescales(reduce(vcat, nested))
end
