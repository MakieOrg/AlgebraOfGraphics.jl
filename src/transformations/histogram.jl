const categoricalplottypes = [BarPlot, Heatmap, Volume]

function compute_edges(intervals::Tuple, bins, closed)
    bs = bins isa Tuple ? bins : map(_ -> bins, intervals)
    return map(intervals, bs) do (min, max), b
        b isa AbstractVector && return b
        b isa Integer && return histrange(float(min), float(max), b, closed)
        msg = "Only AbstractVector and Integer or tuples thereof are accepted as bins"
        throw(ArgumentError(msg))
    end
end

function midpoints(edges::AbstractVector)
    i0, i1 = firstindex(edges), lastindex(edges)
    front, tail = view(edges, i0:i1-1), view(edges, i0+1:i1)
    return (front .+ tail) ./ 2
end

function midpoints(edges::AbstractRange)
    min, s, l = minimum(edges), step(edges), length(edges)
    return range(min + s / 2, step=s, length=l - 1)
end

function _histogram(vs::Tuple; bins=sturges(length(vs[1])), weights=automatic,
    normalization::Symbol, datalimits, closed::Symbol)

    intervals = applydatalimits(datalimits, vs)
    edges = compute_edges(intervals, bins, closed)
    h = if weights === automatic
        fit(Histogram, vs, edges)
    else
        fit(Histogram, vs, StatsBase.weights(weights), edges)
    end
    return normalize(h, mode=normalization)
end

Base.@kwdef struct HistogramAnalysis{D, B}
    datalimits::D=automatic
    bins::B=automatic
    closed::Symbol=:left
    normalization::Symbol=:none
    visual::Visual=Visual()
end

histogram_preprocess_named(::Type{<:Plot}, edges, weights) = (;)
histogram_preprocess_named(::Type{BarPlot}, edges, weights) = (; width=diff(first(edges)))
histogram_preprocess_positional(::Type{<:Plot}, edges, weights) = (map(midpoints, edges)..., weights)
function histogram_preprocess_positional(::Type{Stairs}, edges, weights)
    edges = only(edges)
    phantomedge = edges[end] # to bring step back to baseline
    edges = vcat(edges, phantomedge)
    z = zero(eltype(weights))
    heights = vcat(z, weights, z)
    return (edges, heights)
end
histogram_default_attributes(::Type{<:Plot}) = NamedArguments()
histogram_default_attributes(::Type{BarPlot}) = NamedArguments((; :gap => 0, :dodge_gap => 0))

function (h::HistogramAnalysis)(input::ProcessedLayer)
    datalimits = h.datalimits === automatic ? defaultdatalimits(input.positional) : h.datalimits
    options = valid_options(; datalimits, h.bins, h.closed, h.normalization)

    visual = h.visual
    N = length(input.positional)
    default_plottype = categoricalplottypes[N]
    plottype = Makie.plottype(visual.plottype, input.plottype, default_plottype)

    output = map(input) do p, n
        hist = _histogram(Tuple(p); pairs(n)..., pairs(options)...)
        edges, weights = hist.edges, hist.weights
        named = histogram_preprocess_named(plottype, edges, weights)
        positional = histogram_preprocess_positional(plottype, edges, weights)
        return positional, named
    end

    label = h.normalization == :none ? "count" : string(h.normalization)
    labels = set(output.labels, N+1 => label)
    attributes = merge(output.attributes, histogram_default_attributes(plottype))
    attributes = merge(attributes, visual.attributes)
    return ProcessedLayer(output; plottype, labels, attributes)
end

"""
    histogram(; bins=automatic, datalimits=automatic, closed=:left, normalization=:none, visual=automatic)

Compute a histogram.

The attribute `bins` can be an `Integer`, an `AbstractVector` (in particular, a range), or
a `Tuple` of either integers or abstract vectors (useful for 2- or 3-dimensional histograms).
When `bins` is an `Integer`, it denotes the approximate number of equal-width
intervals used to compute the histogram. In that case, the range covered by the
intervals is defined by `datalimits` (it defaults to the extrema of the whole data).
The keyword argument `datalimits` can be a tuple of two values, e.g. `datalimits=(0, 10)`,
or a function to be applied group by group, e.g. `datalimits=extrema`.
When `bins` is an `AbstractVector`, it denotes the intervals directly.

`closed` determines whether the the intervals are closed to the left or to the right.

The histogram can be normalized by setting `normalization`. Possible values are:
*  `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
   has norm 1 and represents a PDF.
* `:density`: Normalize by bin sizes only. Resulting histogram represents
   count density of input and does not have norm 1.
* `:probability`: Normalize by sum of weights only. Resulting histogram
   represents the fraction of probability mass for each bin and does not have
   norm 1.
*  `:none`: Do not normalize.

Weighted data is supported via the keyword `weights` (passed to `mapping`).

!!! note

    Normalizations are computed withing groups. For example, in the case of
    `normalization=:pdf`, sum of weights *within each group* will be equal to `1`.
"""
histogram(; options...) = transformation(HistogramAnalysis(; options...))
