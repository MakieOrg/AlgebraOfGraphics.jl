# Interface for a context:
#
# `Base.pairs(c::MyContext)` iterates pairs of named tuples
# `(s2::DefaultContext)(s1::MyContext)` returns a `MyContext`

# default context: use broadcast semantics on a set of arrays

struct DefaultContext{P<:NamedTuple, D<:NamedTuple} <: AbstractEdge
    primary::P
    data::D
end

primary(; kwargs...)     = DefaultContext(primary=values(kwargs))
data(args...; kwargs...) = DefaultContext(data=namedtuple(args...; kwargs...))

function DefaultContext(; primary=NamedTuple(), data=NamedTuple())
    return DefaultContext(primary, data)
end

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

_adjust(x::NamedTuple, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

function Base.pairs(s::DefaultContext)
    d = aos(s.data)
    p = aos(_adjust(s.primary, axes(d)))
    return wrapif(p .=> d, Pair)
end

function (s2::DefaultContext)(s1::DefaultContext)
    return DefaultContext(merge(s1.primary, s2.primary), merge(s1.data, s2.data))
end

function Base.show(io::IO, s::DefaultContext)
    print(io, "DefaultContext {...}")
end

# data context: integers and symbols are columns
struct DataContext{L<:AbstractArray} <: AbstractEdge
    list::L
end

function Base.pairs(t::DataContext)
    itr = (pairs(DefaultContext(p, d)) for (_, (p, d)) in t.list)
    return collect(Iterators.flatten(itr))
end

function Base.show(io::IO, s::DataContext)
    print(io, "DataContext of length $(length(pairs(s)))")
end

function extract_column(t, col::Union{Symbol, Int}, wrap=false)
    v = getcolumn(t, col)
    return wrap ? fill(v) : v
end
extract_column(t, c::NamedTuple, wrap=false) = map(x -> extract_column(t, x, wrap), c)
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

function (s2::DefaultContext)(s1::DataContext)
    itr = Base.Generator(s1.list) do (cols, (p, d))
        p2 = extract_column(cols, s2.primary)
        d2 = extract_column(cols, s2.data, true)
        return group(cols, merge(p, p2), merge(d, d2))
    end
    return DataContext(collect(Iterators.flatten(itr)))
end

table(x) = DataContext([(coldict(x), NamedTuple() => NamedTuple())])

# slice context: slice across dims
struct SliceContext{P<:NamedTuple, D<:NamedTuple, N} <: AbstractEdge
    primary::P
    data::D
    dims::NTuple{N, Int}
end
slice(args::Int...) = SliceContext(NamedTuple(), NamedTuple(), args)

function (s2::DefaultContext)(s1::SliceContext)
    p = merge(s1.primary, s2.primary)
    d = merge(s1.data, s2.data)
    return SliceContext(p, d, s1.dims)
end

function Base.pairs(s::SliceContext)
    d = map(s.data) do col
        dims = filter(t -> t < ndims(col), s.dims)
        mapslices(v -> [v], col; dims=dims)
    end
    return pairs(DefaultContext(s.primary, d))
end
