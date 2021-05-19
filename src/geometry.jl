to_points(ring) = map(Point2f0, ring)

function to_polygon(rings)
    exterior, interiors... = map(to_points, rings)
    return Polygon(exterior, interiors)
end

function to_multipolygon(coords)
    polygons = map(to_polygon, coords)
    return MultiPolygon(polygons)
end

function to_geometry(shape)
    type = geotype(shape)
    coords = coordinates(shape)
    if type === :Polygon
        return to_polygon(coords)
    elseif type === :MultiPolygon
        return to_multipolygon(coords)
    else
        msg = "Only `:Polygon` and `:MultiPolygon` are supported"
        throw(ArgumentError(msg))
    end
end

function geodata(featuretable)
    featurecols = columns(featuretable)
    names = Tuple(columnnames(featurecols))
    cols = map(names) do sym
        col = getcolumn(featurecols, sym)
        return sym === :geometry ? map(to_geometry, col) : col
    end
    table = NamedTuple{names}(cols)
    return data(table)
end
