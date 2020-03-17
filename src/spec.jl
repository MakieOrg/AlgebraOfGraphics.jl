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
    analysis::A=nothing
    table::D=nothing
    primary::MixedTuple=mixedtuple()
    data::MixedTuple=mixedtuple()
    metadata::MixedTuple=mixedtuple()
end
Spec(s::Spec) = s

function merge(s1::Spec, s2::Spec)
    analysis = s2.analysis === nothing ? s1.analysis : s2.analysis
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
primary(s::Spec) = s.primary
data(args...; kwargs...) = Spec(data = mixedtuple(args...; kwargs...))
data(s::Spec) = s.data
metadata(args...; kwargs...) = Spec(metadata = mixedtuple(args...; kwargs...))
metadata(s::Spec) = s.metadata
analysis(f; kwargs...) = Spec(analysis = f)
analysis(s::Spec) = s.analysis
table(t) = Spec(table = t)
table(s::Spec) = s.table

get_named(t::Tuple, m::MixedTuple) = get_named(tail(t), m(tail(m.args), m.kwargs))
function get_named(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return NamedTuple{names}(t)
end

function to_vectors(vs...)
    i = findfirst(t -> isa(t, AbstractVector), vs)
    i === nothing && return nothing
    map(vs) do v
        v isa AbstractVector ? v : fill(v, length(vs[i]))
    end
end

function OrderedDict(p::Spec)
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
    vecs = to_vectors(cols...)
    list = if vecs === nothing
        OrderedDict(get_named(cols, primary) => data)
    else
        # TODO do not create unnecessary vectors
        sa = StructArray(map(pool, vecs))
        it = finduniquesorted(sa)
        OrderedDict(get_named(k, primary) => extract_view(data, idxs) for (k, idxs) in it)
    end
    return analyze(analysis, list)
end

to_mixedtuple(t::Tuple) = MixedTuple(t, NamedTuple())
to_mixedtuple(nt::NamedTuple) = MixedTuple((), t)
to_mixedtuple(m::MixedTuple) = m
to_mixedtuple(t) = to_mixedtuple(tuple(t))

analyze(::Nothing, o::OrderedDict) = o
function analyze(f, o::OrderedDict)
    OrderedDict(k => analyze(f, v) for (k, v) in o)
end
analyze(f, m::MixedTuple) = to_mixedtuple(f(m.args...; m.kwargs...))

