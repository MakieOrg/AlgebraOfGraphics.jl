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

function _density(vs::Tuple, vs_orig::Tuple, transforms::Tuple; datalimits, npoints, kwargs...)
    k = _kde(vs; kwargs...)
    intervals = applydatalimits(datalimits, vs)
    rgs = map(intervals) do (min, max)
        return range(min, max; length = npoints)
    end
    res = pdf(k, rgs...)
    rgs_reapplied = ntuple(length(vs_orig)) do i
        from_transformed_numerical(collect(rgs[i]), vs_orig[i], transforms[i])
    end
    return (rgs_reapplied..., res)
end

function (d::DensityAnalysis)(input::ProcessedLayer)
    N = length(input.positional)
    direction = N == 1 ? (d.direction === automatic ? :x : d.direction) : nothing
    nd_plottype = N == 1 ? nothing : Makie.plottype(input.plottype, [Heatmap, Volume][N - 1])
    dimtransforms = ntuple(N) do i
        if N == 1
            positional_transform(input.axis_transforms, direction === :y ? AesY : AesX)
        else
            position_transform(input.axis_transforms, nd_plottype, input.attributes, N + 1, i)
        end
    end
    scales_active = !isempty(input.axis_transforms)
    datalimits = if d.datalimits === automatic
        defaultdatalimits(ntuple(i -> to_transformed_nested(dimtransforms[i], input.positional[i]), N))
    else
        forward_datalimits(_strip_datalimits_units(d.datalimits), dimtransforms)
    end
    options = valid_options(; datalimits, d.npoints, d.kernel, d.bandwidth)
    output = map(input) do p, n
        p, n = _drop_missing_nan_rows(p, n)
        pn = ntuple(i -> to_transformed_numerical(p[i], dimtransforms[i]), length(p))
        return _density(Tuple(pn), Tuple(p), dimtransforms; pairs(n)..., pairs(options)...), (;)
    end
    if N == 1
        labels_base = set(input.labels, N + 1 => "pdf")
        # When direction is :y, Lines reverses the positional arguments, so we need to swap labels 1 and 2
        labels_lines = if direction === :y
            label1 = get(labels_base, 1, nothing)
            label2 = get(labels_base, 2, nothing)
            _labels = copy(labels_base)
            delete!(_labels, 1)
            delete!(_labels, 2)
            if !isnothing(label1)
                insert!(_labels, 2, label1)
            end
            if !isnothing(label2)
                insert!(_labels, 1, label2)
            end
            _labels
        else
            labels_base
        end
        linelayer = ProcessedLayer(
            map(output) do p, n
                _p = direction === :x ? p : direction === :y ? reverse(p) : error("Invalid density direction $(repr(direction)), options are :x or :y")
                _p, n
            end, plottype = Lines, label = :line, labels = labels_lines
        )
        bandlayer = ProcessedLayer(
            map(output) do p, n
                (p[1], zero(p[2]), p[2]), n
            end; plottype = Band, label = :area, attributes = dictionary([:alpha => 0.15, :direction => direction]), labels = labels_base
        )
        return tag_scale_aesthetics(ProcessedLayers([bandlayer, linelayer]), scales_active)
    else
        d.direction === automatic || error("The direction = $(repr(d.direction)) keyword in a density analysis may only be set for the 1-dimensional case")
        labels = set(input.labels, N + 1 => "pdf")
        plottype = nd_plottype
        return tag_scale_aesthetics(ProcessedLayer(output; plottype, labels), scales_active)
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

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.
"""
density(; options...) = transformation(DensityAnalysis(; options...))
