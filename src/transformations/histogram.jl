const categoricalplottypes = [BarPlot, Heatmap, Volume]

to_weights(v) = weights(v)
to_weights(v::AbstractWeights) = v

function compute_edges(extrema, bins::Tuple{Vararg{Integer}}, closed)
    return map(extrema, bins) do (min, max), n
        histrange(float(min), float(max), n, closed)
    end
end
compute_edges(extrema, bins::Tuple{Vararg{AbstractArray}}, closed) = bins

function midpoints(edges::AbstractRange)
    min, s, l = minimum(edges), step(edges), length(edges)
    return range(min + s / 2, step=s, length=l - 1)
end

function _histogram(data...; bins=sturges(length(data[1])), weights=automatic,
    normalization::Symbol=:none, extrema::Tuple, closed::Symbol=:left)

    bins_tuple = bins isa Tuple ? bins : map(_ -> bins, data)
    edges = compute_edges(extrema, bins_tuple, closed)
    w = weights === automatic ? () : (to_weights(weights),)
    h = fit(Histogram, data, w..., edges)
    return normalize(h, mode=normalization)
end

struct HistogramAnalysis
    options::NamedArguments
end

function (h::HistogramAnalysis)(le::Entry)
    extrema = get(h.options, :extrema) do
        return Tuple(map(v -> mapreduce(Base.extrema, extend_extrema, v), le.positional))
    end
    options = merge(h.options, NamedArguments((; extrema)))

    entry = map(le) do p, n
        hist = _histogram(p...; pairs(n)..., pairs(options)...)
        return (map(midpoints, hist.edges)..., hist.weights), (;)
    end

    N = length(le.positional)
    normalization = get(options, :normalization, :none)
    label = normalization == :none ? "count" : string(normalization)
    labels = merge(entry.labels, MixedArguments([N+1], [label]))
    attributes = if N == 1
        merge(entry.attributes, MixedArguments((dodge_gap=0, x_gap=0)))
    else
        entry.attributes
    end
    default_plottype = categoricalplottypes[N]
    plottype = Makie.plottype(entry.plottype, default_plottype)
    return Entry(entry; plottype, labels, attributes)
end

"""
    histogram(; bins=automatic, weights=automatic, normalization=:none)

Compute a histogram. `bins` can be an `Int` to create that
number of equal-width bins over the range of `values`.
Alternatively, it can be a sorted iterable of bin edges. The histogram
can be normalized by setting `normalization`. Possible values are:
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
histogram(; options...) = transformation(HistogramAnalysis(NamedArguments(options)))
