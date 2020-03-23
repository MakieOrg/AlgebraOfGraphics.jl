struct Trace{C, P<:NamedTuple, D<:MixedTuple, M<:MixedTuple}
    context::C
    primary::P
    data::D
    metadata::M
end

function Trace(;
               context=nothing,
               primary=NamedTuple(),
               data=mixedtuple(),
               metadata=mixedtuple()
              )
    return Trace(context, primary, data, metadata)
end

Broadcast.broadcastable(t::Trace) = Ref(t)

function combine(s1::Trace, s2::Trace)
    c1, c2 = context(s1), context(s2)
    c = c2 === nothing ? c1 : c2
    return combine(c, s1, s2)
end

context(s::Trace)  = s.context
primary(s::Trace)  = s.primary
data(s::Trace)     = s.data
metadata(s::Trace) = s.metadata

function Base.show(io::IO, s::Trace)
    print(io, "Trace {...}")
end

keyvalue(t::Trace) = keyvalue(context(t), t)

struct Traces{T<:Trace}
    list::Vector{T}
end
Traces(t) = Traces(vec(collect(t))::Vector)
Traces(t::Vector) = error("Eltype of Traces must be Trace")
Traces(t::Traces) = copy(t)
list(t::Traces) = t.list

function Base.show(io::IO, s::Traces)
    print(io, "Trace list of length $(length(s))")
end

Broadcast.broadcastable(t::Traces) = Ref(t)

Base.copy(t::Traces) = Traces(copy(t.list))

Base.length(l::Traces) = length(l.list)
Base.getindex(t::Traces, i) = t.list[i]
Base.iterate(t::Traces) = iterate(t.list)
Base.iterate(t::Traces, st) = iterate(t.list, st)
Base.eltype(::Type{Traces{T}}) where {T} = T

(t::Traces)(s) = t(data(s)::Traces)
function (t::Traces)(s::Traces)
    l1, l2 = s.list, permutedims(t.list)
    arr = @. list(combine(l1, l2))
    return Traces(reduce(vcat, arr))
end
Base.:+(s::Traces, t::Traces) = Traces(vcat(s.list, t.list))

context(x)                   = Traces([Trace(context=x)])
primary(; kwargs...)         = Traces([Trace(primary=values(kwargs))])
data(args...; kwargs...)     = Traces([Trace(data=mixedtuple(args...; kwargs...))])
metadata(args...; kwargs...) = Traces([Trace(metadata=mixedtuple(args...; kwargs...))])

