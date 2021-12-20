struct DensityAnalysis
    options::Dict{Symbol, Any}
end
DensityAnalysis(; kwargs...) = DensityAnalysis(Dict{Symbol, Any}(kwargs))

# Work around lack of length 1 tuple method
# TODO: also add weights support here
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(i::Union{AbstractArray, Tuple}, _) = i

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
        return map(v -> mapreduce(extrema, extend_extrema, v), le.positional)
    end
    entry = map(le) do p, n
        return _density(p...; pairs(n)..., options...), (;)
    end
    N = length(le.positional)
    labels = copy(le.labels)
    labels[N + 1] = "pdf"
    plottypes = [LinesFill, Heatmap, Volume]
    default_plottype = plottypes[N]
    plottype = Makie.plottype(le.plottype, default_plottype)
    return Entry(entry; plottype, labels)
end

"""
    density(; datalimits, npoints, kernel, bandwidth)

Fit a kernel density estimation of `data`.
Here, `datalimits` specifies the range for which the density should be calculated, `npoints`
is the number of points used by Makie to draw the line and `kernel` and `bandwidth` are
forwarded to `KernelDensity.kde`.
"""
density(; kwargs...) = transformation(DensityAnalysis(; kwargs...))
