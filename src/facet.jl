# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries}; linkxaxes = true, linkyaxes = true)

    scale = get(aes[1].scales, :layout, nothing)
    isnothing(scale) && return

    # Link axes and hide decorations if appropriate
    linkyaxes && linkyaxes!(aes...)
    linkxaxes && linkxaxes!(aes...)
    hideinnerdecorations!(aes, linkxaxes, linkyaxes)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    panel_labels!(aes)

    # span axis labels if appropriate
    nonempty_aes = get_nonempty_aes(aes)

    if consistent_ylabels(nonempty_aes)
        span_ylabel!(fig, aes)
    end
    if consistent_xlabels(nonempty_aes)
        span_xlabel!(fig, aes)
    end
    
    return
end

function facet_grid!(fig, aes::AbstractMatrix{AxisEntries}; linkxaxes = true, linkyaxes = true)
    M, N = size(aes)
    row_scale, col_scale = map(sym -> get(aes[1].scales, sym, nothing), (:row, :col))
    all(isnothing, (row_scale, col_scale)) && return

    # Link axes and hide decorations if appropriate
    linkyaxes && linkyaxes!(aes...)
    linkxaxes && linkxaxes!(aes...)
    hideinnerdecorations!(aes, linkxaxes, linkyaxes)

    # span axis labels if appropriate
    nonempty_aes = get_nonempty_aes(aes)
    
    if !isnothing(row_scale) && consistent_ylabels(nonempty_aes)
        span_ylabel!(fig, aes)
        row_labels!(fig, aes, row_scale)
    end
    if !isnothing(col_scale) && consistent_xlabels(nonempty_aes)
        span_xlabel!(fig, aes)
        col_labels!(fig, aes, col_scale)
    end
    return
end

# facet labels

function col_labels!(fig, aes, col_scale)
    M, N = size(aes)
    
    ax = first_nonempty_axis(aes)
    titlegap = ax.titlegap
    
    facetlabelattributes = (
        color=ax.titlecolor,
        font=ax.titlefont,
        textsize=ax.titlesize,
    )
    
    col_dict = Dict(zip(plotvalues(col_scale), datavalues(col_scale)))
    labelpadding = lift(titlegap) do gap
        return (0f0, 0f0, gap, 0f0)
    end
    for n in 1:N
        Label(fig[1, n, Top()], string(col_dict[n]);
        padding=labelpadding, facetlabelattributes...)
    end

end

function row_labels!(fig, aes, row_scale)
    M, N = size(aes)

    ax = first_nonempty_axis(aes)
    titlegap = ax.titlegap

    facetlabelattributes = (
        color=ax.titlecolor,
        font=ax.titlefont,
        textsize=ax.titlesize,
    )
    
    row_dict = Dict(zip(plotvalues(row_scale), datavalues(row_scale)))
    facetlabelpadding = lift(titlegap) do gap
        return (gap, 0f0, 0f0, 0f0)
    end
    for m in 1:M
        Label(fig[m, N, Right()], string(row_dict[m]);
            rotation=-π/2, padding=facetlabelpadding,
            facetlabelattributes...)
    end
end

function panel_labels!(aes)
    # Add titles to axis (or delete axis if empty)
    for ae in aes
        ax = ae.axis
        entries = ae.entries
        vs = Iterators.filter(
            !isnothing,
            (get(entry.primary, :layout, nothing) for entry in entries)
        )
        it = iterate(vs)
        if !isnothing(it)
            v, _ = it
            ax.title[] = string(v)
        end
    end
end

# spanned axis labels

function consistent_xlabels(nonempty_aes)
    ax = first(nonempty_aes).axis
    ax isa Axis3 && return false
    return all(ae -> ae.axis.xlabel[] == ax.xlabel[], nonempty_aes)
end

function consistent_ylabels(nonempty_aes)
    ax = first(nonempty_aes).axis
    ax isa Axis3 && return false
    return all(ae -> ae.axis.ylabel[] == ax.ylabel[], nonempty_aes)
end

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

function facet!(fig, aes::AbstractMatrix{AxisEntries}; linkxaxes = true, linkyaxes = true)
    facet_wrap!(fig, aes; linkxaxes, linkyaxes)
    facet_grid!(fig, aes; linkxaxes, linkyaxes)
    return
end

function facet!(fg::FigureGrid; linkxaxes = true, linkyaxes = true)
    facet!(fg.figure, fg.grid; linkxaxes, linkyaxes)
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

function hideinnerdecorations!(aes, linkxaxes, linkyaxes)
    I, J = size(aes)
        
    hideydecorations!.(aes[:, 2:end],
        grid = false,
        ticks = linkyaxes,
        ticklabels = linkyaxes
    )
    
    if linkxaxes
        for i in 1:I, j in 1:J
            # don't hide x decorations if axis below is empty
            below_empty = (i < I) && empty_ae(aes[i+1,j])
            
            if (i < I) && !below_empty
                hidexdecorations!(aes[i,j],
                    grid = false,
                    ticks = linkxaxes,
                    ticklabels = linkxaxes
                )
            end

            if (i < I) && below_empty
                # improve appearance with empty axes
                aes[i,j].axis.alignmode = Mixed(bottom = MakieLayout.GridLayoutBase.Protrusion(0))
            end
        end
    end
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
