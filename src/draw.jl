function Makie.plot!(fig, s::OneOrMoreLayers;
                     axis=NamedTuple(), palettes=NamedTuple())
    grid = compute_axes_grid(fig, s; axis, palettes)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(s::OneOrMoreLayers;
                    axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, s; axis, palettes)
    return FigureGrid(fig, grid)
end

"""
    draw(s; axis=NamedTuple(), figure=NamedTuple, palettes=NamedTuple())

Draw a [`AlgebraOfGraphics.Layer`](@ref) or [`AlgebraOfGraphics.Layers`](@ref) object `s`.
The output can be customized by giving axis attributes to `axis`, figure attributes
to `figure`, or custom palettes to `palettes`.
Legend and colorbar are drawn automatically. For finer control, use [`draw!`](@ref),
[`legend!`](@ref), and [`colorbar!`](@ref) independently.
"""
function draw(s::OneOrMoreLayers;
              axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple(),
              facet=NamedTuple(), legend=NamedTuple(), colorbar=NamedTuple())
    fg = plot(s; axis, figure, palettes)
    facet!(fg; facet)
    colorbar!(fg; colorbar...)
    legend!(fg; legend...)
    resizetocontent!(fg)
    return fg
end

"""
    draw!(fig, s; axis=NamedTuple(), palettes=NamedTuple())

Draw a [`AlgebraOfGraphics.Layer`](@ref) or [`AlgebraOfGraphics.Layers`](@ref) object `s` on `fig`.
`fig` can be a figure, a position in a layout, or an axis if `s` has no facet specification.
The output can be customized by giving axis attributes to `axis` or custom palettes
to `palettes`.  
"""
function draw!(fig, s::OneOrMoreLayers;
               axis=NamedTuple(), palettes=NamedTuple(), facet=NamedTuple())
    ag = plot!(fig, s; axis, palettes)
    facet!(fig, ag; facet)
    return ag
end
