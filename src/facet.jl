## Options preprocessing

function normalize_link(link, var, consistent, directionally_consistent)
    directionwise = var == :x ? :colwise : :rowwise
    default = consistent ? :all : directionally_consistent ? directionwise : :none
    link === automatic && return default
    link == :minimal && return directionally_consistent ? directionwise : :none
    link == true && return :all
    link == false && return :none
    link in (:all, directionwise, :none) && return link
    attribute = Symbol(:link, var, :axes)
    @warn "Replaced invalid keyword $attribute = $(repr(link)) by automatic. " *
        "Valid values are :all, $(repr(directionwise)), :minimal, :none, true, false, or automatic."
    return default
end

function normalize_hide(hide, link, var)
    default = link != :none
    hide === automatic && return default
    hide isa Bool && return hide
    attribute = Symbol(:hide, var, :decorations)
    @warn "Replaced invalid keyword $attribute = $(repr(hide)) by automatic. " *
        "Valid values are true, false, or automatic."
    return default
end

function clean_facet_attributes(aes;
                                linkxaxes=automatic, linkyaxes=automatic,
                                hidexdecorations=automatic, hideydecorations=automatic)
    linkxaxes = normalize_link(linkxaxes, :x, consistent_xlabels(aes), colwise_consistent_xlabels(aes))
    linkyaxes = normalize_link(linkyaxes, :y, consistent_ylabels(aes), rowwise_consistent_ylabels(aes))
    hidexdecorations = normalize_hide(hidexdecorations, linkxaxes, :x)
    hideydecorations = normalize_hide(hideydecorations, linkyaxes, :y)
    return (; linkxaxes, linkyaxes, hidexdecorations, hideydecorations)
end

## Label computation and layout

# facet labels
function facet_labels!(fig, aes, scale, dir)
    # reference axis to extract attributes
    ax = first(nonemptyaxes(aes))
    color = ax.titlecolor
    font = ax.titlefont
    fontsize = ax.titlesize
    visible = ax.titlevisible

    padding_index = dir == :row ? 1 : 3
    padding = lift(ax.titlegap) do gap
        return ntuple(i -> i == padding_index ? gap : 0f0, 4)
    end

    return map(plotvalues(scale), datalabels(scale)) do index, label
        rotation = dir == :row ? -π/2 : 0.0
        figpos = dir == :col ? fig[1, index, Top()] :
                 dir == :row ? fig[index, size(aes, 2), Right()] : fig[index..., Top()]
        return Label(figpos, label; rotation, padding, color, font, fontsize, visible)
    end
end

col_labels!(fig, aes, scale) = facet_labels!(fig, aes, scale, :col)
row_labels!(fig, aes, scale) = facet_labels!(fig, aes, scale, :row)
panel_labels!(fig, aes, scale) = facet_labels!(fig, aes, scale, :layout)

# Consistent axis labels

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
function span_label!(fig, aes, var)
    getattr = GetAttr(var)
    for ae in aes
        getattr(ae.axis, :labelvisible)[] = false
    end

    ax = first(nonemptyaxes(aes))

    pos = var == :x ? (size(aes, 1), :) : (:, 1)
    index, side, Side = var == :x ? (4, :bottom, Bottom) : (2, :left, Left)

    protrusions = (protrusionsobservable(ae.axis) for ae in aes[pos...])
    padding = lift(getattr(ax, :labelpadding), protrusions...) do p, xs...
        protrusion = maximum(x -> getproperty(x, side), xs)
        return ntuple(i -> i == index ? protrusion + p : 0f0, 4)
    end

    label = to_value(getattr(ax, :label))
    label == "" && return

    rotation = var == :x ? 0.0 : π/2
    color = getattr(ax, :labelcolor)
    font = getattr(ax, :labelfont)
    fontsize = getattr(ax, :labelsize)
    return Label(fig[pos..., Side()], label; rotation, padding, color, font, fontsize)
end

span_xlabel!(fig, aes) = span_label!(fig, aes, :x)
span_ylabel!(fig, aes) = span_label!(fig, aes, :y)

## Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries}; facet)

    scale = extract_single(AesLayout, aes[1].categoricalscales)
    isnothing(scale) && return

    # Link axes and hide decorations if appropriate
    attrs = clean_facet_attributes(aes; pairs(facet)...)
    link_axes!(aes; attrs.linkxaxes, attrs.linkyaxes)
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap=true)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    scale.props.aesprops.show_labels && panel_labels!(fig, aes, scale)

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
    row_scale = extract_single(AesRow, aes[1].categoricalscales)
    col_scale = extract_single(AesCol, aes[1].categoricalscales)
    all(isnothing, (row_scale, col_scale)) && return

    # link axes and hide decorations if appropriate
    attrs = clean_facet_attributes(aes; pairs(facet)...)
    link_axes!(aes; attrs.linkxaxes, attrs.linkyaxes)
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap=false)

    # span axis labels if appropriate
    is2d = all(isaxis2d, nonemptyaxes(aes))

    is2d && consistent_ylabels(aes) && span_ylabel!(fig, aes)
    is2d && consistent_xlabels(aes) && span_xlabel!(fig, aes)

    if !isnothing(row_scale)
        row_scale.props.aesprops.show_labels && row_labels!(fig, aes, row_scale)
    end
    if !isnothing(col_scale)
        col_scale.props.aesprops.show_labels && col_labels!(fig, aes, col_scale)
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

function link_axes!(aes::AbstractArray{AxisEntries}; linkxaxes, linkyaxes)
    linkxaxes == :all && link_xaxes!(aes)
    linkxaxes == :colwise && foreach(link_xaxes!, eachcol(aes))

    linkyaxes == :all && link_yaxes!(aes)
    linkyaxes == :rowwise && foreach(link_yaxes!, eachrow(aes))

    return aes
end

# Handy grid-preserving versions

hide_xdecorations!(ax) = hidexdecorations!(ax; grid=false, minorgrid=false)
hide_ydecorations!(ax) = hideydecorations!(ax; grid=false, minorgrid=false)

function hideinnerdecorations!(aes::AbstractArray{AxisEntries};
                               hidexdecorations, hideydecorations, wrap)
    I, J = size(aes)

    if hideydecorations
        for i in 1:I, j in 2:J
            hide_ydecorations!(aes[i,j])
        end
    end

    if hidexdecorations
        for i in 1:I-1, j in 1:J
            if wrap && isempty(aes[i+1,j].entries)
                # In facet_wrap, don't hide x decorations if axis below is empty,
                # but instead improve alignment.
                aes[i,j].axis.alignmode = Mixed(bottom=Protrusion(0))
            else
                hide_xdecorations!(aes[i,j])
            end
        end
    end
end

# Miscellaneous utilities

struct GetAttr
    var::Symbol
end

(g::GetAttr)(collection, args...) = getproperty(collection, Symbol(g.var, args...))

nonemptyaxes(aes) = (ae.axis for ae in aes if !isempty(ae.entries))

function deleteemptyaxes!(aes::AbstractArray{AxisEntries})
    for ae in aes
        if isempty(ae.entries)
            delete!(ae.axis)
        end
    end
end

Makie.resize_to_layout!(fg::FigureGrid) = resize_to_layout!(fg.figure)

@deprecate resizetocontent!(fig) (resize_to_layout!(fig); fig)
