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
                     axis=NamedTuple(), scales = Dictionary{Symbol,Any}())
    if isa(fig, Union{Axis, Axis3}) && !isempty(axis)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $axis.")
    end
    grid = update(f -> compute_axes_grid(f, d; axis, scales), fig)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(d::AbstractDrawable;
                    axis=NamedTuple(), figure=NamedTuple(), scales = Dictionary{Symbol,Any}())
    fig = Figure(; figure...)
    grid = plot!(fig, d; axis, scales)
    return FigureGrid(fig, grid)
end

function _kwdict(prs)::Dictionary{Symbol,Any}
    isempty(prs) ? Dictionary{Symbol,Any}() : dictionary(pairs(prs))
end

"""
    draw(d; axis=NamedTuple(), figure=NamedTuple, scales=NamedTuple())

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
The output can be customized by giving axis attributes to `axis`, figure attributes
to `figure`, or custom scale properties to `scales`.
Legend and colorbar are drawn automatically. For finer control, use [`draw!`](@ref),
[`legend!`](@ref), and [`colorbar!`](@ref) independently.
"""
function draw(d::AbstractDrawable;
              axis=NamedTuple(), figure=NamedTuple(), scales = NamedTuple(),
              facet=NamedTuple(), legend=NamedTuple(), colorbar=NamedTuple(), palette=nothing)
    check_palette_kw(palette)
    axis = _kwdict(axis)
    figure = _kwdict(figure)
    scales = _kwdict(scales)
    for (key, value) in pairs(scales)
        scales[key] = _kwdict(value)
    end
    facet = _kwdict(facet)
    legend = _kwdict(legend)
    colorbar = _kwdict(colorbar)

    return _draw(d; axis, figure, scales, facet, legend, colorbar)
end

function _draw(d::AbstractDrawable;
              axis, figure, scales,
              facet, legend, colorbar)

    return update(Figure(; pairs(figure)...)) do f
        grid = plot!(f, d; axis, scales)
        fg = FigureGrid(f, grid)
        facet!(fg; facet)
        colorbar!(fg; pairs(colorbar)...)
        legend!(fg; pairs(legend)...)
        resize_to_layout!(fg)
        return fg
    end
end

# this can be used as a trailing argument to |>
function draw(; kwargs...)
    drawable -> draw(drawable; kwargs...)
end

"""
    draw!(fig, d::AbstractDrawable; axis=NamedTuple(), scales = [])

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d` on `fig`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
`fig` can be a figure, a position in a layout, or an axis if `d` has no facet specification.
The output can be customized by giving axis attributes to `axis` or custom scale properties
to `scales`.
"""
function draw!(fig, d::AbstractDrawable;
               axis=NamedTuple(), scales = Dictionary{Symbol,Any}(), facet=NamedTuple(), palette=nothing)
    check_palette_kw(palette)
    axis = _kwdict(axis)
    facet = _kwdict(facet)
    scales = _kwdict(scales)
    for (key, value) in pairs(scales)
        scales[key] = _kwdict(value)
    end
    _draw!(fig, d; axis, facet, scales)
end

function _draw!(fig, d; axis, scales, facet)
    return update(fig) do f
        ag = plot!(f, d; axis, scales)
        facet!(f, ag; facet)
        return ag
    end
end

struct PaletteError <: Exception
    palette
end

check_palette_kw(_::Nothing) = return
check_palette_kw(palette) = throw(PaletteError(palette))

function Base.showerror(io::IO, pe::PaletteError)
    msg = """
        The `palette` keyword for `draw` and `draw!` has been removed in AlgebraOfGraphics v0.7. Categorical palettes should now be passed via the `scales` keyword, and they don't apply per plot keyword, but per scale. Different keywords from different plot objects can share the same scale.

        For example, where before you'd have passed `palette = (; color = [:red, :green, :blue])` you would now pass `scales = (; Color = (; palette = [:red, :green, :blue]))`. In many cases, the scale name will be a camel-case variant of the keyword, for example `color => Color` or `markersize => MarkerSize` but this depends. To check which aesthetics a plot type, for example `Scatter`, supports, call `AlgebraOfGraphics.aesthetic_mapping(Scatter)`. The key passed to `scales` is the aesthetic type without the `Aes` so `AesColor` has the key `Color`, etc.

        The palette passed was `$(pe.palette)`
        """
    print(io, msg)
end