Base.@kwdef struct ContoursAnalysis
    levels::Union{Int,Vector{Float64}}
    kwargs::Dict{Symbol,Any}
end

function (c::ContoursAnalysis)(input::ProcessedLayer)
    z_limits = AlgebraOfGraphics.nested_extrema_finite(input.positional[3])
    _levels(limits, levels::Int) = range(limits..., length = levels)
    lvls = _levels(z_limits, c.levels)
    named = merge(input.named, dictionary([:color => fill(lvls, length(input.positional[3]))]))
    attributes = merge(input.attributes, dictionary([:levels => lvls, pairs(c.kwargs)...]))
    return ProcessedLayer(input; plottype = Contour, named, attributes)
end

function contours(; levels = 5, kwargs...)
    transformation(ContoursAnalysis(; levels, kwargs = Dict(kwargs)))
end