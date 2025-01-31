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

function Makie.plot!(fig, d::AbstractDrawable, scales::Scales = scales(); axis=NamedTuple())
    if isa(fig, Union{Axis, Axis3}) && !isempty(axis)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $axis.")
    end
    grid = update(f -> compute_axes_grid(f, d, scales; axis), fig)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(d::AbstractDrawable, scales::Scales = scales();
                    axis=NamedTuple(), figure=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, d, scales; axis)
    return FigureGrid(fig, grid)
end

function _kwdict(prs)::Dictionary{Symbol,Any}
    isempty(prs) ? Dictionary{Symbol,Any}() : dictionary(pairs(prs))
end

"""
    draw(d, scales::Scales = scales(); [axis, figure, facet, legend, colorbar])

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
Scale options can be passed as an optional second argument.
The output can be customized by passing named tuples or dictionaries with settings via the `axis`, `figure`, `facet`, `legend` or `colorbar` keywords.
Legend and colorbar are drawn automatically unless `show = false` is passed to the keyword
arguments of either `legend` or `colorbar`.

For finer control, use [`draw!`](@ref),
[`legend!`](@ref), and [`colorbar!`](@ref) independently.

## Figure options

AlgebraOfGraphics accepts the following special keywords under the `figure` keyword,
the remaining attributes are forwarded to Makie's `Figure` constructor.
The `title`, `subtitle` and `footnotes` arguments accept objects of any kind that Makie's
`Label` or `text` function can handle, such as `rich` text.

    - `title`
    - `subtitle`
    - `titlesize::Union{Nothing,Float64}`
    - `subtitlesize::Union{Nothing,Float64}`
    - `titlealign::Union{Nothing,Symbol}`
    - `titlecolor`
    - `subtitlecolor`
    - `titlefont`
    - `subtitlefont`
    - `titlelineheight`
    - `subtitlelineheight`
    - `footnotes::Union{Nothing,Vector{Any}}`
    - `footnotesize::Union{Nothing,Float64}`
    - `footnotefont`
    - `footnotecolor`
    - `footnotealign`
    - `footnotelineheight`
"""
function draw(d::AbstractDrawable, scales::Scales = scales();
              axis=NamedTuple(), figure=NamedTuple(),
              facet=NamedTuple(), legend=NamedTuple(), colorbar=NamedTuple(), palette=nothing)
    check_palette_kw(palette)
    axis = _kwdict(axis)
    figure = _kwdict(figure)
    facet = _kwdict(facet)
    legend = _kwdict(legend)
    colorbar = _kwdict(colorbar)

    return _draw(d, scales; axis, figure, facet, legend, colorbar)
end

_remove_show_kw(pairs) = filter(((key, value),) -> key !== :show, pairs)

struct FigureSettings
    title
    subtitle
    titlesize::Union{Nothing,Float64}
    subtitlesize::Union{Nothing,Float64}
    titlealign::Union{Nothing,Symbol}
    titlecolor
    subtitlecolor
    titlefont
    subtitlefont
    titlelineheight
    subtitlelineheight
    footnotes::Union{Nothing,Vector{Any}}
    footnotesize::Union{Nothing,Float64}
    footnotefont
    footnotecolor
    footnotealign
    footnotelineheight
end

function figure_settings(;
        title = nothing,
        subtitle = nothing,
        titlefont = nothing,
        subtitlefont = nothing,
        titlecolor = nothing,
        subtitlecolor = nothing,
        titlesize = nothing,
        subtitlesize = nothing,
        titlealign = nothing,
        titlelineheight = nothing,
        subtitlelineheight = nothing,
        footnotes = nothing,
        footnotesize = nothing,
        footnotefont = nothing,
        footnotecolor = nothing,
        footnotealign = nothing,
        footnotelineheight = nothing,
        kwargs...,
    )

    f = FigureSettings(
        title,
        subtitle,
        titlesize,
        subtitlesize,
        titlealign,
        titlecolor,
        subtitlecolor,
        titlefont,
        subtitlefont,
        titlelineheight,
        subtitlelineheight,
        footnotes,
        footnotesize,
        footnotefont,
        footnotecolor,
        footnotealign,
        footnotelineheight,
    )

    return f, kwargs
end

