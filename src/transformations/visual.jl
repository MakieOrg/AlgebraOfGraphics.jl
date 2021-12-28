struct Visual
    plottype::PlotFunc
    attributes::NamedArguments
end
Visual(plottype=Any; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    attributes = merge(input.attributes, v.attributes)
    return ProcessedLayer(input; plottype, attributes)
end

visual(plottype=Any; kwargs...) = transformation(Visual(plottype; kwargs...))