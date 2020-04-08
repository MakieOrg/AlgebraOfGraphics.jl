abstract type AbstractGraphical end

const Algebraic = Union{AbstractGraphical, AbstractContextual, AlgebraicDict}

struct Spec{T} <: AbstractGraphical
    analysis::Tuple
    value::NamedTuple
end
Spec(t::Tuple=(), nt::NamedTuple=NamedTuple()) = Spec{Any}(t, nt)
Spec(nt::NamedTuple) = Spec((), nt)
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

struct Analysis{F} <: AbstractGraphical
    f::F
    kwargs::NamedTuple
end

Analysis(f; kwargs...) = Analysis(f, values(kwargs))

(a::Analysis)(; kwargs...) = Analysis(a.f, merge(a.kwargs, values(kwargs)))

(a::Analysis)(args...; kwargs...) = a.f(args...; merge(a.kwargs, values(kwargs))...)

layers(s::Analysis)           = layers(Spec{Any}((s,), NamedTuple()))
layers(s::Spec)               = AlgebraicDict(s => Style())
layers(s::AbstractContextual) = AlgebraicDict(Spec() => Style(s))

AlgebraicDict(s::Union{AbstractGraphical, AbstractContextual}) = AlgebraicDict(layers(s))

Base.:*(s1::Algebraic, s2::Algebraic) = AlgebraicDict(s1) * AlgebraicDict(s2)
Base.:+(s1::Algebraic, s2::Algebraic) = AlgebraicDict(s1) + AlgebraicDict(s2)

# pipeline

function compute(s::Algebraic)
    l = AlgebraicDict(s)
    d = AlgebraicDict(k => LittleDict(pairs(v)) for (k, v) in pairs(l))
    e = computeanalysis(d)
    computescales(e)
end

function computeanalysis(ad::AlgebraicDict, i=1)
    acc = AlgebraicDict()
    for (key, val) in ad
        p = AlgebraicDict(key => val)
        if length(key.analysis) < i
            acc += p
        else
            acc += computeanalysis(key.analysis[i](p), i + 1)
        end
    end
    return acc
end

function computescales(s::AlgebraicDict)
    AlgebraicDict(key => computescales(key, val) for (key, val) in pairs(s))
end
function computescales(s::Spec, dict::AbstractDict)
    scales[] = (; AbstractPlotting.current_default_theme()[:palette]...)
    l = (layout_x = nothing, layout_y = nothing)
    discrete_scales = map(DiscreteScale, merge(scales[], s.value, l))
    continuous_scales = map(ContinuousScale, s.value)
    ks = [applytheme(discrete_scales, ds) for ds in keys(dict)]
    vs = [Style(applytheme(continuous_scales, cs.value)) for cs in values(dict)]
    return LittleDict(ks, vs)
end

function applytheme(scales, grp::NamedTuple{names}) where names
    res = map(names) do key
        haskey(scales, key) ? attr!(scales[key], grp[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
