to_points(ring) = map(Point2f, ring)

function to_polygon(rings)
    exterior, interiors... = map(to_points, rings)
    return Polygon(exterior, interiors)
end

function to_multipolygon(coords)
    polygons = map(to_polygon, coords)
    return MultiPolygon(polygons)
end

function to_geometry(shape)
    if !isgeometry(shape)
        msg = "Argument must be a geometry"
        throw(ArgumentError(msg))
    end
    trait = geomtrait(shape)
    coords = coordinates(shape)
    if trait isa PolygonTrait
        return to_polygon(coords)
    elseif trait isa MultiPolygonTrait
        return to_multipolygon(coords)
    else
        msg = "Only `Polygon` and `MultiPolygon` are supported"
        throw(ArgumentError(msg))
    end
end

function geodata(t)
    error(
        """
        `geodata` has been deprecated.
        For geographic data, use `data` with the `Choropleth` recipe.
        """
    )
end

"""
    choropleth(polygons; kwargs...)

Choropleth map, where regions are defined by `polygons`.
## Attributes
$(ATTRIBUTES)
"""
@recipe(Choropleth) do scene
    return default_theme(scene, Poly)
end

Makie.convert_arguments(::Type{<:Choropleth}, v::AbstractVector) = PlotSpec{Poly}(map(to_geometry, v))
