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

function Trace(;
               context=nothing,
               primary=mixedtuple(),
               data=mixedtuple(),
               metadata=mixedtuple()
              )
    return Trace(context, primary, data, metadata)
end

function merge(s1::AbstractTrace, s2::AbstractTrace)
    c1, c2 = context(s1), context(s2)
    c = c2 === nothing ? c1 : c2
    s2 = apply_context(c, s2)
    p1, p2 = primary(s1), primary(s2)
    d1, d2 = data(s1), data(s2)
    m1, m2 = metadata(s1), metadata(s2)
    p = merge(p1, p2)
    d = merge(d1, d2)
    m = merge(m1, m2)
    return Trace(c, p, d, m)
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

const AbstractTraceOrList = Union{AbstractTrace, AbstractTraceList}

_to_trace(t) = data(t)
_to_trace(t::AbstractTraceOrList) = t

@static if VERSION < v"1.3.0"
    (t::Trace)(s) = merge(_to_trace(s), t)
    (l::TraceList)(v) = merge(_to_trace(v), l)
else
    (t::AbstractTraceOrList)(l) = merge(_to_trace(l), t)
end
