get_layout(gl::GridLayout) = gl
get_layout(f::Union{Figure, GridPosition}) = f.layout
get_layout(l::Union{Block, GridSubposition}) = get_layout(l.parent)

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

function Makie.plot!(fig, d::AbstractDrawable;
                     axis=NamedTuple(), palettes=NamedTuple())
    if isa(fig, Union{Axis, Axis3}) && !isempty(axis)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $axis.")
    end
    grid = update(f -> compute_axes_grid(f, d; axis, palettes), fig)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(d::AbstractDrawable;
                    axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, d; axis, palettes)
    return FigureGrid(fig, grid)
end

"""
    draw(d; axis=NamedTuple(), figure=NamedTuple, palettes=NamedTuple())

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
The output can be customized by giving axis attributes to `axis`, figure attributes
to `figure`, or custom palettes to `palettes`.
Legend and colorbar are drawn automatically. For finer control, use [`draw!`](@ref),
[`legend!`](@ref), and [`colorbar!`](@ref) independently.
"""
function draw(d::AbstractDrawable;
              axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple(),
              facet=NamedTuple(), legend=NamedTuple(), colorbar=NamedTuple())
    return update(Figure(; figure...)) do f
        grid = plot!(f, d; axis, palettes)
        fg = FigureGrid(f, grid)
        facet!(fg; facet)
        colorbar!(fg; colorbar...)
        legend!(fg; legend...)
        resize_to_layout!(fg)
        return fg
    end
end

"""
    draw!(fig, d::AbstractDrawable; axis=NamedTuple(), palettes=NamedTuple())

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d` on `fig`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
`fig` can be a figure, a position in a layout, or an axis if `d` has no facet specification.
The output can be customized by giving axis attributes to `axis` or custom palettes
to `palettes`.
"""
function draw!(fig, d::AbstractDrawable;
               axis=NamedTuple(), palettes=NamedTuple(), facet=NamedTuple())
    return update(fig) do f
        ag = plot!(f, d; axis, palettes)
        facet!(f, ag; facet)
        return ag
    end
end
