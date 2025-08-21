Base.@kwdef struct DensityAnalysis{D, K, B}
    datalimits::D = automatic
    npoints::Int = 200
    kernel::K = automatic
    bandwidth::B = automatic
    direction::Union{Makie.Automatic, Symbol} = automatic
end

# Work around lack of length 1 tuple method
_kde(data::NTuple{1, Any}; kwargs...) = kde(data...; kwargs...)
_kde(data::Tuple; kwargs...) = kde(data; kwargs...)

defaultdatalimits(positional) = map(nested_extrema_finite, Tuple(positional))

applydatalimits(f::Function, d) = map(f, d)
applydatalimits(limits::Tuple{Real, Real}, d) = map(_ -> limits, d)
applydatalimits(limits::Tuple, _) = limits

function _density(vs::Tuple; datalimits, npoints, kwargs...)
    k = _kde(vs; kwargs...)
    intervals = applydatalimits(datalimits, vs)
    rgs = map(intervals) do (min, max)
        return range(min, max; length = npoints)
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
    if N == 1
        direction = d.direction === automatic ? :x : d.direction
        linelayer = ProcessedLayer(
            map(output) do p, n
                _p = direction === :x ? p : direction === :y ? reverse(p) : error("Invalid density direction $(repr(direction)), options are :x or :y")
                _p, n
            end, plottype = Lines, label = :line
        )
        bandlayer = ProcessedLayer(
            map(output) do p, n
                (p[1], zero(p[2]), p[2]), n
            end; plottype = Band, label = :area, attributes = dictionary([:alpha => 0.15, :direction => direction])
        )
        return ProcessedLayers([bandlayer, linelayer])
    else
        d.direction === automatic || error("The direction = $(repr(d.direction)) keyword in a density analysis may only be set for the 1-dimensional case")
        labels = set(input.labels, N + 1 => "pdf")
        default_plottype = [Heatmap, Volume][N - 1]
        plottype = Makie.plottype(input.plottype, default_plottype)
        return ProcessedLayer(output; plottype, labels)
    end
end

"""
    density(; datalimits=automatic, kernel=automatic, bandwidth=automatic, npoints=200, direction=automatic)

Fit a kernel density estimation of `data`.

Here, `datalimits` specifies the range for which the density should be calculated
(it defaults to the extrema of the whole data).
The keyword argument `datalimits` can be a tuple of two values, e.g. `datalimits=(0, 10)`,
or a function to be applied group by group, e.g. `datalimits=extrema`.
The keyword arguments `kernel` and `bandwidth` are forwarded to `KernelDensity.kde`.
`npoints` is the number of points used by Makie to draw the line

Weighted data is supported via the keyword `weights` (passed to `mapping`).

For 1D, returns two layers, a `Band` with label `:area` and a `Lines` with label `:line`
which you can separately style using [`subvisual`](@ref). The direction may be changed to
vertical via `direction = :y`.

For 2D, returns a `Heatmap` and for 3D a `Volume` layer.
"""
density(; options...) = transformation(DensityAnalysis(; options...))
