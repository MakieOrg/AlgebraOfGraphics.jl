# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries}; facet)

    scale = get(aes[1].scales, :layout, nothing)
    isnothing(scale) && return

    # Link axes and hide decorations if appropriate
    attr = clean_facet_attributes(aes, facet)
    link_axes!(aes; attr.linkxaxes, attr.linkyaxes)
    hideinnerdecorations!(aes, attr.hidexdecorations, attr.hideydecorations)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    panel_labels!(fig, aes, scale)

    # span axis labels if appropriate
    nonempty_aes = get_nonempty_aes(aes)
    is2d = isaxis2d(first(nonempty_aes))

    if is2d && consistent_ylabels(aes)
        span_ylabel!(fig, aes)
    end
    if is2d && consistent_xlabels(aes)
        span_xlabel!(fig, aes)
    end
    
    return
end

function facet_grid!(fig, aes::AbstractMatrix{AxisEntries}; facet)
    M, N = size(aes)
    row_scale, col_scale = map(sym -> get(aes[1].scales, sym, nothing), (:row, :col))
    all(isnothing, (row_scale, col_scale)) && return

    # Link axes and hide decorations if appropriate
    attr = clean_facet_attributes(aes, facet)
    link_axes!(aes; attr.linkxaxes, attr.linkyaxes)
    hideinnerdecorations!(aes, attr.hidexdecorations, attr.hideydecorations)

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

function clean_facet_attributes(aes, facet)
    linkxaxes = get(facet, :linkxaxes, automatic)
    linkyaxes = get(facet, :linkyaxes, automatic)
    hidexdecorations = get(facet, :hidexdecorations, automatic)
    hideydecorations = get(facet, :hideydecorations, automatic)

    if linkxaxes ∉ [:all, :colwise, :minimal, :none, true, false, automatic]
        @warn "Replaced invalid keyword linkxaxes = $linkxaxes by automatic"
        linkxaxes = automatic
    end

    if linkyaxes ∉ [:all, :rowwise, :minimal, :none, true, false, automatic] 
        @warn "Replaced invalid keyword linkyaxes = $linkyaxes by automatic"
        linkyaxes = automatic
    end

    if hidexdecorations ∉ [true, false, automatic]
        @warn "Replaced invalid keyword hidexdecorations = $hidexdecorations by automatic"
        hidexdecorations = automatic
    end

    if hideydecorations ∉ [true, false, automatic] 
        @warn "Replaced invalid keyword hideydecorations = $hideydecorations by automatic"
        hideydecorations = automatic
    end

    if linkxaxes === automatic
        if consistent_xlabels(aes)
            linkxaxes = :all
        elseif colwise_consistent_xlabels(aes)
            linkxaxes = :colwise
        else
            linkxaxes = :none
        end
    end

    if linkxaxes == :minimal
        if colwise_consistent_xlabels(aes)
            linkxaxes = :colwise
        else
            linkxaxes = :none
        end
    end

    if linkyaxes === automatic
        if consistent_ylabels(aes)
            linkyaxes = :all
        elseif rowwise_consistent_ylabels(aes)
            linkyaxes = :rowwise
        else
            linkyaxes = :none
        end
    end

    if linkyaxes == :minimal
        if rowwise_consistent_ylabels(aes)
            linkyaxes = :rowwise
        else
            linkyaxes = :none
        end
    end

    if linkxaxes == true
        linkxaxes = :all
    elseif linkxaxes == false
        linkxaxes = :none
    end

    if linkyaxes == true
        linkyaxes = :all
    elseif linkyaxes == false
        linkyaxes = :none
    end

    if hidexdecorations === automatic
        hidexdecorations = (linkxaxes != :none)
    end
    if hideydecorations === automatic
        hideydecorations = (linkyaxes != :none)
    end

    (; linkxaxes, linkyaxes, hidexdecorations, hideydecorations)
end

# link axes

function link_axes!(aes; linkxaxes, linkyaxes)
    if linkxaxes == :all
        linkxaxes!(aes...)
    elseif linkxaxes == :colwise
        link_cols!(aes)
    end

    if linkyaxes == :all
        linkyaxes!(aes...)
    elseif linkyaxes == :rowwise
        link_rows!(aes)
    end
end

function link_rows!(aes)
    M, N = size(aes)
    for i in 1:M
        linkyaxes!(aes[i,:]...)
    end
end

function link_cols!(aes)
    M, N = size(aes)
    for i in 1:N
        linkxaxes!(aes[:,i]...)
    end
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

function colwise_consistent_xlabels(aes)
    _, N = size(aes)
    all(consistent_xlabels(aes[:,i]) for i in 1:N)
end

function rowwise_consistent_ylabels(aes)
    M, _ = size(aes)
    all(consistent_ylabels(aes[i,:]) for i in 1:M)
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

function facet!(fig, aes::AbstractMatrix{AxisEntries}; facet)
    facet_wrap!(fig, aes; facet)
    facet_grid!(fig, aes; facet)
    return
end

function facet!(fg::FigureGrid; facet)
    facet!(fg.figure, fg.grid; facet)
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

function hideinnerdecorations!(aes, hidexdecorations, hideydecorations)
    I, J = size(aes)
        
    if hideydecorations
        hideydecorations!.(aes[:, 2:end], grid = false)
    end
    
    if hidexdecorations
        for i in 1:I, j in 1:J
            # don't hide x decorations if axis below is empty
            below_empty = (i < I) && empty_ae(aes[i+1,j])
            
            if (i < I) && !below_empty
                hidexdecorations!(aes[i,j],
                    grid = false,
                    ticks = hidexdecorations,
                    ticklabels = hidexdecorations
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
