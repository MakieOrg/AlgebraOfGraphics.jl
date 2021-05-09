struct DensityAnalysis
    options::Dict{Symbol, Any}
end
DensityAnalysis(; kwargs...) = DensityAnalysis(Dict{Symbol, Any}(kwargs))

# Work around lack of length 1 tuple method
# TODO: also add weights support here
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

function _density(data...; extrema, npoints=200, kwargs...)
    k = _kde(data; kwargs...)
    rgs = map(e -> range(e...; length=npoints), extrema)
    res = pdf(k, rgs...)
    return (rgs..., res)
end

function (d::DensityAnalysis)(le::Entry)
    summaries = map(summary∘getvalue, le.mappings.positional)
    extrema = get(d.options, :extrema, Tuple(summaries))
    options = merge(d.options, pairs((; extrema)))
    return splitapply(le) do entry
        labels, mappings = map(getlabel, entry.mappings), map(getvalue, entry.mappings)
        result = _density(mappings.positional...; mappings.named..., options...)
        labeled_result = map(Labeled, vcat(labels.positional, "pdf"), collect(result))
        plottypes = [LinesFill, Heatmap, Volume]
        default_plottype = plottypes[length(mappings.positional)]
        return Entry(
            AbstractPlotting.plottype(entry.plottype, default_plottype),
            Arguments(labeled_result),
            entry.attributes
        )
    end
end

"""
    density(; extrema, npoints, kernel, bandwidth)

Fit a kernel density estimation of `data`.
"""
density(; kwargs...) = Layer((DensityAnalysis(; kwargs...),))
