struct Spec{T} <: AbstractElement
    analysis::Tuple
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
    analysis = (t1.analysis..., t2.analysis...)
    style = merge(t1.style, t2.style)
    options = merge(t1.options, t2.options)
    return Spec{T}(analysis, style, options)
end

Base.:*(a1::AbstractElement, a2::AbstractElement) = merge(Spec(a1), Spec(a2))

layers(g::AbstractElement) = AlgebraicList([Spec(g)])
layers(g::AlgebraicList) = g

Base.:*(s1::AbstractElement, s2::AlgebraicList) = layers(s1) * s2
Base.:*(s1::AlgebraicList, s2::AbstractElement) = s1 * layers(s2)

const ElementOrList = Union{AbstractElement, AlgebraicList}

Base.:+(s1::ElementOrList, s2::ElementOrList) = layers(s1) + layers(s2)

# pipeline

function expand(a)
    d = contexts(a)
    AlgebraicDict(merge(k, f) => l for (k, v) in d for (f, l) in pairs(v))
end
function compute(s::ElementOrList)
    l = layers(s)
    d = AlgebraicDict(k => expand(v) for (k, v) in pairs(l))
    e = computeanalysis(d)
    computescales(e)
end
