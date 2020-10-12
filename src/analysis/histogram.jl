function hist2spec(h::Histogram{<:Any, N}) where N
    ptype = [:BarPlot, :Heatmap, :Volume][N]
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    return mapping(map(f, h.edges)..., Float64.(h.weights)) * visual(ptype; kwargs...)
end

to_weights(v) = weights(v)
to_weights(v::AbstractWeights) = v

function trim(range, min, max, closed)
    if closed == :left
        i1 = searchsortedlast(range, min)
        i2 = searchsortedfirst(range, nextfloat(max))
    else
        i1 = searchsortedlast(range, prevfloat(min))
        i2 = searchsortedfirst(range, max)
    end
    return range[i1:i2]
end

function compute_edges(data, extrema, bins::Tuple{Vararg{Integer}}, closed)
    ranges = map(extrema, bins) do (min, max), n
        histrange(min, max, n, closed)
    end
    # trim axis
    map(ranges, data) do range, d
        trim(range, Base.extrema(d)..., closed)
    end
end
compute_edges(data, extrema, bins::Tuple{Vararg{AbstractArray}}, closed) = bins

function _histogram(data...; bins = sturges(length(data[1])), wts = automatic,
    normalization = :none, extrema = map(extrema, data), closed = :left)

    bins_tuple = bins isa Tuple ? bins : map(_ -> bins, data)
    edges = compute_edges(data, extrema, bins_tuple, closed)
    weights = wts === automatic ? () : (to_weights(wts),)
    h = fit(Histogram, data, weights..., edges)
    hn = normalize(h, mode = normalization)
    return hist2spec(hn)
end

"""
    histogram(data...; bins = automatic, wts = automatic, normalization = :none)

Plot a histogram of `values`. `bins` can be an `Int` to create that
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
"""
const histogram = Analysis(_histogram)

function global_options(::typeof(histogram), d::AlgebraicList)
    combine(extr1, extr2) = map(extr1, extr2) do (min1, max1), (min2, max2)
        min(min1, min2), max(max1, max2)
    end
    extr = mapfoldl(combine, d) do spec
        map(extrema, positional(spec.mapping.value))
    end
    return (extrema = extr,)
end