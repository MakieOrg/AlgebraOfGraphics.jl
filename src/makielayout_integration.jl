using AbstractPlotting: px, Attributes, AbstractPlot, AbstractPlotting
using MakieLayout: LAxis,
                   GridLayout,
                   linkxaxes!,
                   linkyaxes!,
                   hidexdecorations!,
                   hideydecorations!,
                   MakieLayout

function set_names!(ax, trace)
    for (nm, prop) in zip(positional(trace.kwargs.names), (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if !isempty(s)
            getproperty(ax, prop)[] = s
        end
    end
end

function create_name(k, v)
    n = string(get_name(first(keys(v))))
    isempty(n) ? string(k) : n
end

function create_legend(scene, legdict::AbstractDict)
    plts_list = [collect(values(v)) for v in values(legdict)]
    entries_list = [string.(keys(v)) for v in values(legdict)]
    names = [create_name(k, v) for (k, v) in pairs(legdict)]
    MakieLayout.LLegend(scene, plts_list, entries_list, names)
end

function adjust_color(c, alpha)
    to_value(c) isa Union{Tuple, AbstractArray} ? c : map(tuple, c, alpha)
end

function set_defaults!(attrs::Attributes)
    # manually implement alpha values
    col = get(attrs, :color, Observable(:black))
    alpha = get(attrs, :alpha, Observable(1))
    attrs[:color] = adjust_color(col, alpha)
    get!(attrs, :markersize, Observable(8px))
end

function layoutplot!(scene, layout, ts::GraphicalOrContextual)
    facetlayout = layout[1, 1] = GridLayout()
    serieslist = layers(compute(ts))
    Nx, Ny = 1, 1
    for (sp, series) in serieslist
        for style in series
            trace = merge(sp, Spec(style))
            Nx = max(Nx, to_value(get(trace.kwargs, :layout_x, Nx)))
            Ny = max(Ny, to_value(get(trace.kwargs, :layout_y, Ny)))
        end
    end
    axs = facetlayout[1:Ny, 1:Nx] = [LAxis(scene) for i in 1:Ny, j in 1:Nx]
    for i in 1:Nx
        linkxaxes!(axs[:, i]...)
    end
    for i in 1:Ny
        linkyaxes!(axs[i, :]...)
    end
    hidexdecorations!.(axs[1:end-1, :])
    hideydecorations!.(axs[:, 2:end])
    legdict = Dict{Symbol, Any}()
    for (sp, series) in serieslist
        for style in series
            trace = merge(sp, Spec(style))
            P = plottype(trace)
            P isa Symbol && (P = getproperty(AbstractPlotting, P))
            args = trace.args
            attrs = Attributes(trace.kwargs)
            set_defaults!(attrs)
            pop!(attrs, :names)
            x_pos = pop!(attrs, :layout_x, 1) |> to_value
            y_pos = pop!(attrs, :layout_y, 1) |> to_value
            current = AbstractPlotting.plot!(axs[y_pos, x_pos], P, attrs, args...)
            set_names!(axs[y_pos, x_pos], trace)
            # for (key, val) in pairs(group)
            #     key in (:layout_x, :layout_y) && continue
            #     legsubdict = get!(legdict, key, OrderedDict{Any, AbstractPlot}())
            #     legentry = get!(legsubdict, val, current)
            # end
        end
    end
    if !isempty(legdict)
        try
            layout[1, 2] = create_legend(scene, legdict)
        catch e
            @warn "Automated legend was not possible due to $e"
        end
    end
    return scene
end

function layoutplot(s; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)

draw(args...; kwargs...) = layoutplot(args...; kwargs...)
