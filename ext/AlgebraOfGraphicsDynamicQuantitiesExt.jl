module AlgebraOfGraphicsDynamicQuantitiesExt

import AlgebraOfGraphics
import DynamicQuantities
const DQ = DynamicQuantities

AlgebraOfGraphics.extrema_finite(v::AbstractVector{<:DQ.Quantity}) = extrema(Iterators.filter(isfinite, skipmissing(v)))

struct DimensionMismatch{X1, X2} <: Exception
    x1::X1
    x2::X2
end

dimensionless(x, u::DQ.Quantity{<:Any, <:DQ.SymbolicDimensions}) = DQ.ustrip(DQ.uconvert(u, x))
function dimensionless(x, u::DQ.Quantity{<:Any, <:DQ.Dimensions})
    xexp = DQ.uexpand(x)
    uexp = DQ.uexpand(u)
    DQ.dimension(xexp) == DQ.dimension(uexp) || throw(DimensionMismatch(x, u))
    return DQ.ustrip(xexp)
end

function AlgebraOfGraphics.strip_units(scale, data::AbstractVector{<:DQ.Quantity})
    u = AlgebraOfGraphics.getunit(scale)
    scale_unitless = AlgebraOfGraphics.ContinuousScale(dimensionless.(scale.extrema, u), scale.label, scale.force, scale.props)
    data_unitless = dimensionless.(data, u)
    return scale_unitless, data_unitless
end

AlgebraOfGraphics.to_unitless_numerical(x::AbstractVector{<:DQ.Quantity}) = DQ.ustrip.(x)
AlgebraOfGraphics.to_unitless_numerical(x::DQ.Quantity) = DQ.ustrip(x)

# `oneunit` on the DQ.Quantity element type fails because the dimensions are stored at runtime,
# not in the type, so we have to inspect values. Trusting `first(x)` alone would silently accept
# vectors with mixed units; instead verify every element shares the same `oneunit` and error
# otherwise. Empty vectors still error here because there's no element to read the unit from,
# which matches the documented limitation that empty unit-bearing groups cannot be analysed.
function only_oneunit(x::AbstractVector{<:DQ.Quantity})
    first_q, rest = Iterators.peel(x)
    u = oneunit(first_q)
    for q in rest
        oneunit(q) == u || error("Encountered multiple different units in a DynamicQuantities vector: $u and $(oneunit(q))")
    end
    return u
end

AlgebraOfGraphics.from_unitless_numerical(x̂::AbstractArray{<:Real}, x::AbstractVector{<:DQ.Quantity}) =
    x̂ .* only_oneunit(x)

AlgebraOfGraphics.is_unit(::DynamicQuantities.Quantity) = true # there seems to be no FreeUnits equivalent in DQ

function AlgebraOfGraphics.unit_string(u::DQ.Quantity)
    return string(DQ.dimension(u))
end

AlgebraOfGraphics.getunit(v::AbstractVector{<:DQ.Quantity}) = only_oneunit(v)

function AlgebraOfGraphics.getunit(scale::AlgebraOfGraphics.ContinuousScale{T}) where {T <: DynamicQuantities.Quantity}
    o1, o2 = oneunit.(scale.extrema)
    o1 == o2 || error("Different ones $o1 $o2")
    o = o1
    if scale.props.unit === nothing
        return o
    else
        if !AlgebraOfGraphics.dimensionally_compatible(o, scale.props.unit)
            error("Incompatible units in continuous scale properties: Unit from scale extrema is \"$o\" and from scale properties \"$(scale.props.unit)\" which are not dimensionally compatible.")
        end
        return scale.props.unit
    end
end

function AlgebraOfGraphics.dimensionally_compatible(q1::DynamicQuantities.Quantity, q2::DynamicQuantities.Quantity)
    return try
        # because we can't uconvert to Dimensions its not super straightforward
        # to check if the units are compatible, so we reuse the conversion mechanism
        dimensionless(q1, q2)
        true
    catch err
        if err isa DimensionMismatch || err isa DQ.DimensionError
            false
        else
            rethrow(err)
        end
    end
end

# a unit-free aesthetic (`nothing`) is a pure number, so it matches a dimensionless quantity
# (e.g. an ABLines slope when AesX and AesY share the same unit).
AlgebraOfGraphics.dimensionally_compatible(q::DQ.Quantity, ::Nothing) = iszero(DQ.dimension(DQ.uexpand(q)))
AlgebraOfGraphics.dimensionally_compatible(::Nothing, q::DQ.Quantity) = iszero(DQ.dimension(DQ.uexpand(q)))

end
