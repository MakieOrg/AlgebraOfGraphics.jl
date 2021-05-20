const categoricalplottypes = [BarPlot, Heatmap, Volume]

to_weights(v) = weights(v)
to_weights(v::AbstractWeights) = v

function compute_edges(data, extrema, bins::Tuple{Vararg{Integer}}, closed)
    return map(extrema, bins) do (min, max), n
        histrange(min, max, n, closed)
    end
end
compute_edges(data, extrema, bins::Tuple{Vararg{AbstractArray}}, closed) = bins

function midpoints(edges::AbstractRange)
    min, s, l = minimum(edges), step(edges), length(edges)
    return range(min + s / 2, step=s, length=l - 1)
end

function _histogram(data...; bins=sturges(length(data[1])), weights=automatic,
    normalization=:none, extrema, closed=:left)

    bins_tuple = bins isa Tuple ? bins : map(_ -> bins, data)
    edges = compute_edges(data, extrema, bins_tuple, closed)
    w = weights === automatic ? () : (to_weights(weights),)
    h = fit(Histogram, data, w..., edges)
    return normalize(h, mode=normalization)
end

struct HistogramAnalysis
    options::Dict{Symbol, Any}
end

function (h::HistogramAnalysis)(le::Entry)
    options = copy(h.options)
    get!(options, :extrema) do
        return map(v -> mapreduce(extrema, extend_extrema, v), le.positional)
    end

    return splitapply(le) do entry
        hist = _histogram(entry.positional...; entry.named..., options...)
        normalization = get(options, :normalization, :none)
        N = length(entry.positional)
        labels, attributes = copy(entry.labels), copy(entry.attributes)
        labels[N + 1] = normalization == :none ? "count" : string(normalization)
        default_plottype = categoricalplottypes[N]
        plottype = Makie.plottype(entry.plottype, default_plottype)
        N == 1 && (attributes[:width] = step(hist.edges[1]))
        positional, named = (map(midpoints, hist.edges)..., hist.weights), (;)
        return Entry(entry; plottype, positional, named, labels, attributes)
    end
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
histogram(; options...) = Layer((HistogramAnalysis(Dict{Symbol, Any}(options)),))
