# Apply default faceting look to a grid of `AxisEntries`

function facet_wrap!(fig, aes::AbstractMatrix{AxisEntries})
    scale = get(aes[1].scales, :layout, nothing)
    isnothing(scale) && return
    linkaxes!(aes...)
    for ae in aes
        ax = Axis(ae)
        entries = ae.entries
        vs = Iterators.filter(
            !isnothing,
            (get(entry.mappings, :layout, nothing) for entry in entries)
        )
        it = iterate(vs)
        if isnothing(it)
            delete!(ax)
        else
            v, _ = it
            ax.title[] = string(first(v))
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

    ax = Axis(aes[1])
    titlegap = ax.titlegap
    titlecolor = ax.titlecolor
    titlefont = ax.titlefont
    titlesize = ax.titlesize
    facetlabelattributes = (
        color=titlecolor,
        font=titlefont,
        textsize=titlesize,
    )

    if !isnothing(row_scale)
        for ae in aes
            Axis(ae).ylabelvisible[] = false
        end
        row_dict = Dict(zip(row_scale.plot, row_scale.data))
        facetlabelpadding = lift(titlegap) do gap
            return (gap, 0f0, 0f0, 0f0)
        end
        for m in 1:M
            Label(fig[m, N, Right()], string(row_dict[m]);
                rotation=-π/2, padding=facetlabelpadding,
                facetlabelattributes...)
        end
        protrusion = lift(
            (xs...) -> maximum(x -> x.left, xs),
            (MakieLayout.protrusionsobservable(Axis(ae)) for ae in aes[:, 1])...
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
    if !isnothing(col_scale)
        for ae in aes
            Axis(ae).xlabelvisible[] = false
        end
        col_dict = Dict(zip(col_scale.plot, col_scale.data))
        labelpadding = lift(titlegap) do gap
            return (0f0, 0f0, gap, 0f0)
        end
        for n in 1:N
            Label(fig[1, n, Top()], string(col_dict[n]); padding=labelpadding, facetlabelattributes...)
        end
        protrusion = lift(
            (xs...) -> maximum(x -> x.bottom, xs),
            (MakieLayout.protrusionsobservable(Axis(ae)) for ae in aes[M, :])...
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