Base.@kwdef struct ContoursAnalysis
    levels::Union{Int, Vector{Float64}}
    kwargs::Dict{Symbol, Any}
end

function (c::ContoursAnalysis)(input::ProcessedLayer)
    z_limits = AlgebraOfGraphics.nested_extrema_finite(input.positional[3])
    _levels(limits, levels::Int) = range(limits..., length = levels)
    lvls = _levels(z_limits, c.levels)
    named = merge(input.named, dictionary([:color => fill(lvls, length(input.positional[3]))]))
    attributes = merge(input.attributes, dictionary([:levels => lvls, pairs(c.kwargs)...]))
    return ProcessedLayer(input; plottype = Contour, named, attributes)
end

"""
    contours(; levels=5, kwargs...)

Create contour lines over the grid spanned over x and y by args 1 and 2 in the `mapping`,
with height values z passed via arg 3. 

You can pass the number of levels as an integer or a vector of levels.
The levels are calculated across the whole z data if they are specified as an integer.

Note that `visual(Contour)` only works in a limited way with AlgebraOfGraphics since version 0.7,
because the internal calculations it does are not compatible with the scale system. With
`visual(Contour)`, you can only have categorically-colored contours (for example to
visualize contours of multiple categories). Alternatively, if you set the `colormap` attribute, you can get
continuously-colored contours but the levels will not be known to AlgebraOfGraphics,
so they won't be synchronized across facets and there will not be a colorbar.

All other keyword arguments are forwarded as attributes to the underlying `Contour` plot.
"""
function contours(; levels = 5, kwargs...)
    return transformation(ContoursAnalysis(; levels, kwargs = Dict(kwargs)))
end
