function layoutplot!(scene, l, s::Tree)
    palette = AbstractPlotting.current_default_theme()[:palette]
    serieslist = specs(s, palette)
    axdict = Dict()
    legdict = Dict{Symbol, Any}()
    for series in serieslist
        for (primary, trace) in series
            P = plottype(trace)
            args = trace.args
            attrs = Attributes(trace.kwargs)
            # TODO also deal with names here
            pop!(attrs, :names)
            x_pos = pop!(attrs, :layout_x, 1) |> to_value
            y_pos = pop!(attrs, :layout_y, 1) |> to_value
            current = get!(axdict, (x_pos, y_pos)) do
                l[y_pos, x_pos] = MakieLayout.LAxis(scene)
            end
            last = AbstractPlotting.plot!(current, P, attrs, args...)
            for (key, val) in pairs(primary)
                key in (:layout_x, :layout_y) && continue
                legsubdict = get!(legdict, key, OrderedDict{String, Vector{AbstractPlot}}())
                legentry = get!(legsubdict, string(val), AbstractPlot[])
                push!(legentry, last)
            end
        end
    end
    legends = Any[]
    for v in values(legdict)
        push!(legends, MakieLayout.LLegend(scene, collect(values(v)), collect(keys(v))))
    end
    # place correctly
    N = maximum(first, keys(axdict))
    for i in eachindex(legends)
        l[i, N+1] = legends[i]
    end
    return scene
end

function layoutplot(s::Tree; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)
