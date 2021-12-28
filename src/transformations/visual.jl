struct Visual
    plottype::PlotFunc
    attributes::NamedArguments
end
Visual(plottype=Any; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(e::Entry)
    plottype = Makie.plottype(v.plottype, e.plottype)
    attributes = merge(e.attributes, v.attributes)
    return Entry(e; plottype, attributes)
end

visual(plottype=Any; kwargs...) = transformation(Visual(plottype; kwargs...))