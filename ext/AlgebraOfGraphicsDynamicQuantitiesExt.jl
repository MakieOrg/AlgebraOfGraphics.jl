module AlgebraOfGraphicsDynamicQuantitiesExt

import AlgebraOfGraphics
import DynamicQuantities
const DQ = DynamicQuantities

AlgebraOfGraphics.extrema_finite(v::AbstractVector{<:DQ.Quantity}) = extrema(Iterators.filter(isfinite, skipmissing(v)))

function AlgebraOfGraphics.strip_units(scale, data::AbstractVector{<:DQ.Quantity})
    o1, o2 = oneunit.(scale.extrema)
    o1 == o2 || error("Different ones $o1 $o2")

    function dimensionless(x, oneunit)
        x_dimless = x / oneunit
        iszero(DQ.dimension(x_dimless)) || error("Value $x was not dimensionless after division with $oneunit")
        return DQ.ustrip(x_dimless)
    end

    scale_unitless = AlgebraOfGraphics.ContinuousScale(dimensionless.(scale.extrema, o1), scale.label, scale.force, scale.props)
    data_unitless = dimensionless.(data, o1)
    return scale_unitless, data_unitless
end

function AlgebraOfGraphics.unit_string(q::DQ.Quantity)
    string(DQ.dimension(q))
end

end