## Options preprocessing

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

## Facet labels

function labels!(fig, aes, scale, dir)
    # Reference axis to extract attributes
    ax = first(nonemptyaxes(aes))
    color = ax.titlecolor
    font = ax.titlefont
    textsize = ax.titlesize

    padding_index = dir == :row ? 1 : 3
    facetlabelpadding = lift(ax.titlegap) do gap
        return ntuple(i -> i == padding_index ? gap : 0f0, 4)
    end

    for (index, label) in zip(plotvalues(scale), datavalues(scale))
        rotation = dir == :row ? -π/2 : 0.0 
        figpos = dir == :col ? fig[1, index, Top()] : dir == :row ? fig[index, size(aes, 2), Right()] : fig[index..., Top()]
        Label(figpos, to_string(label); rotation, padding=facetlabelpadding, color, font, textsize)
    end
end

col_labels!(fig, aes, scale) = labels!(fig, aes, scale, :col)
row_labels!(fig, aes, scale) = labels!(fig, aes, scale, :row)
panel_labels!(fig, aes, scale) = labels!(fig, aes, scale, :wrap)

# consistent axis labels

function consistent_attribute(aes, attr)
    axes = nonemptyaxes(aes)
    ax = first(axes)
    return all(axis -> getproperty(axis, attr)[] == getproperty(ax, attr)[], axes)
end

consistent_xlabels(aes) = consistent_attribute(aes, :xlabel)
consistent_ylabels(aes) = consistent_attribute(aes, :ylabel)

colwise_consistent_xlabels(aes) = all(consistent_xlabels, eachcol(aes))
rowwise_consistent_ylabels(aes) =  all(consistent_ylabels, eachrow(aes))

# spanned axis labels

get_attr(axis, var, key) = getproperty(axis, Symbol(var, key))

function span_label!(fig, aes, var)
    for ae in aes
        get_attr(ae.axis, var, :labelvisible)[] = false
    end

    ax = first(nonemptyaxes(aes))

    pos = var == :x ? (size(aes, 1), :) : (:, 1)
    labelpadding = get_attr(ax, var, :labelpadding)
    index, side, Side = var == :x ? (4, :bottom, Bottom()) : (2, :left, Left())

    padding = lift(labelpadding, (MakieLayout.protrusionsobservable(ae.axis) for ae in aes[pos...])...) do p, xs...
        protrusion = maximum(x -> getproperty(x, side), xs)
        return ntuple(i -> i == index ? protrusion + p : 0f0, 4)
    end

    label = get_attr(ax, var, :label)
    rotation = var == :x ? 0.0 : π/2
    color = get_attr(ax, var, :labelcolor)
    font = get_attr(ax, var, :labelfont)
    textsize = get_attr(ax, var, :labelsize)
    Label(fig[pos..., Side], label; rotation, padding, color, font, textsize)
end

span_xlabel!(fig, aes) = span_label!(fig, aes, :x)
span_ylabel!(fig, aes) = span_label!(fig, aes, :y)

## Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries}; facet)

    scale = get(aes[1].categoricalscales, :layout, nothing)
    isnothing(scale) && return

    # Link axes and hide decorations if appropriate
    attr = clean_facet_attributes(aes, facet)
    link_axes!(aes; attr.linkxaxes, attr.linkyaxes)
    hideinnerdecorations!(aes; attr.hidexdecorations, attr.hideydecorations)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    panel_labels!(fig, aes, scale)

    # span axis labels if appropriate
    is2d = all(isaxis2d, nonemptyaxes(aes))

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
    hideinnerdecorations!(aes; attr.hidexdecorations, attr.hideydecorations)

    # span axis labels if appropriate
    is2d = all(isaxis2d, nonemptyaxes(aes))

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

# Handy non-splatting versions

link_xaxes!(aes::AbstractArray{AxisEntries}) = (linkxaxes!(aes...); aes)
link_yaxes!(aes::AbstractArray{AxisEntries}) = (linkyaxes!(aes...); aes)

function link_axes!(aes; linkxaxes, linkyaxes)
    linkxaxes == :all && link_xaxes!(aes)
    linkxaxes == :colwise && foreach(link_xaxes!, eachcol(aes))

    linkyaxes == :all && link_yaxes!(aes)
    linkyaxes == :rowise && foreach(link_yaxes!, eachrow(aes))

    return aes
end

# Handy grid-preserving versions

hide_xdecorations!(ax) = hidexdecorations!(ax; grid=false, minorgrid=false)
hide_ydecorations!(ax) = hideydecorations!(ax; grid=false, minorgrid=false)

function hideinnerdecorations!(aes; hidexdecorations, hideydecorations)
    I, J = size(aes)
        
    if hideydecorations
        for i in 1:I, j in 2:J
            hide_ydecorations!(aes[i,j])
        end
    end

    if hidexdecorations
        for i in 1:I-1, j in 1:J
            if isempty(aes[i+1,j].entries)
                # Don't hide x decorations if axis below is empty, but instead improve alignment.
                aes[i,j].axis.alignmode = Mixed(bottom=MakieLayout.GridLayoutBase.Protrusion(0))
            else
                hide_xdecorations!(aes[i,j])
            end
        end
    end
end

# Miscellaneous utilities

nonemptyaxes(aes) = (ae.axis for ae in aes if !isempty(ae.entries))

function deleteemptyaxes!(aes::AbstractMatrix{AxisEntries})
    for ae in aes
        if isempty(ae.entries)
            delete!(ae.axis)
        end
    end
end

Makie.resize_to_layout!(fg::FigureGrid) = resize_to_layout!(fg.figure)

@deprecate resizetocontent!(fig) (resize_to_layout!(fig); fig)