const Attributes   = AbstractPlotting.Attributes
const SceneLike    = AbstractPlotting.SceneLike
const PlotFunc     = AbstractPlotting.PlotFunc
const AbstractPlot = AbstractPlotting.AbstractPlot

# forcefully remove extra info from the plot call
function AbstractPlotting.plot!(scn::SceneLike, ::PlotFunc, ::Attributes, tree::Tree)
    palette = AbstractPlotting.current_default_theme()[:palette]
    speclist = specs(tree, palette)
    for specdict in speclist
        for (key, spec) in specdict
            P = plottype(spec)
            AbstractPlotting.plot!(scn, P, Attributes(spec.kwargs), spec.args...)
        end
    end
    return scn
end
