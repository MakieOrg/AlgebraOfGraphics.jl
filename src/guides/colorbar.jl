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
    colorscales = filter(!isnothing, [get(ae.continuousscales, AesColor, nothing) for ae in grid])
    isempty(colorscales) && return

    # colorscale = reduce(mergescales, colorscales)
    colorscale_dict = reduce(colorscales, init=Dictionary{Union{Nothing,Symbol},ContinuousScale}()) do c1, c2
        mergewith!(mergescales, c1, c2)
    end

    if length(colorscale_dict) > 1
        error("Cannot yet handle multiple colorscales, found $colorscale_dict")
    end

    colorscale = only(values(colorscale_dict))
    
    label = getlabel(colorscale)
    limits = @something colorscale.props.aesprops.colorrange colorscale.extrema
    is_highclipped = limits[2] < colorscale.extrema[2]
    is_lowclipped = limits[1] > colorscale.extrema[1]

    _, limits = strip_units(colorscale, collect(limits))

    colormap = @something colorscale.props.aesprops.colormap default_colormap()
    colormap_colors = Makie.to_colormap(colormap)

    lowclip = is_lowclipped ? @something(colorscale.props.aesprops.lowclip, colormap_colors[1]) : Makie.automatic
    highclip = is_highclipped ? @something(colorscale.props.aesprops.highclip, colormap_colors[end]) : Makie.automatic

    return (;
        label,
        limits,
        colormap,
        lowclip,
        highclip,
    )
end
