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

function normalize_single_label(single, var, consistent)
    default = consistent
    single === automatic && return default
    single isa Bool && return single
    attribute = Symbol(:single, var, :label)
    error("Invalid keyword $attribute = $(repr(single)). Valid values are true, false, or automatic.")
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

function clean_facet_attributes(
        aes;
        linkxaxes = automatic, linkyaxes = automatic,
        hidexdecorations = automatic, hideydecorations = automatic,
        singlexlabel = automatic, singleylabel = automatic
    )
    linkxaxes = normalize_link(linkxaxes, :x, consistent_xaxis(aes), colwise_consistent_xaxis(aes))
    linkyaxes = normalize_link(linkyaxes, :y, consistent_yaxis(aes), rowwise_consistent_yaxis(aes))
    hidexdecorations = normalize_hide(hidexdecorations, linkxaxes, :x)
    hideydecorations = normalize_hide(hideydecorations, linkyaxes, :y)
    singlexlabel = normalize_single_label(singlexlabel, :x, consistent_xlabels(aes))
    singleylabel = normalize_single_label(singleylabel, :y, consistent_ylabels(aes))
    return (; linkxaxes, linkyaxes, hidexdecorations, hideydecorations, singlexlabel, singleylabel)
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
        return ntuple(i -> i == padding_index ? gap : 0.0f0, 4)
    end

    return map(plotvalues(scale), datalabels(scale)) do index, label
        rotation = dir == :row ? -π / 2 : 0.0
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
    return all(axis -> Makie.to_value(getproperty(axis, attr)) == Makie.to_value(getproperty(ax, attr)), axes)
end

consistent_xlabels(aes) = consistent_attribute(aes, :xlabel)
consistent_ylabels(aes) = consistent_attribute(aes, :ylabel)
consistent_xaxis(aes) = consistent_xlabels(aes) && (any(!isaxis2d, nonemptyaxes(aes)) || consistent_attribute(aes, :xscale)) # TODO: remove special case once Axis3 supports scales
consistent_yaxis(aes) = consistent_ylabels(aes) && (any(!isaxis2d, nonemptyaxes(aes)) || consistent_attribute(aes, :yscale)) # TODO: remove special case once Axis3 supports scales

colwise_consistent_xlabels(aes) = all(consistent_xlabels, eachcol(aes))
rowwise_consistent_ylabels(aes) = all(consistent_ylabels, eachrow(aes))
colwise_consistent_xaxis(aes) = all(consistent_xaxis, eachcol(aes))
rowwise_consistent_yaxis(aes) = all(consistent_yaxis, eachrow(aes))

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
        return ntuple(i -> i == index ? protrusion + p : 0.0f0, 4)
    end

    label = to_value(getattr(ax, :label))
    label == "" && return

    rotation = var == :x ? 0.0 : π / 2
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
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap = true)

    # delete empty axes
    deleteemptyaxes!(aes)

    # add facet labels
    scale.props.legend && panel_labels!(fig, aes, scale)

    # span axis labels if appropriate
    is2d = all(isaxis2d, nonemptyaxes(aes))

    if is2d && attrs.singleylabel
        span_ylabel!(fig, aes)
    end
    if is2d && attrs.singlexlabel
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
    hideinnerdecorations!(aes; attrs.hidexdecorations, attrs.hideydecorations, wrap = false)

    # span axis labels if appropriate
    is2d = all(isaxis2d, nonemptyaxes(aes))

    is2d && attrs.singleylabel && span_ylabel!(fig, aes)
    is2d && attrs.singlexlabel && span_xlabel!(fig, aes)

    if !isnothing(row_scale)
        row_scale.props.legend && row_labels!(fig, aes, row_scale)
    end
    if !isnothing(col_scale)
        col_scale.props.legend && col_labels!(fig, aes, col_scale)
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
isaxis2d(b::Makie.BlockSpec) = b.type === :Axis
isaxis2d(::Axis3) = false
isaxis2d(ax::AxisSpec) = ax.type <: Axis
isaxis2d(ae::AxisEntries) = isaxis2d(ae.axis)
isaxis2d(ae::AxisSpecEntries) = isaxis2d(ae.axis)

