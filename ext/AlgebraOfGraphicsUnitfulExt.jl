module AlgebraOfGraphicsUnitfulExt

import AlgebraOfGraphics
import Unitful

function AlgebraOfGraphics.strip_units(scale, data::AbstractVector{<:Unitful.Quantity})
    o = oneunit(eltype(scale.extrema))
    scale_unitless = AlgebraOfGraphics.ContinuousScale(scale.extrema ./ o, scale.label, scale.force, scale.props)
    data_unitless = Unitful.uconvert.(Unitful.NoUnits, data ./ o)
    return scale_unitless, data_unitless
end

function AlgebraOfGraphics.unit_string(q::Unitful.Quantity)
    string(Unitful.unit(q))
end

end