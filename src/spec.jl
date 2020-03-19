struct MixedTuple{T<:Tuple, NT<:NamedTuple}
    args::T
    kwargs::NT
end

function mixedtuple(args...; kwargs...)
    nt = values(kwargs)
    MixedTuple(args, nt)
end

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

abstract type AbstractSpec end

struct LazySpec <: AbstractSpec
    primary::MixedTuple
    data::MixedTuple
    metadata::MixedTuple
end
LazySpec(s::LazySpec) = s

function LazySpec(; primary=mixedtuple(), data=mixedtuple(), metadata=mixedtuple())
    return LazySpec(primary, data, metadata)
end

function merge(s1::LazySpec, s2::LazySpec)
    primary = merge(s1.primary, s2.primary)
    data = merge(s1.data, s2.data)
    metadata = merge(s1.metadata, s2.metadata)
    return LazySpec(primary, data, metadata)
end

function Base.show(io::IO, s::LazySpec)
    print(io, "LazySpec with primary")
    show(io, s.primary)
    print(io, ", data")
    show(io, s.data)
    print(io, ", metadata")
    show(io, s.metadata)
end

primary(args...; kwargs...) = LazySpec(primary = mixedtuple(args...; kwargs...))
primary(s::LazySpec) = s.primary
data(args...; kwargs...) = LazySpec(data = mixedtuple(args...; kwargs...))
data(s::LazySpec) = s.data
metadata(args...; kwargs...) = LazySpec(metadata = mixedtuple(args...; kwargs...))
metadata(s::LazySpec) = s.metadata

get_named(t::Tuple, m::MixedTuple) = get_named(tail(t), m(tail(m.args), m.kwargs))
function get_named(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return NamedTuple{names}(t)
end

function to_vectors(vs...)
    i = findfirst(t -> isa(t, AbstractVector), vs)
    i === nothing && return nothing
    map(vs) do v
        v isa AbstractVector ? v : fill(v[], length(vs[i]))
    end
end

function (p::LazySpec)(table=nothing)
    primary = p.primary
    data = p.data
    metadata = p.metadata
    t = columntable(something(table, NamedTuple()))
    primary = extract_column(t, primary)
    data = extract_column(t, data)
    cols = (primary.args..., primary.kwargs...)
    vecs = to_vectors(cols...)
    if vecs === nothing
        primary′ = [get_named(map(getindex, cols), primary)]
        data′ = [data]
    else
        # TODO do not create unnecessary vectors
        sa = StructArray(map(pool, vecs))
        it = finduniquesorted(sa)
        st_data = StructArray(get_named(k, primary) => extract_view(data, idxs) for (k, idxs) in it)
        primary′, data′ = fieldarrays(st_data)
    end
    Spec(primary′, data′, metadata)
end

consistent(a::LazySpec, b::LazySpec) = consistent(a.primary.kwargs, b.primary.kwargs)

struct Spec{P, D} <: AbstractSpec
    primary::P
    data::D
    metadata::MixedTuple
end
Spec(primary, data) = Spec(primary, data, mixedtuple())
Spec(s::Spec) = s

function Base.show(io::IO, s::Spec)
    print(io, "Spec {...}")
end

function merge(s1::Spec, s2::Spec)
    primary = merge(s1.primary, s2.primary)
    data = merge(s1.data, s2.data)
    metadata = merge(s1.metadata, s2.metadata)
    return Spec(primary, data, metadata)
end

(s::Spec)(v) = s
