struct Visual
    plottype::PlotType
    attributes::NamedArguments
end
Visual(plottype=Plot{Any}; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    attributes = merge(input.attributes, v.attributes)
    return ProcessedLayer(input; plottype, attributes)
end

visual(plottype=Plot{Any}; kwargs...) = transformation(Visual(plottype; kwargs...))