struct DimsSelector{N} <: AbstractContextual
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

Broadcast.broadcastable(d::DimsSelector) = fill(d)

Base.:(==)(s1::DimsSelector, s2::DimsSelector) = s1.dims == s2.dims
Base.isless(s1::DimsSelector, s2::DimsSelector) = isless(s1.dims, s2.dims)

function extract_column(t, col::Union{Symbol, Int})
    colname = col isa Symbol ? col : columnnames(t)[col]
    return NamedDimsArray{(colname,)}(getcolumn(t, col))
end
extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, c::Style) = Style(extract_column(t, c.nt))
extract_column(t, v::AbstractArray) = v

adjust(v, c) = v
adjust(x::NamedTuple, c) = map(v -> adjust(v, c), x)
adjust(v::DimsSelector, c) = c[v.dims...]

function aos(d::NamedTuple{names}) where names
    v = broadcast((args...) -> NamedTuple{names}(args), d...)
    return v isa NamedTuple ? [v] : v
end

function expand(s::Style)
    any(t -> isa(t, DimsSelector), s.nt) || return [s]
    v = aos(s.nt)
    styles = [Style(adjust(v[c], c)) for c in CartesianIndices(v)]
    return vec(styles)
end

function expand(g::GraphicalOrContextual)
    l = layers(g)
    dict = LayerDict()
    for (key, val) in pairs(l)
        dict[key] = reduce(vcat, expand.(val))
    end
    return Layers(dict)
end

function (s::GraphicalOrContextual)(t)
    l = layers(expand(s))
    cols = coldict(t)
    dict = LayerDict()
    for (sp, styles) in pairs(l)
        dict[sp] = map(style -> extract_column(cols, style), styles)
    end
    return Layers(dict)
end

function (s::GraphicalOrContextual)(c::AbstractFeatureCollection)
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
    return s(cols)
end
