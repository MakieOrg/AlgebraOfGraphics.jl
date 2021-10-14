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

function has_zcolor(entry::Entry)
    return entry.plottype <: Union{Heatmap, Contour, Contourf, Surface} &&
        !haskey(entry.primary, :color) &&
        !haskey(entry.named, :color) &&
        !haskey(entry.attributes, :color)
end

function getlabeledcolorrange(grid)
    zcolor = any(has_zcolor, entries(grid))
    key = zcolor ? 3 : :color
    continuous_color_entries = Iterators.filter(entries(grid)) do entry
        return get(entry, key, nothing) isa AbstractArray{<:Number}
    end
    colorrange = compute_extrema(continuous_color_entries, key)
    label = compute_label(continuous_color_entries, key)
    return isnothing(colorrange) ? nothing : (label, colorrange)
end

compute_colorbar(fg::FigureGrid) = compute_colorbar(fg.grid)
function compute_colorbar(grid::Matrix{AxisEntries})
    labeledcolorrange = getlabeledcolorrange(grid)
    isnothing(labeledcolorrange) && return
    label, limits = labeledcolorrange
    colormap = current_default_theme().colormap[]
    for entry in entries(grid)
        colormap = to_value(get(entry.attributes, :colormap, colormap))
    end
    return (; label, limits, colormap)
end
