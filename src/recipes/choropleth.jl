take2(pt) = (pt[1], pt[2])

to_points(transf::T, ring) where {T} = map(Point2f∘transf, ring)

function to_polygon(transf::T, rings) where {T}
    exterior, interiors... = map(Base.Fix1(to_points, transf), rings)
    return Polygon(exterior, interiors)
end

function to_multipolygon(transf::T, coords) where {T}
    polygons = map(Base.Fix1(to_polygon, transf), coords)
    return MultiPolygon(polygons)
end

function to_geometry(transf::T, shape) where {T}
    if !isgeometry(shape)
        msg = "Argument must be a geometry"
        throw(ArgumentError(msg))
    end
    trait = geomtrait(shape)
    coords = coordinates(shape)
    if trait isa PolygonTrait
        return to_polygon(transf, coords)
    elseif trait isa MultiPolygonTrait
        return to_multipolygon(transf, coords)
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
    choropleth(geometries; transformation, attributes...)

Choropleth map, where regions are defined by `geometries`.
Use `transformation` to transform coordinates
(see [Proj.jl](https://github.com/JuliaGeo/Proj.jl) for more information).
## Attributes
$(ATTRIBUTES)
"""
@recipe(Choropleth) do scene
    return default_theme(scene, Poly)
end

function Makie.convert_arguments(::Type{<:Choropleth}, v::AbstractVector; transformation=take2)
    geometries = map(Base.Fix1(to_geometry, transformation), v)
    return PlotSpec{Poly}(geometries)
end
