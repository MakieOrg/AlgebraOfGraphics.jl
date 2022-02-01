get_layout(gl::GridLayout) = gl
get_layout(f::Union{Figure, GridPosition}) = f.layout
get_layout(l::Union{MakieLayout.Layoutable, GridSubposition}) = get_layout(l.parent)

# Wrap layout updates in an update block to avoid triggering multiple updates
function update(f, fig)
    layout = get_layout(fig)
    block_updates = layout.block_updates
    layout.block_updates = true
    output = f(fig)
    layout.block_updates = block_updates
    block_updates || update!(layout)
    return output
end

function Makie.plot!(fig, s::OneOrMoreLayers;
                     axis=NamedTuple(), palettes=NamedTuple())
    if (fig isa Union{Axis, Axis3}) && !isempty(axis)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $axis.")
    end
    grid = update(f -> compute_axes_grid(f, s; axis, palettes), fig)
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
    return update(Figure(; figure...)) do f
        grid = plot!(f, s; axis, palettes)
        fg = FigureGrid(f, grid)
        facet!(fg; facet)
        colorbar!(fg; colorbar...)
        legend!(fg; legend...)
        resize_to_layout!(fg)
        return fg
    end
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
    return update(fig) do f
        ag = plot!(f, s; axis, palettes)
        facet!(f, ag; facet)
        return ag
    end
end
