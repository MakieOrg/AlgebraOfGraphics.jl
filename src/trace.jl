abstract type AbstractTraceOrList end

abstract type AbstractTrace <: AbstractTraceOrList end
abstract type AbstractList <: AbstractTraceOrList end

Broadcast.broadcastable(t::AbstractTrace) = Ref(t)

# key-value iterator (pairs)
# metadata

struct Trace{P<:NamedTuple, D<:MixedTuple, M<:MixedTuple} <: AbstractTrace
    primary::P
    data::D
    metadata::M
end

function Trace(;
               primary=NamedTuple(),
               data=mixedtuple(),
               metadata=mixedtuple()
              )
    return Trace(primary, data, metadata)
end

primary(s::Trace)  = s.primary
data(s::Trace)     = s.data
metadata(s::Trace) = s.metadata

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

_adjust(x::Tup, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

function Base.pairs(s::Trace)
    d = aos(data(s))
    p = aos(_adjust(primary(s), axes(d)))
    return wrapif(p .=> d, Pair)
end

primary(; kwargs...)         = Trace(primary=values(kwargs))
data(args...; kwargs...)     = Trace(data=mixedtuple(args...; kwargs...))
metadata(args...; kwargs...) = Trace(metadata=mixedtuple(args...; kwargs...))

(t::Trace)(s) = t(data(s)::Trace)
function (s2::Trace)(s1::Trace) 
    p1, p2 = primary(s1), primary(s2)
    if !isempty(keys(p1) ∩ keys(p2))
        error("Cannot combine with overlapping primary keys")
    end
    d1, d2 = data(s1), data(s2)
    m1, m2 = metadata(s1), metadata(s2)
    p = merge(p1, p2)
    d = merge(d1, d2)
    m = merge(m1, m2)
    return Trace(p, d, m)
end

function Base.show(io::IO, s::Trace)
    print(io, "Trace {...}")
end

struct DataTrace{T<:AbstractArray, M<:MixedTuple} <: AbstractTrace
    list::T
    metadata::M
end
metadata(t::DataTrace) = t.metadata
function Base.pairs(t::DataTrace)
    itr = (pairs(Trace(primary=p, data=d)) for (_, (p, d)) in t.list)
    return collect(Iterators.flatten(itr))
end

function Base.show(io::IO, s::DataTrace)
    print(io, "DataTrace of length $(length(pairs(s)))")
end

function extract_column(t, col::Union{Symbol, Int}, wrap=false)
    v = getcolumn(t, col)
    return wrap ? fill(v) : v
end
extract_column(t, c::Tup, wrap=false) = map(x -> extract_column(t, x, wrap), c)
extract_column(t, c::AbstractArray, wrap=false) = map(x -> extract_column(t, x, false), c)
extract_column(t, c::DimsSelector, wrap=false) = c

function group(cols, p, d)
    pv = keepvectors(p)
    list = if isempty(pv)
        [(cols, p => d)]
    else
        sa = StructArray(map(pool, pv))
        map(finduniquesorted(sa)) do (k, idxs)
            v = map(t -> map(x -> view(x, idxs), t), d)
            subtable = coldict(cols, idxs)
            (subtable, merge(p, map(fill, k)) => v)
        end
    end
end

function (s2::Trace)(s1::DataTrace)
    # TODO: add labels to metadata
    itr = Base.Generator(s1.list) do (cols, (p, d))
        p2 = extract_column(cols, primary(s2))
        d2 = extract_column(cols, data(s2), true)
        return group(cols, merge(p, p2), merge(d, d2))
    end
    return DataTrace(collect(Iterators.flatten(itr)), merge(metadata(s1), metadata(s2)))
end

table(x) = DataTrace([(coldict(x), NamedTuple() => mixedtuple())], mixedtuple())

# Trick to be able to define `+`

struct ScalarList <: AbstractList
    list::Vector{AbstractTrace}
end
ScalarList(v::Vector) = ScalarList(convert(Vector{AbstractTrace}, v))
ScalarList(s::ScalarList) = s
ScalarList(t::AbstractTrace) = ScalarList([t])

function Base.show(io::IO, s::ScalarList)
    print(io, "Scalar list of length $(length(s.list))")
end

Broadcast.broadcastable(t::ScalarList) = Ref(t)

(t::Trace)(s::ScalarList) = ScalarList(map(t, s.list))
(s::ScalarList)(t::AbstractTrace) = ScalarList(map(f -> f(t), s.list))
(s::ScalarList)(t::ScalarList) = ScalarList([ss(tt) for ss in s.list for tt in t.list])

function Base.:+(a::Union{AbstractTrace, ScalarList}, b::Union{AbstractTrace, ScalarList})
    a = ScalarList(a)
    b = ScalarList(b)
    return ScalarList(vcat(a.list, b.list))
end

list(s::AbstractTrace) = [s]
list(s::ScalarList) = s.list

function flatten(t::AbstractArray{<:AbstractTraceOrList})
    return collect(Iterators.flatten(Base.Generator(list, t)))
end
