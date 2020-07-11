abstract type AbstractGraphical end

const Algebraic = Union{AbstractGraphical, AbstractContextual, AlgebraicList}

struct Spec{T} <: AbstractGraphical
    analysis::Tuple
    style::Style
    options::NamedTuple
end

Spec{T}(t::Tuple=(), nt::NamedTuple=NamedTuple()) where {T} = Spec{T}(t, Style(), nt)
Spec(t::AbstractContextual) = Spec{Any}((), Style(t), NamedTuple())
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

function Base.:(==)(s1::Spec, s2::Spec)
    return plottype(s1) === plottype(s2) && s1.analysis == s2.analysis && s1.value == s2.value
end

Base.hash(a::Spec, h::UInt64) = hash((a.analysis, a.value), hash(typeof(a), h))

Base.:*(a1::AbstractGraphical, a2::AbstractGraphical) = merge(Spec(a1), Spec(a2))

key(; kwargs...) = AlgebraicDict(Spec() => AlgebraicDict(values(kwargs) => Style()))

layers(g::AbstractGraphical) = AlgebraicDict(Spec(g) => Style())
layers(c::AbstractContextual) = AlgebraicDict(Spec() => Style(c))
layers(c::AlgebraicDict) = isgraphical(c) ? c : AlgebraicDict(Spec() => c)

contexts(s::AbstractContextual) = AlgebraicDict(NamedTuple() => s)
contexts(s::AlgebraicDict) = s

isgraphical(_) = false
isgraphical(::AbstractGraphical) = true
isgraphical(::AbstractContextual) = false
isgraphical(t::AlgebraicDict) = any(isgraphical, keys(t))

function Base.:*(s1::Algebraic, s2::Algebraic)
    any(isgraphical, (s1, s2)) ? layers(s1) * layers(s2) : contexts(s1) * contexts(s2)
end

function Base.:+(s1::Algebraic, s2::Algebraic)
    any(isgraphical, (s1, s2)) ? layers(s1) + layers(s2) : contexts(s1) + contexts(s2)
end

# pipeline

function expand(a)
    d = contexts(a)
    AlgebraicDict(merge(k, f) => l for (k, v) in d for (f, l) in pairs(v))
end
function compute(s::Algebraic)
    l = layers(s)
    d = AlgebraicDict(k => expand(v) for (k, v) in pairs(l))
    e = computeanalysis(d)
    computescales(e)
end