function _draw(d::AbstractDrawable, scales::Scales;
              axis, figure, facet, legend, colorbar)

    ae = compute_axes_grid(d, scales; axis)
    _draw(ae; figure, facet, legend, colorbar)
end
function _draw(ae::Matrix{AxisSpecEntries}; figure = (;), facet = (;), legend = (;), colorbar = (;))

    fs, remaining_figure_kw = figure_settings(; pairs(figure)...)

    _filter_nothings(; kwargs...) = (key => value for (key, value) in kwargs if value !== nothing)

    return update(Figure(; pairs(remaining_figure_kw)...)) do f
        grid = map(x -> AxisEntries(x, f), ae)
        foreach(plot!, grid)

        fg = FigureGrid(f, grid)
        facet!(fg; facet)
        if get(colorbar, :show, true)
            colorbar!(fg; _remove_show_kw(pairs(colorbar))...)
        end
        if get(legend, :show, true)
            legend!(fg; _remove_show_kw(pairs(legend))...)
        end

        base_fontsize = Makie.theme(fg.figure.scene)[:fontsize][]

        if fs.subtitle !== nothing
            Label(fg.figure[begin-1, :], fs.subtitle; tellwidth = false, halign = :left, _filter_nothings(; font = fs.subtitlefont, color = fs.subtitlecolor, fontsize = fs.subtitlesize, halign = fs.titlealign, lineheight = fs.subtitlelineheight)...)
        end
        if fs.title !== nothing
            Label(fg.figure[begin-1, :], fs.title; tellwidth = false, fontsize = base_fontsize * 1.15, font = :bold, halign = :left, _filter_nothings(; font = fs.titlefont, color = fs.titlecolor, fontsize = fs.titlesize, halign = fs.titlealign, lineheight = fs.titlelineheight)...)
        end
        if fs.subtitle !== nothing
            fg.figure.layout.addedrowgaps[1] = Fixed(0)
        end
        if fs.footnotes !== nothing
            fgl = GridLayout(fg.figure[end+1, :]; halign = :left, _filter_nothings(; halign = fs.footnotealign)...)
            for (i, note) in enumerate(fs.footnotes)
                Label(fgl[i, 1], note; tellwidth = false, halign = :left, fontsize = base_fontsize / 1.15, _filter_nothings(; halign = fs.footnotealign, font = fs.footnotefont, color = fs.footnotecolor, fontsize = fs.footnotesize, lineheight = fs.footnotelineheight)...)
            end
            fgl.addedrowgaps .= Ref(Fixed(0))
        end
        resize_to_layout!(fg)
        return fg
    end
end

# this can be used as a trailing argument to |>
function draw(scales::Scales = scales(); kwargs...)
    drawable -> draw(drawable, scales; kwargs...)
end

"""
    draw!(fig, d::AbstractDrawable, scales::Scales = scales(); [axis, facet])

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d` on `fig`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
`fig` can be a figure, a position in a layout, or an axis if `d` has no facet specification.
The output can be customized by passing named tuples or dictionaries with settings via the `axis` or `facet` keywords.
"""
function draw!(fig, d::AbstractDrawable, scales::Scales = scales();
               axis=NamedTuple(), facet=NamedTuple(), palette=nothing)
    check_palette_kw(palette)
    axis = _kwdict(axis)
    facet = _kwdict(facet)
    _draw!(fig, d, scales; axis, facet)
end

function _draw!(fig, d, scales; axis, facet)
    return update(fig) do f
        ag = plot!(f, d, scales; axis)
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
        The `palette` keyword for `draw` and `draw!` has been removed in AlgebraOfGraphics v0.7. Categorical palettes should now be passed as a scale setting using the `scales` function, and they don't apply per plot keyword, but per scale. Different keywords from different plot objects can share the same scale.

        For example, where before you did `draw(spec; palette = (; color = [:red, :green, :blue])` you would now do `draw(spec, scales(Color = (; palette = [:red, :green, :blue]))`. In many cases, the scale name will be a camel-case variant of the keyword, for example `color => Color` or `markersize => MarkerSize` but this depends. To check which aesthetics a plot type, for example `Scatter`, supports, call `AlgebraOfGraphics.aesthetic_mapping(Scatter)`. The key passed to `scales` is the aesthetic type without the `Aes` so `AesColor` has the key `Color`, etc.

        The palette passed was `$(pe.palette)`
        """
    print(io, msg)
end