function hist2spec(h::Histogram{<:Any, N}) where N
    ptype = [:BarPlot, :Heatmap, :Volume][N]
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    return style(map(f, h.edges)..., Float64.(h.weights)) * spec(ptype; kwargs...)
end

to_weights(v) = weights(v)
to_weights(v::AbstractWeights) = v

function compute_edges(extrema, bins::Tuple{Vararg{Integer}}, closed)
    map(extrema, bins) do (min, max), n
        histrange(min, max, n, closed)
    end
end
compute_edges(extrema, bins::Tuple{Vararg{AbstractArray}}, closed) = bins

function _histogram(data...; bins = sturges(length(data[1])), wts = automatic,
    normalization = :none, extrema = map(extrema, data), closed = :left)

    bins_tuple = bins isa Tuple ? bins : map(_ -> bins, data)
    edges = compute_edges(extrema, bins_tuple, closed)
    weights = wts === automatic ? () : (to_weights(wts),)
    h = fit(Histogram, data, weights..., edges)
    hn = normalize(h, mode = normalization)
    return hist2spec(hn)
end

const histogram = Analysis(_histogram)

function global_options(::typeof(histogram), d::AlgebraicList)
    combine(extr1, extr2) = map(extr1, extr2) do (min1, max1), (min2, max2)
        min(min1, min2), max(max1, max2)
    end
    extr = mapfoldl(combine, d) do spec
        map(extrema, positional(spec.style.value))
    end
    return (extrema = extr,)
end