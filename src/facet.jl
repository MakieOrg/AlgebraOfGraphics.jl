# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries})
    scale = get(aes[1].scales, :layout, nothing)
    isnothing(scale) && return
    linkaxes!(aes...)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    panel_labels!(fig, aes, scale)
    
    return
end

# TODO: add configuration options here (esp. to determine when / how to link)
function facet_grid!(fig, aes::AbstractMatrix{AxisEntries})
    M, N = size(aes)
    row_scale, col_scale = map(sym -> get(aes[1].scales, sym, nothing), (:row, :col))
    all(isnothing, (row_scale, col_scale)) && return

    # Link axes and hide decorations if appropriate
    hideinnerdecorations!(aes)
    linkaxes!(aes...)

    # span axis labels if appropriate
    nonempty_aes = get_nonempty_aes(aes)
    is2d = isaxis2d(first(nonempty_aes))
    
    if !isnothing(row_scale) && consistent_ylabels(aes)
        is2d && span_ylabel!(fig, aes)
        row_labels!(fig, aes, row_scale)
    end
    if !isnothing(col_scale) && consistent_xlabels(aes)
        is2d && span_xlabel!(fig, aes)
        col_labels!(fig, aes, col_scale)
    end
    return
end

# facet labels

function col_labels!(fig, aes, scale)
    zipped_scale = zip(plotvalues(scale), datavalues(scale))

    titlegap, attributes = facetlabelattributes(first_nonempty_axis(aes))

    facetlabelpadding = lift(titlegap) do gap
        return (0f0, 0f0, gap, 0f0)
    end

    for (index, label) in zipped_scale
        Label(fig[1, index, Top()], string(label);
        padding=facetlabelpadding, attributes...)
    end
end

function row_labels!(fig, aes, scale)
    _, N = size(aes)
    zipped_scale = zip(plotvalues(scale), datavalues(scale))

    titlegap, attributes = facetlabelattributes(first_nonempty_axis(aes))

    facetlabelpadding = lift(titlegap) do gap
        return (gap, 0f0, 0f0, 0f0)
    end

    for (index, label) in zipped_scale
        Label(fig[index, N, Right()], string(label);
            rotation=-π/2, padding=facetlabelpadding,
            attributes...)
    end
end

function panel_labels!(fig, aes, scale)
    zipped_scale = zip(plotvalues(scale), datavalues(scale))

    titlegap, attributes = facetlabelattributes(first_nonempty_axis(aes))

    facetlabelpadding = lift(titlegap) do gap
        return (0f0, 0f0, gap, 0f0)
    end

    for (index, label) in zipped_scale        
        Label(fig[index..., Top()], string(label);
            padding=facetlabelpadding, attributes...)
    end
end

function facetlabelattributes(ax)
    titlegap = ax.titlegap

    attributes = (
        color=ax.titlecolor,
        font=ax.titlefont,
        textsize=ax.titlesize,
    )

	(; titlegap, attributes)
end

# consistent axis labels

function consistent_xlabels(aes)
    nonempty_aes = get_nonempty_aes(aes)
    ax = first(nonempty_aes).axis
    return all(ae -> ae.axis.xlabel[] == ax.xlabel[], nonempty_aes)
end

function consistent_ylabels(aes)
    nonempty_aes = get_nonempty_aes(aes)
    ax = first(nonempty_aes).axis
    return all(ae -> ae.axis.ylabel[] == ax.ylabel[], nonempty_aes)
end

# spanned axis labels

function span_xlabel!(fig, aes)
    M, N = size(aes)
    
    for ae in aes
        ae.axis.xlabelvisible[] = false
    end
    protrusion = lift(
        (xs...) -> maximum(x -> x.bottom, xs),
        (MakieLayout.protrusionsobservable(ae.axis) for ae in aes[M, :])...
    )

    ax = first_nonempty_axis(aes)
    
    xlabelpadding = lift(protrusion, ax.xlabelpadding) do val, p
        return (0f0, 0f0, 0f0, val + p)
    end
    xlabelcolor = ax.xlabelcolor
    xlabelfont = ax.xlabelfont
    xlabelsize = ax.xlabelsize
    xlabelattributes = (
        color=xlabelcolor,
        font=xlabelfont,
        textsize=xlabelsize,
    )
    Label(fig[M, :, Bottom()], ax.xlabel;
        padding=xlabelpadding, xlabelattributes...)
end

function span_ylabel!(fig, aes)
    M, N = size(aes)
    
    for ae in aes
        ae.axis.ylabelvisible[] = false
    end
    
    protrusion = lift(
        (xs...) -> maximum(x -> x.left, xs),
        (MakieLayout.protrusionsobservable(ae.axis) for ae in aes[:, 1])...
    )
    # TODO: here and below, set in such a way that one can change padding after the fact?
    ax = first_nonempty_axis(aes)
    
    ylabelpadding = lift(protrusion, ax.ylabelpadding) do val, p
        return (0f0, val + p, 0f0, 0f0)
    end
    
    ylabelcolor = ax.ylabelcolor
    ylabelfont = ax.ylabelfont
    ylabelsize = ax.ylabelsize
    ylabelattributes = (
        color=ylabelcolor,
        font=ylabelfont,
        textsize=ylabelsize,
    )
    Label(fig[:, 1, Left()], ax.ylabel;
        rotation=π/2, padding=ylabelpadding, ylabelattributes...)
end

empty_ae(ae) = isempty(ae.entries)
get_nonempty_aes(aes) = filter(!empty_ae, aes)
first_nonempty_axis(aes) = first(get_nonempty_aes(aes)).axis

function facet!(fig, aes::AbstractMatrix{AxisEntries})
    facet_wrap!(fig, aes)
    facet_grid!(fig, aes)
    return
end

function facet!(fg::FigureGrid)
    facet!(fg.figure, fg.grid)
    return fg
end

## Layout helpers

isaxis2d(::Axis) = true
isaxis2d(::Any) = false
isaxis2d(ae::AxisEntries) = isaxis2d(ae.axis)

for sym in [:hidexdecorations!, :hideydecorations!, :hidedecorations!]
    @eval function $sym(ae::AxisEntries; kwargs...)
        axis = ae.axis
        isaxis2d(axis) && $sym(axis; kwargs...)
    end
end

for sym in [:linkxaxes!, :linkyaxes!, :linkaxes!]
    @eval function $sym(ae::AxisEntries, aes::AxisEntries...)
        axs = filter(isaxis2d, map(ae->ae.axis, (ae, aes...)))
        isempty(axs) || $sym(axs...)
    end
end

function hideinnerdecorations!(aes::Matrix{AxisEntries})
    options = (label=true, ticks=true, minorticks=true, grid=false, minorgrid=false)
    foreach(ae -> hidexdecorations!(ae; options...), aes[1:end-1, :])
    foreach(ae -> hideydecorations!(ae; options...), aes[:, 2:end])
end

function deleteemptyaxes!(aes::Matrix{AxisEntries})
    for ae in aes
        if isempty(ae.entries)
            delete!(ae.axis)
        end
    end
end

function resizetocontent!(fig::Figure)
    figsize = size(fig.scene)
    sz = map((Col(), Row()), figsize) do dir, currentsize
        inferredsize = determinedirsize(fig.layout, dir)
        return ceil(Int, something(inferredsize, currentsize))
    end
    sz == figsize || resize!(fig.scene, sz)
    return fig
end

function resizetocontent!(fg::FigureGrid)
    resizetocontent!(fg.figure)
    return fg
end
