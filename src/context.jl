# contextual pair and map

struct ContextualPair{C, P<:NamedTuple, D<:NamedTuple}
    context::C
    primary::P
    data::D
end
ContextualPair(context) = ContextualPair(context, NamedTuple(), NamedTuple())

function Base.:(==)(s1::ContextualPair, s2::ContextualPair)
    s1.context == s2.context && s1.primary == s2.primary && s1.data == s2.data
end

function Base.show(io::IO, c::ContextualPair{C}) where {C}
    Base.print(io, "ContextualPair of context type $C")
end

struct ContextualMap{L<:ContextualPair}
    list::Vector{L}
end
ContextualMap(c::ContextualMap) = c
ContextualMap(c::ContextualPair) = ContextualMap([c])
ContextualMap() = ContextualMap([ContextualPair(nothing, NamedTuple(), NamedTuple())])

function Base.show(io::IO, c::ContextualMap)
    Base.print(io, "ContextualMap of length $(length(c.list))")
end

Base.:(==)(s1::ContextualMap, s2::ContextualMap) = s1.list == s2.list

function merge_primary_data(c::ContextualMap, pd)
    l = [ContextualMap(merge_primary_data(cp, pd)).list for cp in c.list]
    return ContextualMap(reduce(vcat, l))
end

function Base.pairs(c::ContextualMap)
    l = [vec(collect(pairs(cp))) for cp in c.list]
    return reduce(vcat, l)
end

# Algebra and constructors

function Base.:+(c1::ContextualMap, c2::ContextualMap)
    return ContextualMap(vcat(c1.list, c2.list))
end

function Base.:*(c1::ContextualMap, c2::ContextualMap)
    l = [ContextualMap(cp1 * cp2).list for cp1 in c1.list for cp2 in c2.list]
    return ContextualMap(reduce(vcat, l))
end

# TODO: deal with context more carefully here?
function Base.:*(c1::ContextualPair, c2::ContextualPair)
    return merge_primary_data(c1, c2.primary => c2.data)
end

function primary(; kwargs...)
    cp = ContextualPair(nothing, values(kwargs), NamedTuple())
    return ContextualMap(cp)
end

function data(args...; kwargs...)
    cp = ContextualPair(nothing, NamedTuple(), namedtuple(args...; kwargs...))
    return ContextualMap(cp)
end

# Default: broadcast context

adjust(x, d) = x

struct DimsSelector{T}
    x::T
end
dims(args...) = DimsSelector(args)

adjust(ds::DimsSelector, d) = [c[ds.x...] for c in CartesianIndices(d)]

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa AbstractArray ? v : fill(v)
end

function Base.pairs(s::ContextualPair)
    d = aos(s.data)
    p = aos(map(v -> adjust(v, d), s.primary))
    return Broadcast.broadcastable(p .=> d)
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
    d = map(c.data) do col
        mapslices(v -> [v], col; dims=c.context.dims)
    end
    return pairs(ContextualPair(nothing, c.primary, d))
end

Base.:(==)(s1::SliceContext, s2::SliceContext) = s1.dims == s2.dims

