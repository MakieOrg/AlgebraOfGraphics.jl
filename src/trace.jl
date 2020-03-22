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

# Allow customization of merge by context?
function merge(s1::Trace, s2::Trace)
    c1, c2 = context(s1), context(s2)
    c = c2 === nothing ? c1 : c2
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

# To support piping interface
(t::Trace)(s) = merge(data(s)::Trace, t)
(t::Trace)(s::Trace) = merge(s, t)
