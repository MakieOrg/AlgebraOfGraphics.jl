Base.@kwdef struct StepHistogramAnalysis{D, B}
    datalimits::D=automatic
    bins::B=automatic
    closed::Symbol=:left
    normalization::Symbol=:none
end

function (h::StepHistogramAnalysis)(input::ProcessedLayer)
    datalimits = h.datalimits === automatic ? defaultdatalimits(input.positional) : h.datalimits
    options = valid_options(; datalimits, h.bins, h.closed, h.normalization)

    output = map(input) do p, n
        hist = _histogram(Tuple(p); pairs(n)..., pairs(options)...)
        edges, weights = hist.edges, hist.weights
        return (map(midpoints, edges)..., weights), (;)
    end

    N = length(input.positional)
    @assert N == 1 "StepHistogram only supports 1D data"
    label = h.normalization == :none ? "count" : string(h.normalization)
    labels = set(output.labels, N+1 => label)
    attributes = output.attributes
    default_plottype = Stairs
    plottype = Makie.plottype(input.plottype, default_plottype)
    return ProcessedLayer(output; plottype, labels, attributes)
end

stephistogram(; options...) = transformation(StepHistogramAnalysis(; options...))