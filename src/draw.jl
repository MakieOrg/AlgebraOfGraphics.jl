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

function Makie.plot!(fig, d::AbstractDrawable, scales::Scales = scales(); axis = NamedTuple())
    if isa(fig, Union{Axis, Axis3}) && !isempty(axis)
        @warn("Axis got passed, but also axis attributes. Ignoring axis attributes $axis.")
    end
    grid = update(f -> compute_axes_grid(f, d, scales; axis), fig)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(
        d::AbstractDrawable, scales::Scales = scales();
        axis = NamedTuple(), figure = NamedTuple()
    )
    fig = Figure(; figure...)
    grid = plot!(fig, d, scales; axis)
    return FigureGrid(fig, grid)
end

function _kwdict(prs, keyword::Symbol)::Dictionary{Symbol, Any}
    err = nothing
    dict = try
        _dict::Dictionary{Symbol, Any} = dictionary(pairs(prs))
    catch _err
        err = _err
    end
    if err !== nothing
        io = IOBuffer()
        Base.showerror(io, err)
        errmsg = String(take!(io))
        throw(ArgumentError("Can't convert value passed via the keyword `$keyword` to a `Dictionary{Symbol,Any}`. If you intended to pass a single-element `NamedTuple`, check that you didn't write `$keyword = (key = value)` as this expression resolves to just `value`. Use either `$keyword = (; key = value)` or `$keyword = (key = value,)`. The invalid value that was passed was:\n\n$(repr(prs))\n\nThe underlying error message was:\n\n$errmsg"))
    end
    return dict
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

## Facet options

AlgebraOfGraphics accepts the following keywords under the `facet` keyword:

- `linkxaxes`: Control x-axis linking. Valid values are `automatic`, `:all`, `:colwise`, `:minimal`, `:none`, `true`, or `false`.
- `linkyaxes`: Control y-axis linking. Valid values are `automatic`, `:all`, `:rowwise`, `:minimal`, `:none`, `true`, or `false`.
- `hidexdecorations`: Whether to hide x-axis decorations on inner panels. Valid values are `automatic`, `true`, or `false`.
- `hideydecorations`: Whether to hide y-axis decorations on inner panels. Valid values are `automatic`, `true`, or `false`.
- `singlexlabel`: Whether to show a single spanning x-axis label instead of labels on each panel. Valid values are `automatic`, `true`, or `false`. Default is `automatic`, which compacts labels when they are consistent across panels.
- `singleylabel`: Whether to show a single spanning y-axis label instead of labels on each panel. Valid values are `automatic`, `true`, or `false`. Default is `automatic`, which compacts labels when they are consistent across panels.
"""
function draw(
        d::AbstractDrawable, scales::Scales = scales();
        axis = NamedTuple(), figure = NamedTuple(),
        facet = NamedTuple(), legend = NamedTuple(), colorbar = NamedTuple(), palette = nothing
    )
    check_palette_kw(palette)
    axis = _kwdict(axis, :axis)
    figure = _kwdict(figure, :figure)
    facet = _kwdict(facet, :facet)
    legend = _kwdict(legend, :legend)
    colorbar = _kwdict(colorbar, :colorbar)

    return _draw(d, scales; axis, figure, facet, legend, colorbar)
end

_remove_show_kw(pairs) = filter(((key, value),) -> key !== :show, pairs)

struct FigureSettings
    title
    subtitle
    titlesize::Union{Nothing, Float64}
    subtitlesize::Union{Nothing, Float64}
    titlealign::Union{Nothing, Symbol}
    titlecolor
    subtitlecolor
    titlefont
    subtitlefont
    titlelineheight
    subtitlelineheight
    footnotes::Union{Nothing, Vector{Any}}
    footnotesize::Union{Nothing, Float64}
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

function _draw(
        d::AbstractDrawable, scales::Scales;
        axis, figure, facet, legend, colorbar
    )

    ae = compute_axes_grid(d, scales; axis)
    return _draw(ae; figure, facet, legend, colorbar)
end

function _draw(ae::Matrix{AxisSpecEntries}; axis = Dictionary{Symbol, Any}(), figure = Dictionary{Symbol, Any}(), facet = Dictionary{Symbol, Any}(), legend = Dictionary{Symbol, Any}(), colorbar = Dictionary{Symbol, Any}())

    if !isempty(axis)
        # merge in axis attributes here because pagination runs `compute_axes_grid`
        # which in the normal `draw` pipeline consumes `axis`
        ae = map(ae) do ase
            Accessors.@set ase.axis.attributes = merge(ase.axis.attributes, axis)
        end
    end

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

        halign = fs.titlealign === nothing ? :left : fs.titlealign
        justification = halign

        if fs.subtitle !== nothing
            Label(fg.figure[begin - 1, :], fs.subtitle; tellwidth = false, halign, justification, _filter_nothings(; font = fs.subtitlefont, color = fs.subtitlecolor, fontsize = fs.subtitlesize, lineheight = fs.subtitlelineheight)...)
        end
        if fs.title !== nothing
            Label(fg.figure[begin - 1, :], fs.title; tellwidth = false, fontsize = base_fontsize * 1.15, font = :bold, halign, justification, _filter_nothings(; font = fs.titlefont, color = fs.titlecolor, fontsize = fs.titlesize, lineheight = fs.titlelineheight)...)
        end
        if fs.subtitle !== nothing
            fg.figure.layout.addedrowgaps[1] = Fixed(0)
        end
        if fs.footnotes !== nothing
            fgl = GridLayout(fg.figure[end + 1, :]; halign = :left, _filter_nothings(; halign = fs.footnotealign)...)
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
    return drawable -> draw(drawable, scales; kwargs...)
end

"""
    draw!(fig, d::AbstractDrawable, scales::Scales = scales(); [axis, facet])

