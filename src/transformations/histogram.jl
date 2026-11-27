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
    front, tail = view(edges, i0:(i1 - 1)), view(edges, (i0 + 1):i1)
    return (front .+ tail) ./ 2
end

function midpoints(edges::AbstractRange)
    min, s, l = minimum(edges), step(edges), length(edges)
    return range(min + s / 2, step = s, length = l - 1)
end

function _histogram(
        vs::Tuple; bins = sturges(length(vs[1])), weights = automatic,
        normalization::Symbol, datalimits, closed::Symbol
    )

    intervals = applydatalimits(datalimits, vs)
    edges = compute_edges(intervals, bins, closed)
    h = if weights === automatic
        fit(Histogram, vs, edges)
    else
        fit(Histogram, vs, StatsBase.weights(weights), edges)
    end
    return normalize(h, mode = normalization)
end

struct HistogramAnalysis{plottype <: Plot, D, B}
    direction::Union{Automatic, Symbol}
    datalimits::D
    bins::B
    closed::Symbol
    normalization::Symbol
end

function HistogramAnalysis{plottype}(;
        direction::Union{Automatic, Symbol} = automatic,
        datalimits::D = automatic,
        bins::B = automatic,
        closed::Symbol = :left,
        normalization::Symbol = :none,
    ) where {plottype <: Plot, D, B}
    return HistogramAnalysis{plottype, D, B}(direction, datalimits, bins, closed, normalization)
end
HistogramAnalysis(; options...) = HistogramAnalysis{Plot{plot}}(; options...)

histogram_preprocess_named(::Type{<:Plot}, edges, weights, p) = (;)
histogram_preprocess_named(::Type{BarPlot}, edges, weights, p) = (; width = from_unitless_numerical(diff(first(edges)), p[1]))
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

function (h::HistogramAnalysis{_plottype})(input::ProcessedLayer) where {_plottype}
    N = length(input.positional)
    default_plottype = categoricalplottypes[N]
    plottype = Makie.plottype(_plottype, input.plottype, default_plottype)

    h.direction === automatic || N == 1 || error("The direction = $(repr(h.direction)) keyword in a histogram analysis may only be set for the 1-dimensional case")
    binning_attributes = h.direction === automatic ? input.attributes : merge(input.attributes, dictionary([:direction => h.direction]))

    dimtransforms = ntuple(i -> position_transform(input.axis_transforms, plottype, binning_attributes, N + 1, i), N)
    datalimits = if h.datalimits === automatic
        defaultdatalimits(ntuple(i -> to_transformed_nested(dimtransforms[i], input.positional[i]), N))
    else
        forward_datalimits(_strip_datalimits_units(h.datalimits), dimtransforms)
    end
    options = valid_options(; datalimits, h.bins, h.closed, h.normalization)

    output = map(input) do p, n
        p, n = _drop_missing_nan_rows(p, n)
        pn = ntuple(i -> to_transformed_numerical(p[i], dimtransforms[i]), length(p))
        hist = _histogram(Tuple(pn); pairs(n)..., pairs(options)...)
        weights = hist.weights
        edges = ntuple(length(hist.edges)) do i
            t = dimtransforms[i]
            t === nothing ? hist.edges[i] : apply_scale_inverse(t, collect(hist.edges[i]))
        end
        named = histogram_preprocess_named(plottype, edges, weights, p)
        positional = histogram_preprocess_positional(plottype, edges, weights)
        positional = ntuple(length(positional)) do i
            i <= length(p) ? from_unitless_numerical(collect(positional[i]), p[i]) : positional[i]
        end
        return positional, named
    end

    label = h.normalization == :none ? "count" : string(h.normalization)
    labels = set(output.labels, N + 1 => label)
    attributes = merge(binning_attributes, histogram_default_attributes(plottype))
    scales_active = !isempty(input.axis_transforms)
    return tag_scale_aesthetics(ProcessedLayer(output; plottype, labels, attributes), scales_active)
end

"""
    histogram(plottype::Type{<:Plot} = Plot{plot}; bins=automatic, datalimits=automatic, closed=:left, normalization=:none, direction=automatic)

Compute a histogram.

A plot type can be passed as the first argument controlling the type of plot the histogram
is displayed as, e.g. `histogram(Stairs)` creates a stephist. The default plot type for
1-dimensional histograms is `BarPlot`, `Heatmap` for 2d, and `Volume` for 3d histograms.

For a 1-dimensional histogram, `direction` (`:x` or `:y`) sets the orientation of the bars.
With `direction = :y` the binned variable is placed on the `Y` aesthetic, which also determines
the scale space the bins are computed in when a `scale` is set via `scales` (e.g. `scales(Y = (; scale = log10))`).

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

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.

!!! note

    Normalizations are computed withing groups. For example, in the case of
    `normalization=:pdf`, sum of weights *within each group* will be equal to `1`.

"""
histogram(plottype::Type{<:Plot} = Plot{plot}; options...) = transformation(HistogramAnalysis{plottype}(; options...))
