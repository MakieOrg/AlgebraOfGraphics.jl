struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

to_mixedtuple(t::Tuple) = MixedTuple(t, NamedTuple())
to_mixedtuple(nt::NamedTuple) = MixedTuple((), t)
to_mixedtuple(m::MixedTuple) = m
to_mixedtuple(t) = to_mixedtuple(tuple(t))

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

struct Analysis{T, N<:NamedTuple}
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end
Analysis() = Analysis(mixedtuple)

function Base.show(io::IO, an::Analysis)
    print(io, "Analysis(")
    show(io, an.f)
    print(io, ")")
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
function (an::Analysis)(args...; kwargs...)
    return an.f(args...; kwargs..., an.kwargs...)
end
function (an::Analysis)(m::MixedTuple)
    to_mixedtuple(an(m.args...; m.kwargs...))
end
function (an::Analysis)(d::OrderedDict{<:NamedTuple, <:MixedTuple})
    OrderedDict(k => an(v) for (k, v) in d)
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

# function Traces(g::Group, t::Traces)
#     isempty(g.columns) && return t
#     sa = StructArray(map(pool, g.columns))
#     itr = finduniquesorted(sa)
#     list = [merge(k, a) => extract_view(s, idxs) for (k, idxs) in itr for (a, s) in t.list]
#     return Traces(list)
# end

get_named(t::Tuple, m::MixedTuple) = get_named(tail(t), m(tail(m.args), m.kwargs))
function get_named(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return NamedTuple{names}(t)
end

function Base.collect(p::Spec)
    table = p.table
    analysis = p.analysis
    primary = p.primary
    data = p.data
    if table !== nothing
        t = columntable(table)
        primary = extract_column(t, primary)
        data = extract_column(t, data)
    end
    cols = (primary.args..., primary.kwargs...)
    dict = if isempty(cols)
        OrderedDict(mixedtuple() => data)
    else
        sa = StructArray(map(pool, cols))
        it = finduniquesorted(sa)
        OrderedDict(get_named(k, primary) => extract_view(data, idxs) for (k, idxs) in it)
    end
    return analysis(dict)
end

