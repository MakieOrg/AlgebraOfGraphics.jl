# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries}; facet)

    scale = get(aes[1].categoricalscales, :layout, nothing)
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
    row_scale, col_scale = map(sym -> get(aes[1].categoricalscales, sym, nothing), (:row, :col))
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

"""
    get_with_options(collection, key; options)

Internal helper function to get the value corresponding to `key` in a `collection`.
If the value is not present, return `automatic`.
If the value is not among the `options`, warn and return `automatic`.
"""
function get_with_options(collection, key; options)
    value = get(collection, key, automatic)
    if isequal(value, automatic) || value in options
        return value
    else
        msg = sprint() do io
            print(io, "Replaced invalid keyword $key = ")
            show(io, value)
            print(io, " by automatic. ")
            print(io, "Valid values are ")
            for option in options
                show(io, option)
                print(io, ", ")
            end
            print(io, "or automatic.")
        end
        @warn msg
        return automatic
    end
end

function normalize_link(link, direction, consistent, directionally_consistent)
    directionwise = Symbol(direction, :wise)
    link in (:all, directionwise, :none) && return link
    link === automatic && return consistent ? :all : directionally_consistent ? directionwise : :none
    link == :minimal && return directionally_consistent ? directionwise : :none
    link == true && return :all
    link == false && return :none
    throw(ArgumentError("Could not convert $link to standard link attribute."))
end

normalize_hide(hide, link) = hide === automatic ? (link != :none) : hide

function clean_facet_attributes(aes, facet)
    _linkxaxes = get_with_options(facet, :linkxaxes, options=(:all, :colwise, :minimal, :none, true, false))
    _linkyaxes = get_with_options(facet, :linkyaxes, options=(:all, :rowwise, :minimal, :none, true, false))

    linkxaxes = normalize_link(_linkxaxes, :col, consistent_xlabels(aes), colwise_consistent_xlabels(aes))
    linkyaxes = normalize_link(_linkyaxes, :row, consistent_ylabels(aes), rowwise_consistent_ylabels(aes))

    _hidexdecorations = get_with_options(facet, :hidexdecorations, options=(true, false))
    _hideydecorations = get_with_options(facet, :hideydecorations, options=(true, false))

    hidexdecorations = normalize_hide(_hidexdecorations, linkxaxes)
    hideydecorations = normalize_hide(_hideydecorations, linkyaxes)

    return (; linkxaxes, linkyaxes, hidexdecorations, hideydecorations)
end

# link axes

link_xaxes!(aes::AbstractArray{<:AxisEntries}) = (linkxaxes!(aes...); aes)
link_yaxes!(aes::AbstractArray{<:AxisEntries}) = (linkyaxes!(aes...); aes)

function link_axes!(aes; linkxaxes, linkyaxes)
    linkxaxes == :all && link_xaxes!(aes)
    linkxaxes == :colwise && foreach(link_xaxes!, eachcol(aes))

    linkyaxes == :all && link_yaxes!(aes)
    linkyaxes == :rowise && foreach(link_yaxes!, eachrow(aes))

    return aes
end

# facet labels

function col_labels!(fig, aes, scale)
    zipped_scale = zip(plotvalues(scale), datavalues(scale))

    titlegap, attributes = facetlabelattributes(first_nonempty_axis(aes))

    facetlabelpadding = lift(titlegap) do gap
        return (0f0, 0f0, gap, 0f0)
    end

    for (index, label) in zipped_scale
        Label(fig[1, index, Top()], to_string(label);
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
        Label(fig[index, N, Right()], to_string(label);
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
        Label(fig[index..., Top()], to_string(label);
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

    return (; titlegap, attributes)
end

# consistent axis labels

function consistent_attribute(aes, attr)
    nonempty_aes = get_nonempty_aes(aes)
    ax = first(nonempty_aes).axis
    return all(ae -> getproperty(ae.axis, attr)[] == getproperty(ax, attr)[], nonempty_aes)
end

consistent_xlabels(aes) = consistent_attribute(aes, :xlabel)
consistent_ylabels(aes) = consistent_attribute(aes, :ylabel)

colwise_consistent_xlabels(aes) = all(consistent_xlabels, eachcol(aes))
rowwise_consistent_ylabels(aes) =  all(consistent_ylabels, eachrow(aes))

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
    update(fig) do f
        facet_wrap!(f, aes; facet)
        facet_grid!(f, aes; facet)
    end
    return
end

function facet!(fg::FigureGrid; facet)
    facet!(fg.figure, fg.grid; facet)
    return fg
end

## Layout helpers

isaxis2d(::Axis) = true
isaxis2d(::Axis3) = false
isaxis2d(ax::AxisSpec) = ax.type <: Axis
isaxis2d(ae::AxisEntries) = isaxis2d(ae.axis)
isaxis2d(ae::AxisSpecEntries) = isaxis2d(ae.axis)

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

Makie.resize_to_layout!(fg::FigureGrid) = resize_to_layout!(fg.figure)
