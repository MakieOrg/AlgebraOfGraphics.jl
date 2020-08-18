function AbstractPlotting.MakieLayout.LColorbar(parent::Scene, plots::Vector{<: AbstractPlot}; kwargs...)
    colormap = plots[1].colormap
    # compute colorrange
    min = minimum(p.colorrange[][1] for p in plots)
    max = maximum(p.colorrange[][2] for p in plots)
    colorrange = (min, max)
     
    for p in plots
        p.colorrange = colorrange
    end
    
    LColorbar(parent,
        colormap = plots[1].colormap,
        limits = colorrange;
        kwargs...) 
end
