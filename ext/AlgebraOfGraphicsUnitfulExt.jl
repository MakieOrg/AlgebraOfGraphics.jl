module AlgebraOfGraphicsUnitfulExt

import AlgebraOfGraphics
import Unitful

const MaybeMissingQuantities = AbstractVector{<:Union{Missing, Unitful.Quantity}}

function AlgebraOfGraphics.strip_scale(scale::AlgebraOfGraphics.ContinuousScale{<:Unitful.Quantity})
    u = AlgebraOfGraphics.getunit(scale)
    return AlgebraOfGraphics.ContinuousScale(Unitful.ustrip.(u, scale.extrema), scale.label, scale.force, scale.props)
end

function AlgebraOfGraphics.strip_scale(scale, data::MaybeMissingQuantities)
    u = AlgebraOfGraphics.getunit(scale)
    data_unitless = AlgebraOfGraphics.map_nonmissing(x -> Unitful.ustrip(u, x), data)
    return AlgebraOfGraphics.strip_scale(scale), data_unitless
end

AlgebraOfGraphics.to_unitless_numerical(x::MaybeMissingQuantities) = AlgebraOfGraphics.map_nonmissing(Unitful.ustrip, x)
AlgebraOfGraphics.to_unitless_numerical(x::Unitful.Quantity) = Unitful.ustrip(x)
AlgebraOfGraphics.from_unitless_numerical(x̂::AbstractArray{<:Real}, x::MaybeMissingQuantities) =
    x̂ .* Unitful.unit(nonmissingtype(eltype(x)))

function AlgebraOfGraphics.unit_string(u::Unitful.FreeUnits)
    return string(u)
end

AlgebraOfGraphics.getunit(v::MaybeMissingQuantities) = Unitful.unit(nonmissingtype(eltype(v)))

AlgebraOfGraphics.is_unit(::Unitful.FreeUnits) = true

function AlgebraOfGraphics.getunit(scale::AlgebraOfGraphics.ContinuousScale{T}) where {T <: Unitful.Quantity}
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

function AlgebraOfGraphics.dimensionally_compatible(u1::Unitful.FreeUnits, u2::Unitful.FreeUnits)
    return Unitful.dimension(u1) == Unitful.dimension(u2)
end

# a unit-free aesthetic (`nothing`) is a pure number, so it matches a dimensionless unit
# (e.g. an ABLines slope when AesX and AesY share the same unit collapses to a plain number).
AlgebraOfGraphics.dimensionally_compatible(u::Unitful.FreeUnits, ::Nothing) = Unitful.dimension(u) == Unitful.NoDims
AlgebraOfGraphics.dimensionally_compatible(::Nothing, u::Unitful.FreeUnits) = Unitful.dimension(u) == Unitful.NoDims

end
