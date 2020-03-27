function layoutplot!(scene, l, s::Tree)
    palette = AbstractPlotting.current_default_theme()[:palette]
    serieslist = specs(s, palette)
    axdict = Dict()
    for series in serieslist
        for (_, trace) in series
            P = plottype(trace)
            args = trace.args
            attrs = Attributes(trace.kwargs)
            x_pos = pop!(attrs, :layout_x, 1) |> to_value
            y_pos = pop!(attrs, :layout_y, 1) |> to_value
            current = get!(axdict, (x_pos, y_pos)) do
                l[y_pos, x_pos] = MakieLayout.LAxis(scene)
            end
            AbstractPlotting.plot!(current, P, attrs, args...)
        end
    end
    return scene
end

function layoutplot(s::Tree; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)
