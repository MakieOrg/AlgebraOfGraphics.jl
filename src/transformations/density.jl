Base.@kwdef struct DensityAnalysis{D, K, B}
    datalimits::D=automatic
    npoints::Int=200
    kernel::K=automatic
    bandwidth::B=automatic
end

# Work around lack of length 1 tuple method
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

defaultdatalimits(positional) = map(nested_extrema_finite, Tuple(positional))

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(limits::Tuple, _) = limits

function _density(vs::Tuple; datalimits, npoints, kwargs...)
    k = _kde(vs; kwargs...)
    intervals = applydatalimits(datalimits, vs)
    rgs = map(intervals) do (min, max)
        return range(min, max; length=npoints)
    end
    res = pdf(k, rgs...)
    return (rgs..., res)
end

function (d::DensityAnalysis)(input::ProcessedLayer)
    datalimits = d.datalimits === automatic ? defaultdatalimits(input.positional) : d.datalimits
    options = valid_options(; datalimits, d.npoints, d.kernel, d.bandwidth)
    output = map(input) do p, n
        return _density(Tuple(p); pairs(n)..., pairs(options)...), (;)
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

Here, `datalimits` specifies the range for which the density should be calculated
(it defaults to the extrema of the whole data).
The keyword argument `datalimits` can be a tuple of two values, e.g. `datalimits=(0, 10)`,
or a function to be applied group by group, e.g. `datalimits=extrema`.
The keyword arguments `kernel` and `bandwidth` are forwarded to `KernelDensity.kde`.
`npoints` is the number of points used by Makie to draw the line

Weighted data is supported via the keyword `weights` (passed to `mapping`).
"""
density(; options...) = transformation(DensityAnalysis(; options...))
