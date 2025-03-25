module AlgebraOfGraphicsUnitfulExt

import AlgebraOfGraphics
import Unitful

function AlgebraOfGraphics.strip_units(scale, data::AbstractVector{<:Unitful.Quantity})
    u = AlgebraOfGraphics.getunit(scale)
    scale_unitless = AlgebraOfGraphics.ContinuousScale(Unitful.ustrip.(u, scale.extrema), scale.label, scale.force, scale.props)
    data_unitless = Unitful.ustrip.(u, data)
    return scale_unitless, data_unitless
end

function AlgebraOfGraphics.unit_string(u::Unitful.FreeUnits)
    string(u)
end

AlgebraOfGraphics.is_unit(::Unitful.FreeUnits) = true

function AlgebraOfGraphics.getunit(scale::AlgebraOfGraphics.ContinuousScale{T}) where T <: Unitful.Quantity
    u = Unitful.unit(eltype(scale.extrema))
    if scale.props.unit === nothing
        return u
    else
        if Unitful.dimension(scale.props.unit) == Unitful.dimension(u)
            return scale.props.unit
        else
            error("Incompatible units in continuous scale properties: Unit from scale extrema is \"$u\" and from scale properties \"$(scale.props.unit)\" which are not dimensionally compatible.")
        end
    end
end

end