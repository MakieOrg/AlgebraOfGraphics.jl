# contextual pair and map

struct ContextualPair{C, P<:NamedTuple, D<:NamedTuple} <: AbstractEdge
    context::C
    primary::P
    data::D
end
ContextualPair(context) = ContextualPair(context, NamedTuple(), NamedTuple())

function Base.:(==)(s1::ContextualPair, s2::ContextualPair)
    s1.context == s2.context && s1.primary == s2.primary && s1.data == s2.data
end

struct ContextualMap{L<:ContextualPair} <: AbstractEdge
    list::Vector{L}
end
ContextualMap(c::ContextualMap) = c
ContextualMap(c::ContextualPair) = ContextualMap([c])

Base.:(==)(s1::ContextualMap, s2::ContextualMap) = s1.list == s2.list

function merge_primary_data(c::ContextualMap, pd)
    l = [ContextualMap(merge_primary_data(cp, pd)).list for cp in c.list]
    return ContextualMap(reduce(vcat, l))
end

function Base.pairs(c::ContextualMap)
    l = [collect(pairs(cp)) for cp in c.list]
    return reduce(vcat, l)
end

# Default: broadcast context

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

_adjust(x::NamedTuple, shape) = map(t -> _adjust(t, shape), x)
_adjust(x, shape) = x
_adjust(d::DimsSelector, shape) = [_adjust(d, c) for c in CartesianIndices(shape)]
_adjust(d::DimsSelector, c::CartesianIndex) = c[d.x...]

function Base.pairs(s::ContextualPair)
    d = aos(s.data)
    p = aos(_adjust(s.primary, axes(d)))
    return wrapif(p .=> d, Pair)
end

function merge_primary_data(c::ContextualPair, (p, d))
    return ContextualPair(c.context, merge(c.primary, p), merge(c.data, d))
end

# data context: integers and symbols are columns

struct DataContext{T}
    table::T
end

Base.:(==)(s1::DataContext, s2::DataContext) = s1.table == s2.table

Base.pairs(t::ContextualPair{<:DataContext}) = pairs(ContextualPair(nothing, t.primary, t.data))

function extract_column(t, col::Union{Symbol, Int}, wrap=false)
    colname = col isa Symbol ? col : columnnames(t)[col]
    v = NamedDimsArray{(colname,)}(getcolumn(t, col))
    return wrap ? fill(v) : v
end
extract_column(t, c::NamedTuple, wrap=false) = map(x -> extract_column(t, x, wrap), c)
extract_column(t, c::AbstractArray, wrap=false) = map(x -> extract_column(t, x, false), c)
extract_column(t, c::DimsSelector, wrap=false) = c

function group(cols, p, d)
    pv = keepvectors(p)
    list = if isempty(pv)
        [ContextualPair(DataContext(cols), p, d)]
    else
        sa = StructArray(map(pool, pv))
        map(finduniquesorted(sa)) do (k, idxs)
            v = map(t -> map(x -> view(x, idxs), t), d)
            subtable = coldict(cols, idxs)
            namedkey = map(pv, k) do col, el
                NamedEntry(get_name(col), el)
            end
            newkey = merge(p, map(fill, namedkey))
            ContextualPair(DataContext(subtable), newkey, v)
        end
    end
    return ContextualMap(list)
end

function merge_primary_data(s::ContextualPair{<:DataContext}, (primary, data))
    cols, p, d = s.context.table, s.primary, s.data
    p2 = extract_column(cols, primary)
    d2 = extract_column(cols, data, true)
    return group(cols, merge(p, p2), merge(d, d2))
end

table(x) = ContextualMap([ContextualPair(DataContext(coldict(x)))])

# slice context: slice across dims

struct SliceContext{N}
    dims::NTuple{N, Int}
end
slice(args::Int...) = ContextualMap([ContextualPair(SliceContext(args))])

function Base.pairs(c::ContextualPair{<:SliceContext})
    d = map(s.data) do col
        mapslices(v -> [v], col; dims=s.dims)
    end
    return pairs(ContextualPair(nothing, s.primary, d))
end

Base.:(==)(s1::SliceContext, s2::SliceContext) = s1.dims == s2.dims

# Constructors

function (c::ContextualMap)(d::ContextualMap)
    list = [ContextualMap(cp(d)).list for cp in c.list]
    return ContextualMap(reduce(vcat, list))
end

function (c::ContextualPair{Nothing})(d::ContextualMap)
    return merge_primary_data(d, c.primary => c.data)
end

function primary(; kwargs...)
    cp = ContextualPair(nothing, values(kwargs), NamedTuple())
    return ContextualMap(cp)
end
function data(args...; kwargs...)
    cp = ContextualPair(nothing, NamedTuple(), namedtuple(args...; kwargs...))
    return ContextualMap(cp)
end
