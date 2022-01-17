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

defaultdatalimits(positional) = map(v -> mapreduce(extrema, extend_extrema, v), Tuple(positional))

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(limits::Union{AbstractArray, Tuple}, _) = limits

function _density(vs...; datalimits, npoints, kwargs...)
    k = _kde(vs; kwargs...)
    es = applydatalimits(datalimits, vs)
    rgs = map(e -> range(e...; length=npoints), es)
    res = pdf(k, rgs...)
    return (rgs..., res)
end

function (d::DensityAnalysis)(input::ProcessedLayer)
    datalimits = d.datalimits === automatic ? defaultdatalimits(input.positional) : d.datalimits
    options = valid_options(; datalimits, d.npoints, d.kernel, d.bandwidth)
    output = map(input) do p, n
        return _density(p...; pairs(n)..., pairs(options)...), (;)
    end
    N = length(input.positional)
    labels = set(input.labels, N+1 => "pdf")
    plottypes = [LinesFill, Heatmap, Volume]
    default_plottype = plottypes[N]
    plottype = Makie.plottype(input.plottype, default_plottype)
    return ProcessedLayer(output; plottype, labels)
end

"""
    density(; datalimits=automatic, kernel=automatic, bandwidth=automatic, npoints=200)

Fit a kernel density estimation of `data`.
Here, `datalimits` specifies the range for which the density should be calculated,
and `kernel` and `bandwidth` are forwarded to `KernelDensity.kde`.
`npoints` is the number of points used by Makie to draw the line
"""
density(; options...) = transformation(DensityAnalysis(; options...))
