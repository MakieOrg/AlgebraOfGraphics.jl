# abstract type architecture

abstract type AbstractContextual end

abstract type AbstractContext <: AbstractContextual end

# contextual pair and map

struct ContextualPair{C, P<:NamedTuple, D<:NamedTuple} <: AbstractContextual
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

struct ContextualMap{L<:ContextualPair} <: AbstractContextual
    entries::Vector{L}
end
ContextualMap() = ContextualMap(ContextualPair(nothing))
ContextualMap(c::AbstractContextual) = ContextualMap(entries(c))

entries(c::ContextualMap)   = c.entries
entries(c::ContextualPair)  = [c]
entries(c::AbstractContext) = entries(ContextualPair(c))

function Base.show(io::IO, c::ContextualMap)
    Base.print(io, "ContextualMap of length $(length(entries(c)))")
end

Base.:(==)(s1::ContextualMap, s2::ContextualMap) = entries(s1) == entries(s2)

Base.pairs(c::ContextualMap) = Iterators.flatten(pairs(cp) for cp in entries(c))

# Algebra and constructors

function Base.:+(c1::AbstractContextual, c2::AbstractContextual)
    return ContextualMap(vcat(map(entries, (c1, c2))...))
end

function Base.:*(c1::AbstractContextual, c2::AbstractContextual)
    l = [entries(cp1 * cp2) for cp1 in entries(c1) for cp2 in entries(c2)]
    return ContextualMap(reduce(vcat, l))
end

# TODO: deal with context more carefully here?
function Base.:*(c1::ContextualPair, c2::ContextualPair)
    return merge_primary_data(c1, c2.primary => c2.data)
end

primary(; kwargs...) = ContextualPair(nothing, values(kwargs), NamedTuple())
data(t...; nt...) = ContextualPair(nothing, NamedTuple(), namedtuple(t...; nt...))

# Default: broadcast context

adjust(x, d) = x

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? [v] : v
end

function Base.pairs(s::ContextualPair)
    d = aos(s.data)
    p = aos(map(v -> adjust(v, d), s.primary))
    return p .=> d
end

function merge_primary_data(c::ContextualPair, (p, d))
    return ContextualPair(c.context, merge(c.primary, p), merge(c.data, d))
end

# slicing context

struct DimsSelector{N} <: AbstractContext
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Base.:(==)(s1::DimsSelector, s2::DimsSelector) = s1.dims == s2.dims

adjust(ds::DimsSelector, d) = [c[ds.dims...] for c in CartesianIndices(d)]

function Base.pairs(c::ContextualPair{<:DimsSelector})
    d = map(c.data) do col
        mapslices(v -> [v], col; dims=c.context.dims)
    end
    return pairs(ContextualPair(nothing, c.primary, d))
end

# data context: integers and symbols are columns

struct DataContext{T} <: AbstractContext
    table::T
end

table(x) = DataContext(coldict(x))

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

