struct Visual
    plottype::PlotFunc
    attributes::Dict{Symbol, Any}
end
Visual(plottype=Any; kwargs...) = Visual(plottype, Dict{Symbol, Any}(kwargs))

function (v::Visual)(e::Entry)
    plottype = AbstractPlotting.plottype(v.plottype, e.plottype)
    mappings = e.mappings
    attributes = merge(e.attributes, v.attributes)
    return Entry(plottype, mappings, attributes)
end

visual(plottype=Any; kwargs...) = Layer((Visual(plottype; kwargs...),))