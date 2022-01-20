const categoricalplottypes = [BarPlot, Heatmap, Volume]

function compute_edges(intervals::Tuple, bins, closed)
    bs = bins isa Tuple ? bins : map(_ -> bins, intervals)
    return map(intervals, bs) do (min, max), b
        b isa AbstractVector && return b
        b isa Integer && return histrange(float(min), float(max), b, closed)
        msg = "only AbstractVector and Integer or tuples thereof are accepted as bins"
        throw(ArgumentError(msg))
    end
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
end

function (h::HistogramAnalysis)(input::ProcessedLayer)
    datalimits = h.datalimits === automatic ? defaultdatalimits(input.positional) : h.datalimits
    options = valid_options(; datalimits, h.bins, h.closed, h.normalization)

    output = map(input) do p, n
        hist = _histogram(Tuple(p); pairs(n)..., pairs(options)...)
        return (map(midpoints, hist.edges)..., hist.weights), (;)
    end

    N = length(input.positional)
    label = h.normalization == :none ? "count" : string(h.normalization)
    labels = set(output.labels, N+1 => label)
    attributes = if N == 1
        set(output.attributes, :dodge_gap => 0, :x_gap => 0)
    else
        output.attributes
    end
    default_plottype = categoricalplottypes[N]
    plottype = Makie.plottype(output.plottype, default_plottype)
    return ProcessedLayer(output; plottype, labels, attributes)
end

"""
    histogram(; bins=automatic, datalimits=automatic, closed=:left, normalization=:none)

Compute a histogram. `bins` can be an `Int` to create that
number of equal-width bins over the range of `values`. In that case, the range covered
by the `bins` is defined by `datalimits` (defaults to the extrema of the data).
Alternatively, `bins` can be a sorted iterable of bin edges.
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
Weighted data is supported via the keyword `weights`.

!!! note

    Normalizations are computed withing groups. For example, in the case of
    `normalization=:pdf`, sum of weights *within each group* will be equal to `1`.
"""
histogram(; options...) = transformation(HistogramAnalysis(; options...))
