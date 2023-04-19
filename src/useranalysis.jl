histogram()

function (h::HistogramAnalysis)(input::ProcessedLayer)
    datalimits = h.datalimits === automatic ? defaultdatalimits(input.positional) : h.datalimits
    options = valid_options(; datalimits, h.bins, h.closed, h.normalization)

    output = map(input) do p, n
        hist = _histogram(Tuple(p); pairs(n)..., pairs(options)...)
        edges, weights = hist.edges, hist.weights
        named = length(edges) == 1 ? (; width=diff(first(edges))) : (;)
        return (map(midpoints, edges)..., weights), named
    end

    N = length(input.positional)
    label = h.normalization == :none ? "count" : string(h.normalization)
    labels = set(output.labels, N+1 => label)
    attributes = if N == 1
        set(output.attributes, :gap => 0, :dodge_gap => 0)
    else
        output.attributes
    end
    default_plottype = categoricalplottypes[N]
    plottype = Makie.plottype(output.plottype, default_plottype)
    return ProcessedLayer(output; plottype, labels, attributes)
end

### We do it right now

struct UserAnalysis
    groupcomputation
    custom_attributes
    labels
    attributes
    plottype
end

function (ua::UserAnalysis)(input::ProcessedLayer)
    scales = defaultdatalimits(input.positional)
    output = map(input) do positional, named
        return ua.f(positional, named; scales, ua.custom_attributes)
    end
    output.labels = merge(output.labels, ua.labels)
    output.attributes = merge(output.attributes, ua.attributes)
    output.plottype = Makie.plottype(output.plottype, ua.plottype)
    return output
end

### The developer does it

function histogram_computation(positional, named; scales, custom_attributes)
    # The user creates the function
    bins = range(scales, 200)
    hist = _histogram(positional...; bins=bins)
    edges, weights = hist.edges, hist.weights
    named = length(edges) == 1 ? (; width=diff(first(edges))) : (;)
    return map(midpoints, edges)..., weights), named 
end

function myhistogram(; custom_attributes)
    labels = ["count"]
    attributes = (dodge_gap = 0, x_gap = 0)
    plottype = BarPlot
    return UserAnalysis(histogram_computation, custom_attributes, labels, attributes, plottype)
end

analysis = UserAnalysis(histogram_computation, labels="")

### The end user does it

myhistogram(normalization=:none)


