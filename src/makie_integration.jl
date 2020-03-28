const Attributes   = AbstractPlotting.Attributes
const SceneLike    = AbstractPlotting.SceneLike
const PlotFunc     = AbstractPlotting.PlotFunc
const AbstractPlot = AbstractPlotting.AbstractPlot
const xlabel!      = AbstractPlotting.xlabel!
const ylabel!      = AbstractPlotting.ylabel!
const zlabel!      = AbstractPlotting.zlabel!

# forcefully remove extra info from the plot call
function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, a::Attributes, tree::Tree)
    P === Any || error("Only `plot` is supported on a `Tree`")
    isempty(a) || error("No attributes can be passed to `plot(t::Tree)`")
    palette = AbstractPlotting.current_default_theme()[:palette]
    serieslist = specs(tree, palette)
    for series in serieslist
        for (_, trace) in series
            P = plottype(trace)
            attr = Attributes(trace.kwargs)
            pop!(attr, :names)
            AbstractPlotting.plot!(scn, P, attr, trace.args...)
            for (nm, func!) in zip(positional(trace.kwargs.names), [xlabel!, ylabel!, zlabel!])
                func!(string(nm))
            end
        end
    end
    return scn
end
