# abstract type architecture

abstract type AbstractContextual end

abstract type AbstractContext <: AbstractContextual end

# contextual pair and map

struct ContextualPair{C, P<:NamedTuple, D<:NamedTuple} <: AbstractContextual
    context::C
    group::P
    style::D
end
ContextualPair(context) = ContextualPair(context, NamedTuple(), NamedTuple())

function Base.:(==)(s1::ContextualPair, s2::ContextualPair)
    s1.context == s2.context && s1.group == s2.group && s1.style == s2.style
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

Base.pairs(c::ContextualMap) = collect(Iterators.flatten(pairs(cp) for cp in entries(c)))

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
    return merge_group_style(c1, c2.group => c2.style)
end

group(; kwargs...) = ContextualPair(nothing, values(kwargs), NamedTuple())
style(t...; nt...) = ContextualPair(nothing, NamedTuple(), namedtuple(t...; nt...))

# Default: broadcast context

adjust(x, d) = x
adjust(x::NamedTuple, d) = map(v -> adjust(v, d), x)

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? [v] : v
end

function Base.pairs(s::ContextualPair)
    d = aos(s.style)
    p = aos(adjust(s.group, d))
    return p .=> d
end

function merge_group_style(c::ContextualPair, (p, d))
    return ContextualPair(c.context, merge(c.group, p), merge(c.style, d))
end

# slicing context

struct DimsSelector{N} <: AbstractContext
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Base.:(==)(s1::DimsSelector, s2::DimsSelector) = s1.dims == s2.dims
Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

adjust(ds::DimsSelector, d) = [c[ds.dims...] for c in CartesianIndices(d)]

function Base.pairs(c::ContextualPair{<:DimsSelector})
    d = map(c.style) do col
        mapslices(v -> [v], col; dims=c.context.dims)
    end
    return pairs(ContextualPair(nothing, c.group, d))
end

# style context: integers and symbols are columns

struct DataContext{T} <: AbstractContext
    data::T
end

data(x) = DataContext(coldict(x))

Base.:(==)(s1::DataContext, s2::DataContext) = s1.data == s2.data

Base.pairs(t::ContextualPair{<:DataContext}) = pairs(ContextualPair(nothing, t.group, t.style))

function extract_column(t, col::Union{Symbol, Int}, wrap=false)
    colname = col isa Symbol ? col : columnnames(t)[col]
    v = NamedDimsArray{(colname,)}(getcolumn(t, col))
    return wrap ? fill(v) : v
end
function extract_column(t, c::DimsSelector, wrap=false)
    ra = RefArray(fill(UInt8(1), length(getcolumn(t, 1))))
    return PooledArray(ra, Dict(c => UInt8(1)))
end
extract_column(t, c::NamedTuple, wrap=false) = map(x -> extract_column(t, x, wrap), c)
extract_column(t, c::AbstractArray, wrap=false) = map(x -> extract_column(t, x, false), c)

extract_view(t, idxs) = view(t, idxs)
extract_view(t::AbstractArray, idxs) = map(v -> view(v, idxs), t)
function extract_view(t::Union{NamedTuple, Tuple}, idxs)
    map(v -> extract_view(v, idxs), t)
end

addname(name, el) = fill(NamedEntry(name, el))
addname(_, el::DimsSelector) = el
addname(names::NamedTuple, els::NamedTuple) = map(addname, names, els)

# TODO consider further optimizations with refine_perm!
function _group(cols, p, d, pcols, names)
    sa = StructArray(pcols)
    list = map(finduniquesorted(sa)) do (k, idxs)
        v = extract_view(d, idxs)
        subdata = coldict(cols, idxs)
        newkey = merge(p, addname(names, k))
        ContextualPair(DataContext(subdata), newkey, v)
    end
    return ContextualMap(list)
end

function merge_group_style(s::ContextualPair{<:DataContext}, (group, style))
    ctx, p, d = s.context, s.group, s.style
    cols = ctx.data
    d′ = extract_column(cols, style, true)
    d′′ = merge(d, d′)
    p′ = extract_column(cols, group)
    ns = map(get_name, p′)
    isempty(p′) ? ContextualPair(ctx, p, d′′) : _group(cols, p, d′′, map(pool, p′), ns)
end

# Geo context

function data(c::AbstractFeatureCollection)
    cols = OrderedDict{Symbol, AbstractVector}()
    cols[:geometry] = Vector{Vector{Point2f0}}(undef, 0)
    for f in c.features
        geom = GeoInterface.geometry(f)
        coords = geom isa AbstractMultiPolygon ? coordinates(geom) : [coordinates(geom)]
        polies = [Point2f0.(first(c)) for c in coords]
        append!(cols[:geometry], polies)
        np = length(polies)
        for (key, val) in pairs(GeoInterface.properties(f))
            k = Symbol(key)
            v = get(cols, k, Union{}[])
            vs = fill(val, np)
            cols[k] = val isa eltype(v) ? append!(v, vs) : vcat(v, vs)
        end
    end
    return data(cols) * style(:geometry)
end
