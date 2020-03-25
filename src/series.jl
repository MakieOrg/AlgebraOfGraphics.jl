# Series

abstract type AbstractSeries end

primarytable(t::AbstractSeries) = fieldarrays(StructArray(p for (p, _) in pairs(t)))

# Interface: 
# key-value iterator (pairs)
# trace
# support (t2::Series)(t1::MySeries) (returns a `MySeries`)

struct Series{P<:NamedTuple, D<:MixedTuple, T} <: AbstractSeries
    primary::P
    data::D
    spec::Trace{T}
end

function Series(;
               primary=NamedTuple(),
               data=mixedtuple(),
               spec=trace()
              )
    return Series(primary, data, spec)
end

primary(s::Series) = s.primary
data(s::Series)    = s.data
spec(s::Series)    = s.spec

primary(; kwargs...)     = tree(Series(primary=values(kwargs)))
data(args...; kwargs...) = tree(Series(data=mixedtuple(args...; kwargs...)))
spec(args...; kwargs...) = tree(Series(spec=trace(args...; kwargs...)))

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

_adjust(x::Tup, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

function Base.pairs(s::Series)
    d = aos(data(s))
    p = aos(_adjust(primary(s), axes(d)))
    return wrapif(p .=> d, Pair)
end

function (t::Series)(s::T) where {T<:AbstractSeries}
    error("No method implemented to call a `Series` on $T")
end
function (s2::Series)(s1::Series) 
    p1, p2 = primary(s1), primary(s2)
    if !isempty(keys(p1) ∩ keys(p2))
        error("Cannot combine with overlapping primary keys")
    end
    d1, d2 = data(s1), data(s2)
    m1, m2 = spec(s1), spec(s2)
    p = merge(p1, p2)
    d = merge(d1, d2)
    m = merge(m1, m2)
    return Series(p, d, m)
end

function Base.show(io::IO, s::Series)
    print(io, "Series {...}")
end

struct DataSeries{L<:AbstractArray, T} <: AbstractSeries
    list::L
    spec::Trace{T}
end
spec(t::DataSeries) = t.spec
function Base.pairs(t::DataSeries)
    itr = (pairs(Series(primary=p, data=d)) for (_, (p, d)) in t.list)
    return collect(Iterators.flatten(itr))
end

function Base.show(io::IO, s::DataSeries)
    print(io, "DataSeries of length $(length(pairs(s)))")
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

function (s2::Series)(s1::DataSeries)
    # TODO: add labels to spec
    itr = Base.Generator(s1.list) do (cols, (p, d))
        p2 = extract_column(cols, primary(s2))
        d2 = extract_column(cols, data(s2), true)
        return group(cols, merge(p, p2), merge(d, d2))
    end
    return DataSeries(collect(Iterators.flatten(itr)), merge(spec(s1), spec(s2)))
end

function table(x)
    t = coldict(x)
    dt = DataSeries([(t, NamedTuple() => mixedtuple())], trace())
    return tree(dt)
end