Draw a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d` on `fig`.
In practice, `d` will often be a [`AlgebraOfGraphics.Layer`](@ref) or
[`AlgebraOfGraphics.Layers`](@ref).
`fig` can be a figure, a position in a layout, or an axis if `d` has no facet specification.
The output can be customized by passing named tuples or dictionaries with settings via the `axis` or `facet` keywords.
"""
function draw!(
        fig, d::AbstractDrawable, scales::Scales = scales();
        axis = NamedTuple(), facet = NamedTuple(), palette = nothing
    )
    check_palette_kw(palette)
    axis = _kwdict(axis, :axis)
    facet = _kwdict(facet, :facet)
    return _draw!(fig, d, scales; axis, facet)
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
    return print(io, msg)
end

"""
    draw_to_spec(d, scales = scales(); [axis, facet])

!!! warning
    This function is considered experimental.
    It can have breaking changes or be removed at any time.

Create a Makie SpecApi specification from a [`AlgebraOfGraphics.AbstractDrawable`](@ref) object `d`.
Scale options can be passed as an optional second argument.
The output can be customized by passing named tuples or dictionaries with settings via the `axis` or `facet` keywords.

Unlike [`draw`](@ref), this function does not create or mutate a figure. Instead, it returns a
`Makie.SpecApi.GridLayout` specification that can be used for reactive
plotting with observables. This allows for creating plots that can be efficiently updated
when the underlying data changes.

The returned specification includes axis configurations, plot specifications, facet layouts,
legends, and colorbars as appropriate. It can be plotted using `Makie.plot(spec)` or used
in more complex reactive plotting scenarios.

## Example

```julia
using AlgebraOfGraphics, GLMakie

function random_frame()
    (
        x = randn(100),
        y = randn(100),
        color = randn(100),
        marker = rand(rand('A':'Z', 3), 100),
        layout = rand(rand(names(Base), 9), 100),
    )
end

df = Observable(random_frame())
specobs = lift(df) do df
    layer = data(df) * mapping(:x, :y, color = :color, marker = :marker, layout = :layout) *
        visual(Scatter)
    AlgebraOfGraphics.draw_to_spec(layer, scales(Color = (; colormap = rand(RGBf, 3))))
end
f = Figure()
plot(f[1, 1], specobs)
f

# later, the data observable can be updated

