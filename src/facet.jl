# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries})
    scale = get(aes[1].scales, :layout, nothing)
    isnothing(scale) && return
    linkaxes!(aes...)
    for ae in aes
        ax = ae.axis
        entries = ae.entries
        vs = Iterators.filter(
            !isnothing,
            (get(entry.primary, :layout, nothing) for entry in entries)
        )
        it = iterate(vs)
        if isnothing(it)
            delete!(ax)
        else
            v, _ = it
            ax.title[] = to_string(v)
        end
    end
    return
end

# F. Greimel implementation from AlgebraOfGraphics

# TODO: add configuration options here (esp. to determine when / how to link)
function facet_grid!(fig, aes::AbstractMatrix{AxisEntries})
    M, N = size(aes)
    row_scale, col_scale = map(sym -> get(aes[1].scales, sym, nothing), (:row, :col))
    all(isnothing, (row_scale, col_scale)) && return
    hideinnerdecorations!(aes)
    linkaxes!(aes...)

    nonempty_aes = filter(ae -> !isempty(ae.entries), aes)

    ax = first(nonempty_aes).axis
    titlegap = ax.titlegap
    titlecolor = ax.titlecolor
    titlefont = ax.titlefont
    titlesize = ax.titlesize
    facetlabelattributes = (
        color=titlecolor,
        font=titlefont,
        textsize=titlesize,
    )

    consistent_xlabels = all(ae -> ae.axis.xlabel[] == ax.xlabel[], nonempty_aes)
    consistent_ylabels = all(ae -> ae.axis.ylabel[] == ax.ylabel[], nonempty_aes)

    if !isnothing(row_scale) && consistent_ylabels
        for ae in aes
            ae.axis.ylabelvisible[] = false
        end
        row_dict = Dict(zip(plotvalues(row_scale), datavalues(row_scale)))
        facetlabelpadding = lift(titlegap) do gap
            return (gap, 0f0, 0f0, 0f0)
        end
        for m in 1:M
            Label(fig[m, N, Right()], to_string(row_dict[m]);
                rotation=-π/2, padding=facetlabelpadding,
                facetlabelattributes...)
        end
        protrusion = lift(
            (xs...) -> maximum(x -> x.left, xs),
            (MakieLayout.protrusionsobservable(ae.axis) for ae in aes[:, 1])...
        )
        # TODO: here and below, set in such a way that one can change padding after the fact?
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
    if !isnothing(col_scale) && consistent_xlabels
        for ae in aes
            ae.axis.xlabelvisible[] = false
        end
        col_dict = Dict(zip(plotvalues(col_scale), datavalues(col_scale)))
        labelpadding = lift(titlegap) do gap
            return (0f0, 0f0, gap, 0f0)
        end
        for n in 1:N
            Label(fig[1, n, Top()], to_string(col_dict[n]);
                padding=labelpadding, facetlabelattributes...)
        end
        protrusion = lift(
            (xs...) -> maximum(x -> x.bottom, xs),
            (MakieLayout.protrusionsobservable(ae.axis) for ae in aes[M, :])...
        )
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
    return
end

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
