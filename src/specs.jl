abstract type AbstractGraphical end

const Algebraic = Union{AbstractGraphical, AbstractContextual, AlgebraicDict}

struct Spec{T} <: AbstractGraphical
    args::Tuple
    kwargs::NamedTuple
end
Spec(t::Tuple=(), nt::NamedTuple=NamedTuple()) = Spec{Any}(t, nt)
Spec(nt::NamedTuple) = Spec((), nt)

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
    # TODO: analysis go here
    # ls = computelayout(s)
    return computescales(d)
end

# function computeanalysis(s::GraphicalOrContextual)
#     s′ = Spec{plottype(s)}(Base.tail(s.args), s.kwargs)
#     compute(first(s.args), v) * compute(s′, v)
# end

function computescales(s::AlgebraicDict)
    AlgebraicDict(key => computescales(key, val) for (key, val) in pairs(s))
end
function computescales(s::Spec, dict::AbstractDict)
    scales[] = (; AbstractPlotting.current_default_theme()[:palette]...)
    l = (layout_x = nothing, layout_y = nothing)
    discrete_scales = map(DiscreteScale, merge(scales[], s.kwargs, l))
    continuous_scales = map(ContinuousScale, s.kwargs)
    ks = [applytheme(discrete_scales, ds) for ds in keys(dict)]
    vs = [applytheme(continuous_scales, cs) for cs in values(dict)]
    return LittleDict(ks, vs)
end

function applytheme(scales, grp::NamedTuple{names}) where names
    res = map(names) do key
        haskey(scales, key) ? attr!(scales[key], grp[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