df[] = random_frame()
```

See also [`draw`](@ref), [`draw!`](@ref).
"""
function draw_to_spec(spec, scales = scales(); facet = (;), axis = (;))
    agrid = compute_axes_grid(spec, scales; axis)

    S = Makie.SpecApi

    axisspecs = map(agrid) do ase
        ax = ase.axis
        axtype = ax.type === Axis ? S.Axis : ax.type === Axis3 ? S.Axis3 : error()

        isempty(ase.entries) && return nothing

        plots::Vector{Makie.PlotSpec} = map(ase.entries) do entry
            Makie.PlotSpec(entry.plottype, entry.positional...; pairs(entry.named)...)
        end

        ax.position => axtype(; plots, pairs(ax.attributes)...)
    end

    axisspecs_vec = [x for x in vec(axisspecs) if x !== nothing]

    specs = Pair[]

    append!(specs, axisspecs_vec)

    gridattrs = facet_grid!(specs, axisspecs, first(agrid).categoricalscales; facet)
    wrapattrs = facet_wrap!(specs, axisspecs, first(agrid).categoricalscales; facet)

    gridsize = size(agrid)

    legend = compute_legend(agrid; order = nothing)
    if legend !== nothing
        legendpos = (:, gridsize[2] + 1)
        legendspec = S.Legend(legend...)
        push!(specs, legendpos => legendspec)
    end

    colorbars = compute_colorbars(agrid)
    if !isempty(colorbars)
        push!(
            specs, (:, gridsize[2] + 1 + (legend !== nothing)) => S.GridLayout(
                [
                    S.Colorbar(; colorbar...) for colorbar in colorbars
                ]
            )
        )
    end

    xaxislinks = Vector{Makie.BlockSpec}[]
    yaxislinks = Vector{Makie.BlockSpec}[]

    gridattrs !== nothing && link_axes!(xaxislinks, yaxislinks, axisspecs; gridattrs.linkxaxes, gridattrs.linkyaxes)
    wrapattrs !== nothing && link_axes!(xaxislinks, yaxislinks, axisspecs; wrapattrs.linkxaxes, wrapattrs.linkyaxes)

    return S.GridLayout(
        specs;
        xaxislinks,
        yaxislinks,
    )
end

function link_axes!(xaxislinks::Vector{Vector{Makie.BlockSpec}}, yaxislinks::Vector{Vector{Makie.BlockSpec}}, axisspecs::Matrix; linkxaxes, linkyaxes)
    _link!(v, axes) = push!(v, [a[2] for a in axes if a !== nothing])

    linkxaxes == :all && _link!(xaxislinks, axisspecs)
    linkxaxes == :colwise && foreach(col -> _link!(xaxislinks, col), eachcol(axisspecs))

    linkyaxes == :all && _link!(yaxislinks, axisspecs)
    linkyaxes == :rowwise && foreach(row -> _link!(yaxislinks, row), eachrow(axisspecs))

    return
end

function facet_wrap!(specs::Vector{<:Pair}, aes::AbstractMatrix, categoricalscales; facet)

    scale = extract_single(AesLayout, categoricalscales)
    isnothing(scale) && return

    # # Link axes and hide decorations if appropriate
    attrs = clean_facet_attributes(aes; pairs(facet)...)
    # link_axes!(aes; attrs.linkxaxes, attrs.linkyaxes)
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap = true)

    # # delete empty axes
    # deleteemptyaxes!(aes)

    # add facet labels
    scale.props.legend && panel_labels!(specs, aes, scale)

    # # span axis labels if appropriate
    # is2d = all(isaxis2d, nonemptyaxes(aes))

    # if is2d && consistent_ylabels(aes)
    #     span_ylabel!(fig, aes)
    # end
    # if is2d && consistent_xlabels(aes)
    #     span_xlabel!(fig, aes)
    # end

    return attrs
end

function facet_grid!(specs::Vector{<:Pair}, aes::AbstractMatrix, categoricalscales; facet)
    row_scale = extract_single(AesRow, categoricalscales)
    col_scale = extract_single(AesCol, categoricalscales)
    all(isnothing, (row_scale, col_scale)) && return

    # # link axes and hide decorations if appropriate
    attrs = clean_facet_attributes(aes; pairs(facet)...)
    # link_axes!(aes; attrs.linkxaxes, attrs.linkyaxes)
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap = false)

    # # span axis labels if appropriate
    # is2d = all(isaxis2d, nonemptyaxes(aes))

    # is2d && consistent_ylabels(aes) && span_ylabel!(fig, aes)
    # is2d && consistent_xlabels(aes) && span_xlabel!(fig, aes)

    if !isnothing(row_scale)
        row_scale.props.legend && row_labels!(specs, aes, row_scale)
    end
    if !isnothing(col_scale)
        col_scale.props.legend && col_labels!(specs, aes, col_scale)
    end
    return attrs
end

function facet_labels!(specs::Vector{<:Pair}, aes, scale, dir)
    # reference axis to extract attributes
    ax = first(nonemptyaxes(aes))

    axdefaults = Makie.block_defaults(Axis, Dict(), nothing)

    color = get(() -> axdefaults[:titlecolor], ax.kwargs, :titlecolor)
    font = get(() -> axdefaults[:titlefont], ax.kwargs, :titlefont)
    fontsize = get(() -> axdefaults[:titlesize], ax.kwargs, :titlesize)
    visible = get(() -> axdefaults[:titlevisible], ax.kwargs, :titlevisible)

    padding_index = dir == :row ? 1 : 3
    padding = ntuple(i -> i == padding_index ? axdefaults[:titlegap] : 0.0f0, 4)

    return append!(
        specs, map(plotvalues(scale), datalabels(scale)) do index, label
            rotation = dir == :row ? -π / 2 : 0.0
            figpos = dir == :col ? (1, index, Top()) :
                dir == :row ? (index, size(aes, 2), Right()) : (index..., Top())
            return figpos => Makie.SpecApi.Label(; text = label, rotation, padding, color, font, fontsize, visible)
        end
    )
end

function hideinnerdecorations!(
        aes::AbstractMatrix{<:Union{Nothing, <:Pair}};
        hidexdecorations, hideydecorations, wrap
    )
    I, J = size(aes)

    if hideydecorations
        for i in 1:I, j in 2:J
            aes[i, j] !== nothing && hide_ydecorations!(aes[i, j][2])
        end
    end

    return if hidexdecorations
        for i in 1:(I - 1), j in 1:J
            if wrap && aes[i + 1, j] === nothing
                # In facet_wrap, don't hide x decorations if axis below is empty,
                # but instead improve alignment.
                if aes[i, j] !== nothing
                    aes[i, j][2].alignmode = Mixed(bottom = Protrusion(0))
                end
            else
                aes[i, j] !== nothing && hide_xdecorations!(aes[i, j][2])
            end
        end
    end
end

function hide_xdecorations!(ax::Makie.BlockSpec)
    ax.xlabelvisible = false
    ax.xticklabelsvisible = false
    return ax.xticksvisible = false
end
function hide_ydecorations!(ax::Makie.BlockSpec)
    ax.ylabelvisible = false
    ax.yticklabelsvisible = false
    return ax.yticksvisible = false
end
