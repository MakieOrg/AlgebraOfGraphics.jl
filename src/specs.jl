abstract type AbstractGraphical end

const Algebraic = Union{AbstractGraphical, AbstractContextual, AlgebraicDict}

struct Spec{T} <: AbstractGraphical
    analysis::Tuple
    value::NamedTuple
end
Spec(t::Tuple=(), nt::NamedTuple=NamedTuple()) = Spec{Any}(t, nt)
Spec(nt::NamedTuple) = Spec((), nt)
Spec(s::Spec) = s
Spec(t::Style) = Spec(t.value)

spec(args...; kwargs...) = Spec{Any}((), namedtuple(args...; kwargs...))
spec(T::Union{Type, Symbol}, args...; kwargs...) = Spec{T}((), namedtuple(args...; kwargs...))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    analysis = (t1.analysis..., t2.analysis...)
    value = merge(t1.value, t2.value)
    return Spec{T}(analysis, value)
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
