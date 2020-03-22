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

struct Trace{C, P<:MixedTuple, D<:MixedTuple, M<:MixedTuple}
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

Broadcast.broadcastable(t::Trace) = Ref(t)

function merge(s1::Trace, s2::Trace)
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

struct TraceArray{T, N} <: AbstractArray{T, N}
    parent::Array{T, N}
end
TraceArray(t::TraceArray) = copy(t)

Base.parent(t::TraceArray) = t.parent
Base.size(s::TraceArray) = size(parent(s))
Base.getindex(s::TraceArray, i::Integer) = getindex(parent(s), i)
Base.setindex!(s::TraceArray, v, i::Integer) = setindex!(parent(s), v, i)
Base.IndexStyle(::Type{<:TraceArray}) = IndexLinear()

Broadcast.BroadcastStyle(::Type{<:TraceArray}) = ArrayStyle{TraceArray}()
function Base.similar(bc::Broadcasted{ArrayStyle{TraceArray}}, ::Type{ElType}) where {ElType<:Trace}
    return TraceArray(similar(Array{ElType}, axes(bc)))
end

function Base.similar(::Type{T}, sz::Dims) where {T<:TraceArray}
    return TraceArray(similar(Array{T}, sz))
end
Base.similar(s::TraceArray, ::Type{T}, sz::Dims) where {T} = TraceArray(similar(parent(s), T, sz))
 
Base.reshape(s::TraceArray, d::Dims) = TraceArray(reshape(parent(s), d))
Base.copy(s::TraceArray) = TraceArray(copy(parent(s)))

# should we use a private function instead?
merge(s::Trace, t::TraceArray) = merge.(s, t)
merge(s::TraceArray, t::Trace) = merge.(s, t)
function merge(s::TraceArray{<:Any, N}, t::TraceArray) where N
    sz = (ntuple(_ -> 1, N)..., size(t)...)
    t′ = reshape(t, sz...)
    return TraceArray(merge.(s, t′))
end

_to_trace(s::Union{Trace, TraceArray}) = s
_to_trace(s) = data(s)

(t::Trace)(s) = merge(_to_trace(s), t)
(t::TraceArray)(s) = merge(_to_trace(s), t)

Base.:+(a::Union{Trace, TraceArray}, b::Union{Trace, TraceArray}) = TraceArray(vcat(a, b))
