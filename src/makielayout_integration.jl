using AbstractPlotting: px, Attributes, AbstractPlot, AbstractPlotting
using MakieLayout: LAxis,
                   GridLayout,
                   linkxaxes!,
                   linkyaxes!,
                   hidexdecorations!,
                   hideydecorations!,
                   MakieLayout

function set_names!(ax, names)
    for (nm, prop) in zip(names, (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if !isempty(s)
            getproperty(ax, prop)[] = s
        end
    end
end

function somestring(s, t)
    s = string(s)
    isempty(s) ? string(t) : s
end

function create_legend(scene, legdict::AbstractDict)
    plts_list = [collect(values(sublegdict)) for sublegdict in values(legdict)]
    entries_list = [collect(keys(sublegdict)) for sublegdict in values(legdict)]
    names = last.(keys(legdict))
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

function layoutplot!(scene, layout, ts::Algebraic)
    facetlayout = layout[1, 1] = GridLayout()
    serieslist = compute(ts)
    Nx, Ny = 1, 1
    for (sp, series) in serieslist
        for (key, val) in series
            trace = foldl(merge, (sp, Spec(key), Spec(val)))
            Nx = max(Nx, rank(to_value(get(trace.value, :layout_x, Nx))))
            Ny = max(Ny, rank(to_value(get(trace.value, :layout_y, Ny))))
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
    legdict = Dict{Pair, Any}()
    for (sp, series) in serieslist
        for (key, val) in series
            discrete_attrs = map(t -> t.value, key)
            trace = foldl(merge, (sp, Spec(discrete_attrs), Spec(val)))
            P = plottype(trace)
            P isa Symbol && (P = getproperty(AbstractPlotting, P))
            args, kwargs = split(trace.value)
            names, args = extract_names(args)
            attrs = Attributes(kwargs)
            set_defaults!(attrs)
            x_pos = pop!(attrs, :layout_x, 1) |> to_value |> rank
            y_pos = pop!(attrs, :layout_y, 1) |> to_value |> rank
            current = AbstractPlotting.plot!(axs[y_pos, x_pos], P, attrs, args...)
            set_names!(axs[y_pos, x_pos], names)
            for (k, v) in pairs(key)
                k in (:layout_x, :layout_y) && continue
                @assert v isa LegendEntry
                name = somestring(v.name, k)
                sublegdict = get!(legdict, k => name, OrderedDict{String, Vector{AbstractPlot}}())
                legtraces = get!(sublegdict, string(v.key), AbstractPlot[])
                push!(legtraces, current)
            end
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
