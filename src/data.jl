# style context: integers and symbols are columns

function extract_column(t, col::Union{Symbol, Int})
    colname = col isa Symbol ? col : columnnames(t)[col]
    return NamedDimsArray{(colname,)}(getcolumn(t, col))
end
extract_column(t, c::Union{Tuple, NamedTuple, AbstractArray}) = map(x -> extract_column(t, x), c)
extract_column(t, c::Style) = Style(extract_column(t, c.nt))

function (s::GraphicalOrContextual)(t)
    l = layers(s)
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
