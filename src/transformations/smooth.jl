Base.@kwdef struct SmoothAnalysis
    npoints::Int = 200
    span::Float64 = 0.75
    degree::Int = 2
    interval::Union{Symbol, Nothing} = :confidence
    level::Float64 = 0.95
end

# Loess loses precision when x lives far from 0 or spans a large magnitude (e.g.
# `datetime2float(Date)` is ~1e11 and a multi-day range is ~1e9): the degree-2 normal equations
# then mix terms differing by ~1e18 and the local fit is ill-conditioned, collapsing the prediction.
# Standardize x (center on the mean, scale by the standard deviation) before fitting. For continuous
# x this leaves predictions unchanged to machine precision; with few distinct x values Loess's
# kd-tree becomes mildly scale-sensitive, shifting predictions by a fraction of a percent.
function _standardize(xn)
    offset = sum(xn) / length(xn)
    centered = xn .- offset
    scale = sqrt(sum(abs2, centered) / length(centered))
    scale = iszero(scale) ? one(scale) : scale
    return centered ./ scale, offset, scale
end

function (l::SmoothAnalysis)(input::ProcessedLayer)
    tx = position_transform(input.axis_transforms, Lines, input.attributes, 2, 1)
    ty = position_transform(input.axis_transforms, Lines, input.attributes, 2, 2)
    scales_active = !isempty(input.axis_transforms)
    if isnothing(l.interval)
        output = map(input) do p, n
            p, _ = _drop_missing_nan_rows(p, n)
            x, y = p
            xn = to_transformed_numerical(x, tx)
            yn = to_transformed_numerical(y, ty)
            xn_s, x_offset, x_scale = _standardize(xn)
            model = Loess.loess(xn_s, yn; l.span, l.degree)
            x̂n = collect(range(extrema(xn)..., length = l.npoints))
            ŷn = Loess.predict(model, (x̂n .- x_offset) ./ x_scale)
            x̂ = from_transformed_numerical(x̂n, x, tx)
            ŷ = from_transformed_numerical(ŷn, y, ty)
            return (x̂, ŷ), (;)
        end
        plottype = Makie.plottype(output.plottype, Lines)
        return tag_scale_aesthetics(ProcessedLayer(output; plottype, label = :prediction), scales_active)
    else
        output = map(input) do p, n
            p, _ = _drop_missing_nan_rows(p, n)
            x, y = p
            xn = to_transformed_numerical(x, tx)
            yn = to_transformed_numerical(y, ty)
            xn_s, x_offset, x_scale = _standardize(xn)
            model = Loess.loess(xn_s, yn; l.span, l.degree)
            x̂n = collect(range(extrema(xn)..., length = l.npoints))
            pred = Loess.predict(model, (x̂n .- x_offset) ./ x_scale; interval = l.interval, level = l.level)
            ŷ = from_transformed_numerical(pred.predictions, y, ty)
            lower = from_transformed_numerical(pred.lower, y, ty)
            upper = from_transformed_numerical(pred.upper, y, ty)
            x̂ = from_transformed_numerical(x̂n, x, tx)
            return (x̂, ŷ, x̂, lower, upper), (;)
        end

        lineslayer = ProcessedLayer(
            map(output) do p, n
                x̂, ŷ, x, lower, upper = p
                (x̂, ŷ), (;)
            end, plottype = Lines, label = :prediction
        )

        bandlayer = ProcessedLayer(
            map(output) do p, n
                x̂, ŷ, x, lower, upper = p
                (x, lower, upper), (;)
            end, plottype = Band, label = :ci, attributes = dictionary([:alpha => 0.15])
        )

        return tag_scale_aesthetics(ProcessedLayers([bandlayer, lineslayer]), scales_active)
    end
end

"""
    smooth(; span=0.75, degree=2, interval=:confidence, level=0.95, npoints=200)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting.
`degree` is the polynomial degree used in the loess model.
Use `interval` to specify what type of interval the shaded band should represent,
for a given coverage `level` (the default `0.95` equates `alpha = 0.05`).
Valid values of `interval` are `:confidence` (the default), to delimit the uncertainty
of the predicted relationship. Use `interval = nothing` to only compute the line fit,
without any uncertainty estimate.
`npoints` is the number of points used by Makie to draw the line and shaded band.

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.

This transformation creates two `ProcessedLayer`s labelled `:prediction` and `:ci`, which can be styled separately with `[subvisual](@ref)`.
"""
smooth(; options...) = transformation(SmoothAnalysis(; options...))
