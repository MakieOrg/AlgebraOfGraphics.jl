struct Analysis{T, N<:NamedTuple}
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end

function Base.show(io::IO, an::Analysis)
    print(io, "Analysis(")
    show(io, an.f)
    print(io, ")")
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
function (an::Analysis)(args...; kwargs...)
    return an.f(args...; kwargs..., an.kwargs...)
end

struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

Base.map(f, m::MixedTuple) = MixedTuple(map(f, m.args), map(f, m.kwargs))

function Base.show(io::IO, m::MixedTuple)
    print(io, "MixedTuple")
    _show(io, m.args...; m.kwargs...)
end

function merge(a::MixedTuple, b::MixedTuple)
    tup = (a.args..., b.args...)
    nt = merge(a.kwargs, b.kwargs)
    return MixedTuple(tup, nt)
end

_merge(::Nothing, ::Nothing) = nothing
_merge(a, ::Nothing) = a
_merge(::Nothing, b) = b
_merge(a, b) = merge(a, b)

abstract type AbstractSpec end

Base.@kwdef struct Spec{A, D} <: AbstractSpec
    analysis::A=identity
    table::D=Nothing()
    primary::MixedTuple=mixedtuple()
    data::MixedTuple=mixedtuple()
    metadata::MixedTuple=mixedtuple()
end
Spec(s::Spec) = s

function merge(s1::Spec, s2::Spec)
    analysis = s2.analysis ∘ s1.analysis
    table = s2.table === nothing ? s1.table : s2.table
    primary = merge(s1.primary, s2.primary)
    data = merge(s1.data, s2.data)
    metadata = merge(s1.metadata, s2.metadata)
    return Spec(analysis, table, primary, data, metadata)
end

function Base.show(io::IO, s::Spec)
    print(io, "Spec{ }")
end

primary(args...; kwargs...) = Spec(primary = mixedtuple(args...; kwargs...))
data(args...; kwargs...) = Spec(data = mixedtuple(args...; kwargs...))
metadata(args...; kwargs...) = Spec(metadata = mixedtuple(args...; kwargs...))
analysis(f; kwargs...) = Spec(analysis = Analysis(f; kwargs...))
table(t) = Spec(table = t)
