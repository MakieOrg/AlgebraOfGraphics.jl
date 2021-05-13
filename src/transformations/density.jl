struct DensityAnalysis
    options::Dict{Symbol, Any}
end
DensityAnalysis(; kwargs...) = DensityAnalysis(Dict{Symbol, Any}(kwargs))

# Work around lack of length 1 tuple method
# TODO: also add weights support here
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(i::Tuple, d) = i

function _density(data...; datalimits=extrema, npoints=200, kwargs...)
    k = _kde(data; kwargs...)
    es = applydatalimits(datalimits, data)
    rgs = map(e -> range(e...; length=npoints), es)
    res = pdf(k, rgs...)
    return (rgs..., res)
end

function (d::DensityAnalysis)(le::Entry)
    options = copy(d.options)
    get!(options, :datalimits) do
        return map(extrema, le.positional)
    end
    return splitapply(le) do entry
        N = length(entry.positional)
        positional, named = _density(entry.positional...; entry.named..., options...), (;)
        labels = copy(entry.labels)
        labels[N + 1] = "pdf"
        plottypes = [LinesFill, Heatmap, Volume]
        default_plottype = plottypes[N]
        plottype = AbstractPlotting.plottype(entry.plottype, default_plottype)
        return Entry(entry; plottype, positional, named, labels)
    end
end

"""
    density(; extrema, npoints, kernel, bandwidth)

Fit a kernel density estimation of `data`.
"""
density(; kwargs...) = Layer((DensityAnalysis(; kwargs...),))
