abstract type AbstractContextual end

abstract type AbstractContext <: AbstractContextual end

struct Style{C} <: AbstractContextual
    context::C
    value::NamedTuple
end
Style(s::NamedTuple=NamedTuple()) = Style(nothing, s)
Style(c::AbstractContext) = Style(c, NamedTuple())
Style(s::Style) = s

style(args...; kwargs...) = Style(namedtuple(args...; kwargs...))

function Base.merge(s1::Style, s2::Style)
    context = s2.context === nothing ? s2.context : s1.context
    return Style(context, merge(s1.value, s2.value))
end

styles(s::Style) = styles(s.context, s)
styles(::Any, s::Style) = [s]

## Dims context

struct DimsSelector{N} <: AbstractContext
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Broadcast.broadcastable(d::DimsSelector) = fill(d)

Base.:(==)(s1::DimsSelector, s2::DimsSelector) = s1.dims == s2.dims
Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? fill(v) : v
end

adjust(val, c) = c
adjust(val::DimsSelector, c) = CartesianIndex((c[i] for i in val.dims)...)

function styles(::DimsSelector{0}, s::Style)
    nts = aos(s.value)
    adjusted = map(CartesianIndices(nts)) do c
        nt = nts[c]
        return map(nt) do val
            adjust(val, c)
        end
    end
    return map(Style, adjusted)
end

function styles(d::DimsSelector, s::Style)
    value = map(s.value) do v
        v isa AbstractArray ? mapslices(x -> [x], v; dims=d.dims) : v
    end
    return styles(Style(dims(), value))
end

# data context: integers and symbols are columns

struct DataContext{T} <: AbstractContext
    data::T
end

data(x) = DataContext(coldict(x))

Base.:(==)(s1::DataContext, s2::DataContext) = s1.data == s2.data

function extract_column(t, col::Union{Symbol, Int})
    colname = col isa Symbol ? col : columnnames(t)[col]
    return NamedDimsArray{(colname,)}(getcolumn(t, col))
end
extract_columns(t, val::DimsSelector) = t
extract_columns(t, val::Union{Tuple, AbstractArray}) = map(t -> extract_column(data, t), val)
extract_columns(t, val) = fill(extract_column(t, val))

function styles(ctx::DataContext, s::Style)
    data = ctx.data
    cols = map(val -> extract_columns(ctx.data, val), s.value)
    return styles(Style(dims(), cols))
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
