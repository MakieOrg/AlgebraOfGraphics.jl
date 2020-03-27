const Attributes   = AbstractPlotting.Attributes
const SceneLike    = AbstractPlotting.SceneLike
const PlotFunc     = AbstractPlotting.PlotFunc
const AbstractPlot = AbstractPlotting.AbstractPlot

# forcefully remove extra info from the plot call
function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, a::Attributes, tree::Tree)
    P === Any || error("Only `plot` is supported on a `Tree`")
    isempty(a) || error("No attributes can be passed to `plot(t::Tree)`")
    palette = AbstractPlotting.current_default_theme()[:palette]
    serieslist = specs(tree, palette)
    for series in serieslist
        for (_, trace) in series
            P = plottype(trace)
            AbstractPlotting.plot!(scn, P, Attributes(trace.kwargs), trace.args...)
        end
    end
    return scn
end
