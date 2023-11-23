struct TrivialTransformation end

const trivialtransformation = TrivialTransformation()

(::TrivialTransformation)(pt) = pt[1], pt[2]

to_points(transf, ring) = map(Point2f∘transf, ring)

function to_polygon(transf, rings)
    exterior, interiors... = map(Base.Fix1(to_points, transf), rings)
    return Polygon(exterior, interiors)
end

function to_multipolygon(transf, coords)
    polygons = map(Base.Fix1(to_polygon, transf), coords)
    return MultiPolygon(polygons)
end

function to_geometry(transf, shape)
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

function geodata(featuretable)
    @warn(
        """
        `geodata` has been deprecated.
        For geographic data, use `data` with the `Choropleth` recipe.
        """
    )
    featurecols = columns(featuretable)
    names = Tuple(columnnames(featurecols))
    cols = map(names) do sym
        col = getcolumn(featurecols, sym)
        return sym === :geometry ? map(Base.Fix1(to_geometry, trivialtransformation), col) : col
    end
    table = NamedTuple{names}(cols)
    return data(table)
end

"""
    choropleth(geometries; transformation, attributes...)

Choropleth map, where regions are defined by `geometries`.
Use `transformation` to transform coordinates
(see [Proj.jl](https://github.com/JuliaGeo/Proj.jl) for more information).

!!! warning

    The `transformation` keyword argument is experimental and could be deprecated
    (even in a non-breaking release) in favor of a different syntax.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Choropleth) do scene
    return default_theme(scene, Poly)
end

Makie.used_attributes(::Type{<:Choropleth}, v::AbstractVector) = (:transformation,)

function Makie.convert_arguments(::Type{<:Choropleth}, v::AbstractVector;
                                 transformation=trivialtransformation)
    geometries = map(Base.Fix1(to_geometry, transformation), v)
    return PlotSpec(:poly, geometries)
end
