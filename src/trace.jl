struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

Base.iterate(m::MixedTuple) = Base.iterate((m.args..., m.kwargs...))
Base.iterate(m::MixedTuple, i) = Base.iterate((m.args..., m.kwargs...), i)

function Base.map(f, m::MixedTuple, ms::MixedTuple...)
    args = map(t -> t.args, (m, ms...))
    kwargs = map(t -> t.kwargs, (m, ms...))
    return MixedTuple(map(f, args...), map(f, kwargs...))
end

function Base.show(io::IO, m::MixedTuple)
    print(io, "MixedTuple")
    _show(io, m.args...; m.kwargs...)
end

function merge(a::MixedTuple, b::MixedTuple)
    tup = (a.args..., b.args...)
    nt = merge(a.kwargs, b.kwargs)
    return MixedTuple(tup, nt)
end

function Base.:(==)(m1::MixedTuple, m2::MixedTuple)
    m1.args == m2.args && m1.kwargs == m2.kwargs
end

abstract type AbstractTrace{C} end

struct Trace{C, P<:MixedTuple, D<:MixedTuple, M<:MixedTuple} <: AbstractTrace{C}
    context::C
    primary::P
    data::D
    metadata::M
end

const empty_trace = Trace(nothing, mixedtuple(), mixedtuple(), mixedtuple())

(t::AbstractTrace)(s::AbstractTrace) = merge(s, t)
(t::AbstractTrace)(s) = merge(data(s), t)

function Trace(;
               context=nothing,
               primary=mixedtuple(),
               data=mixedtuple(),
               metadata=mixedtuple()
              )
    return Trace(context, primary, data, metadata)
end

function merge(s1::AbstractTrace, s2::AbstractTrace)
    @assert context(s2) === nothing || context(s2) === context(s1)
    return merge(context(s1), s1, s2)
end

function Base.show(io::IO, s::Trace)
    print(io, "Trace {...}")
end

context(x) = Trace(context = x)
context(s::Trace) = s.context
primary(args...; kwargs...) = Trace(primary = mixedtuple(args...; kwargs...))
primary(s::Trace) = s.primary
data(args...; kwargs...) = Trace(data = mixedtuple(args...; kwargs...))
data(s::Trace) = s.data
metadata(args...; kwargs...) = Trace(metadata = mixedtuple(args...; kwargs...))
metadata(s::Trace) = s.metadata

abstract type AbstractTraceList{T} end

struct TraceList{T} <: AbstractTraceList{T}
    traces::T
end
const null = TraceList(())
traces(t::TraceList) = t.traces

TraceList(l::TraceList) = l

Base.iterate(p::AbstractTraceList) = iterate(traces(p))
Base.iterate(p::AbstractTraceList, st) = iterate(traces(p), st)
Base.length(p::AbstractTraceList) = length(traces(p))
Base.axes(p::AbstractTraceList) = axes(traces(p))
Base.eltype(::Type{<:AbstractTraceList{T}}) where {T} = eltype(T)

Base.IteratorEltype(::Type{<:AbstractTraceList{T}}) where {T} = Base.IteratorEltype(T)
Base.IteratorSize(::Type{<:AbstractTraceList{T}}) where {T} = Base.IteratorSize(T)

function Base.show(io::IO, l::TraceList)
    print(io, "TraceList with traces ")
    show(io, traces(l))
end

+(a::AbstractTrace, b::AbstractTrace) = TraceList([a]) + TraceList([b])
+(a::AbstractTraceList, b::AbstractTrace) = a + TraceList([b])
+(a::AbstractTrace, b::AbstractTraceList) = TraceList([a]) + b
+(a::AbstractTraceList, b::AbstractTraceList) = TraceList(Iterators.flatten(traces.([a, b])))

function consistent(s::AbstractTrace, t::AbstractTrace)
    return consistent(primary(s).kwargs, primary(t).kwargs)
end

merge(s::AbstractTrace, t::AbstractTraceList) = TraceList([merge(s, el) for el in traces(t)])
merge(s::AbstractTraceList, t::AbstractTrace) = TraceList([merge(el, t) for el in traces(s)])
function merge(s::AbstractTraceList, t::AbstractTraceList)
    prod = Iterators.product(traces(s), traces(t))
    return TraceList(merge(els, elt) for (els, elt) in prod)
end

(l::AbstractTraceList)(v::AbstractTrace) = merge(v, l)
(l::AbstractTraceList)(v::AbstractTraceList) = merge(v, l)
(t::AbstractTrace)(l::AbstractTraceList) = merge(l, t)