for sym in [:hidexdecorations!, :hideydecorations!, :hidedecorations!]
    @eval function $sym(ae::AxisEntries; kwargs...)
        axis = ae.axis
        return isaxis2d(axis) && $sym(axis; kwargs...)
    end
end

for sym in [:linkxaxes!, :linkyaxes!, :linkaxes!]
    @eval function $sym(ae::AxisEntries, aes::AxisEntries...)
        axs = filter(isaxis2d, map(ae -> ae.axis, (ae, aes...)))
        return isempty(axs) || $sym(axs...)
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

hide_xdecorations!(ax) = hidexdecorations!(ax; grid = false, minorgrid = false)
hide_ydecorations!(ax) = hideydecorations!(ax; grid = false, minorgrid = false)

# An empty facet with ambiguous scales has its decorations hidden by compute_axes_grid.
# Neighboring axes must keep their decorations visible since the hidden axis can't show them.
# The check is direction-specific: hiding x decorations depends on whether the neighbor
# can show x ticks, and likewise for y.
_has_hidden_decorations(ae::AxisEntries, var::Symbol) =
    isaxis2d(ae) && isempty(ae.entries) && !to_value(getproperty(ae.axis, Symbol(var, :ticksvisible)))

function hideinnerdecorations!(
        aes::AbstractArray{AxisEntries};
        hidexdecorations, hideydecorations, wrap
    )
    I, J = size(aes)

    # Snapshot which cells were hidden by compute_axes_grid (ambiguous scales) BEFORE
    # any hide_*decorations! calls mutate axis attributes. Without this, hiding y
    # decorations on an empty cell (e.g., j=2) would make it look "hidden" to the
    # next column (j=3), incorrectly preserving that column's y decorations.
    x_hidden = [_has_hidden_decorations(aes[i, j], :x) for i in 1:I, j in 1:J]
    y_hidden = [_has_hidden_decorations(aes[i, j], :y) for i in 1:I, j in 1:J]

    if hideydecorations
        for i in 1:I, j in 2:J
            y_hidden[i, j - 1] && continue
            hide_ydecorations!(aes[i, j])
        end
    end

    if hidexdecorations
        for i in 1:(I - 1), j in 1:J
            below_empty = wrap && isempty(aes[i + 1, j].entries)
            if !below_empty && !x_hidden[i + 1, j]
                hide_xdecorations!(aes[i, j])
            end
        end
    end

    # When an axis neighbors a hidden-empty or deleted-empty axis, its tick labels
    # would otherwise create a gap. Setting Protrusion(0) lets them extend into the
    # empty space instead.
    for i in 1:I, j in 1:J
        overrides = NamedTuple()
        if hidexdecorations && i < I
            if (wrap && isempty(aes[i + 1, j].entries)) || x_hidden[i + 1, j]
                overrides = (; overrides..., bottom = Protrusion(0))
            end
        end
        if hideydecorations && j > 1 && y_hidden[i, j - 1]
            overrides = (; overrides..., left = Protrusion(0))
        end
        if !isempty(overrides)
            aes[i, j].axis.alignmode = Mixed(; overrides...)
        end
    end

    return
end

# Miscellaneous utilities

struct GetAttr
    var::Symbol
end

(g::GetAttr)(collection, args...) = getproperty(collection, Symbol(g.var, args...))

nonemptyaxes(aes) = (ae.axis for ae in aes if !isempty(ae.entries))
nonemptyaxes(aes::AbstractArray{<:Union{Nothing, Pair{Tuple{Int64, Int64}, Makie.BlockSpec}}}) = (a[2] for a in aes if a !== nothing)

function deleteemptyaxes!(aes::AbstractArray{AxisEntries})
    for ae in aes
        if isempty(ae.entries)
            delete!(ae.axis)
        end
    end
    return
end

Makie.resize_to_layout!(fg::FigureGrid) = resize_to_layout!(fg.figure)

@deprecate resizetocontent!(fig) (resize_to_layout!(fig); fig)
