Base.@kwdef struct DensityAnalysis{D, K, B}
    datalimits::D=automatic
    npoints::Int=200
    kernel::K=automatic
    bandwidth::B=automatic
end

# Work around lack of length 1 tuple method
# TODO: also add weights support here
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

function compute_datalimits(positional, datalimits)
    return if datalimits === automatic
        map(v -> mapreduce(extrema, extend_extrema, v), Tuple(positional))
    else
        datalimits
    end
end

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(limits::Union{AbstractArray, Tuple}, _) = limits

function _density(data...; datalimits, npoints, kwargs...)
    k = _kde(data; kwargs...)
    es = applydatalimits(datalimits, data)
    rgs = map(e -> range(e...; length=npoints), es)
    res = pdf(k, rgs...)
    return (rgs..., res)
end

function (d::DensityAnalysis)(le::Entry)
    datalimits = compute_datalimits(le.positional, d.datalimits)
    options = valid_options((; datalimits, d.npoints, d.kernel, d.bandwidth))
    entry = map(le) do p, n
        return _density(p...; pairs(n)..., pairs(options)...), (;)
    end
    N = length(le.positional)
    labels = set(le.labels, N+1 => "pdf")
    plottypes = [LinesFill, Heatmap, Volume]
    default_plottype = plottypes[N]
    plottype = Makie.plottype(le.plottype, default_plottype)
    return Entry(entry; plottype, labels)
end

"""
    density(; datalimits=automatic, npoints=200, kernel=automatic, bandwidth=automatic)

Fit a kernel density estimation of `data`.
Here, `datalimits` specifies the range for which the density should be calculated, `npoints`
is the number of points used by Makie to draw the line and `kernel` and `bandwidth` are
forwarded to `KernelDensity.kde`.
"""
density(; options...) = transformation(DensityAnalysis(; options...))
