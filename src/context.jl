abstract type AbstractContextual end

abstract type AbstractContext <: AbstractContextual end

struct Style{C} <: AbstractContextual
    context::C
    value::NamedTuple
end
Style(s::NamedTuple=NamedTuple()) = Style(nothing, s)
Style(c::AbstractContext) = Style(c, NamedTuple())
Style(s::Style) = s

function Base.show(io::IO, s::Style)
    print(io, "Style with entries ")
    show(io, keys(s.value))
end

style(args...; kwargs...) = Style(namedtuple(args...; kwargs...))

Base.:*(s1::AbstractContextual, s2::AbstractContextual) = merge(Style(s1), Style(s2))

Base.merge(s1::Style, s2::Style) = _merge(s1.context, s1, s2)
Base.pairs(s::Style) = _pairs(s.context, s)

# interface and fallbacks

_merge(c, s1::Style, s2::Style) = Style(c, merge(s1.value, s2.value))
_pairs(c, s::Style) = [NamedTuple() => s]

## Dims context

struct DimsSelector{N} <: AbstractContext
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Broadcast.broadcastable(d::DimsSelector) = fill(d)

Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? fill(v) : v
end

function adjust(val::DimsSelector, c, nts)
    is = collect(val.dims)
    ax, cf = axes(nts)[is], Tuple(c)[is]
    return NamedDimsArray{(Symbol(""),)}([LinearIndices(ax)[cf...]])
end

# make it a pair list
function _pairs(::DimsSelector{0}, s::Style)
    nts = aos(s.value)
    ps = map(CartesianIndices(nts)) do c
        nt = nts[c]
        dskeys = filter(keys(nt)) do key
            nt[key] isa DimsSelector
        end
        dsvalues = map(dskeys) do key
            val = nt[key]
            return adjust(val, c, nts)
        end
        ds = (; zip(dskeys, dsvalues)...)
        nds = Base.structdiff(nt, ds)
        return ds => Style(nds)
    end
    return vec(ps)
end

function _pairs(d::DimsSelector, s::Style)
    value = map(s.value) do v
        v isa AbstractArray ? mapslices(x -> [x], v; dims=d.dims) : v
    end
    return pairs(Style(dims(), value))
end

# data context: integers and symbols are columns

struct DataContext{T, NT, I<:AbstractVector{Int}} <: AbstractContext
    data::T
    pkeys::NT
    perm::I
end

function DataContext(data)
    col = getcolumn(data, 1)
    DataContext(data, NamedTuple(), axes(col, 1))
end

data(x) = DataContext(coldict(x))

iscategorical(v) = !(eltype(v) <: Number)
function unwrap_categorical(values)
    pc = filter(keys(values)) do key
        t = values[key]
        iskw = tryparse(Int, String(key)) === nothing
        iskw && ndims(t) == 0 && iscategorical(t[])
    end
    return (; zip(pc, map(key -> values[key][], pc))...)
end

function refine_perm(perm, pc, n)
    if n == length(pc)
        perm
    elseif n == 0
        sortperm(StructArray(pc))
    else
        x, y = pc[n], pc[n+1]
        refine_perm!(copy(perm), pc, n, x, y, 1, length(x))
    end
end

optimize_cols(v::NamedDimsArray) = refs(parent(v))
optimize_cols(v::Union{Tuple, NamedTuple}) = map(optimize_cols, v)

function _merge(c::DataContext, s1::Style, s2::Style)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    nt = map(val -> extract_columns(data, val), s2.value)
    newpkeys = unwrap_categorical(nt)
    @assert isempty(intersect(keys(pkeys), keys(newpkeys)))
    allpkeys = merge(pkeys, newpkeys)
    # unwrap from NamedDimsArray to perform the sorting
    allperm = refine_perm(perm, optimize_cols(allpkeys), length(pkeys))
    ctx = DataContext(data, allpkeys, allperm)
    return Style(ctx, merge(s1.value, Base.structdiff(nt, newpkeys)))
end

function _pairs(c::DataContext, s::Style)
    data, pkeys, perm = c.data, c.pkeys, c.perm
    isempty(pkeys) && return pairs(Style(dims(), s.value))
    # uwrap for sorting computations
    itr = GroupPerm(StructArray(optimize_cols(pkeys)), perm)
    sa = StructArray(pkeys)
    nestedpairs = map(itr) do idxs
        i1 = perm[first(idxs)]
        # keep value categorical and preserve name by taking a mini slice
        k = map(col -> col[i1:i1], pkeys)
        cols = map(s.value) do val
            extract_views(val, perm[idxs])
        end
        [merge(k, p) => v for (p, v) in pairs(Style(dims(), cols))]
    end
    return reduce(vcat, nestedpairs)
end

extract_views(cols, idxs) = map(t -> view(t, idxs), cols)
extract_views(cols::DimsSelector, idxs) = cols

function extract_column(t, (nm, f)::Pair)
    colname = nm isa Symbol ? nm : columnnames(t)[nm]
    vals = f(getcolumn(t, nm))
    p = iscategorical(vals) ? categorical(vals) : vals
    return NamedDimsArray{(colname,)}(p)
end
extract_column(t, nm::Union{Symbol, Int}) = extract_column(t, nm => identity)

extract_columns(t, val::DimsSelector) = val
extract_columns(t, val::Union{Tuple, AbstractArray}) = map(v -> extract_column(t, v), val)
extract_columns(t, val) = fill(extract_column(t, val))

# Geo context

using GeoInterface: AbstractMultiPolygon, AbstractFeatureCollection, coordinates, GeoInterface

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
