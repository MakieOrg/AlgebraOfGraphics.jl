function colorbar!(fg::FigureGrid; position=:right,
                   vertical=default_isvertical(position), kwargs...)

    guide_pos = guides_position(fg.figure, position)
    return colorbar!(guide_pos, fg; vertical, kwargs...)
end

"""
    colorbar!(figpos, grid; kwargs...)

Compute colorbar for `grid` (which should be the output of [`draw!`](@ref)) and draw it in
position `figpos`. Attributes allowed in `kwargs` are the same as `MakieLayout.Colorbar`.
"""
function colorbar!(figpos, grid; kwargs...)
    colorbar = compute_colorbar(grid)
    return isnothing(colorbar) ? nothing : Colorbar(figpos; colorbar..., kwargs...)
end

compute_colorbar(fg::FigureGrid) = compute_colorbar(fg.grid)
function compute_colorbar(grid::Matrix{AxisEntries})
    colorscales = filter(!isnothing, [get(ae.continuousscales, :color, nothing) for ae in grid])
    isempty(colorscales) && return
    colorscale = reduce(mergescales, colorscales)
    label = something(colorscale.label, "")
    limits = colorscale.extrema
    colormap = current_default_theme().colormap[]
    # FIXME: handle separate colorbars
    for entry in entries(grid)
        colormap = to_value(get(entry, :colormap, colormap))
    end
    return (; label, limits, colormap)
end
