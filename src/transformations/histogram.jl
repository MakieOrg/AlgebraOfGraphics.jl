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

function _histogram(data...; bins=sturges(length(data[1])), wts=automatic,
    normalization=:none, extrema, closed=:left)

    bins_tuple = bins isa Tuple ? bins : map(_ -> bins, data)
    edges = compute_edges(data, extrema, bins_tuple, closed)
    weights = wts === automatic ? () : (to_weights(wts),)
    h = fit(Histogram, data, weights..., edges)
    return normalize(h, mode=normalization)
end

struct HistogramAnalysis
    options::Dict{Symbol, Any}
end

function (h::HistogramAnalysis)(le::Entry)
    summaries = map(summary∘getvalue, le.mappings.positional)
    extrema = get(h.options, :extrema, Tuple(summaries))
    options = merge(h.options, pairs((; extrema)))

    return splitapply(le) do entry
        labels, mappings = map(getlabel, entry.mappings), map(getvalue, entry.mappings)
        hist = _histogram(mappings.positional...; mappings.named..., options...)
        normalization = get(options, :normalization, :none)
        newlabel = normalization == :none ? "count" : string(normalization)
        N = length(mappings.positional)
        default_plottype = categoricalplottypes[N]
        kwargs = N == 1 ? (width=step(hist.edges[1]), x_gap=0, dodge_gap=0) : (;)
        labeled_result = map(
            Labeled,
            vcat(labels.positional, newlabel),
            (map(midpoints, hist.edges)..., hist.weights)
        )
        return Entry(
            AbstractPlotting.plottype(entry.plottype, default_plottype),
            Arguments(labeled_result),
            merge(entry.attributes, pairs(kwargs))
        )
    end
end


"""
    histogram(; bins=automatic, wts=automatic, normalization=:none)

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
Weighted data is supported via the keyword `wts`.

!!! note

    Normalizations are computed withing groups. For example, in the case of
    `normalization=:pdf`, sum of weights *within each group* will be equal to `1`.
"""
histogram(; options...) = Layer((HistogramAnalysis(Dict{Symbol, Any}(options)),))
