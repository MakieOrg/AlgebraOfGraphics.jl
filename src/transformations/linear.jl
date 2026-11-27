Base.@kwdef struct LinearAnalysis{I}
    npoints::Int = 200
    dropcollinear::Bool = false
    interval::I = automatic
    level::Float64 = 0.95
end

function add_intercept_column(x::AbstractVector{T}) where {T}
    mat = similar(x, float(T), (length(x), 2))
    fill!(view(mat, :, 1), 1)
    copyto!(view(mat, :, 2), x)
    return mat
end

# TODO: add multidimensional version
function (l::LinearAnalysis)(input::ProcessedLayer)
    tx = position_transform(input.axis_transforms, Lines, input.attributes, 2, 1)
    ty = position_transform(input.axis_transforms, Lines, input.attributes, 2, 2)
    scales_active = !isempty(input.axis_transforms)
    output = map(input) do p, n
        p, n = _drop_missing_nan_rows(p, n)
        x, y = p
        xn = to_transformed_numerical(x, tx)
        yn = to_transformed_numerical(y, ty)
        weights_raw = get(n, :weights, similar(xn, 0))
        weights = StatsBase.fweights(to_unitless_numerical(weights_raw))
        default_interval = length(weights) > 0 ? nothing : :confidence
        interval = l.interval === automatic ? default_interval : l.interval
        # FIXME: handle collinear case gracefully
        lin_model = GLM.lm(add_intercept_column(xn), yn; weights, l.dropcollinear)
        x̂n = collect(range(extrema(xn)..., length = l.npoints))
        pred = GLM.predict(lin_model, add_intercept_column(x̂n); interval, l.level)
        x̂ = from_transformed_numerical(x̂n, x, tx)
        return if !isnothing(interval)
            ŷn, lowern, uppern = pred
            ŷ = from_transformed_numerical(ŷn, y, ty)
            lower = from_transformed_numerical(lowern, y, ty)
            upper = from_transformed_numerical(uppern, y, ty)
            (x̂, ŷ, x̂, lower, upper), (;)
        else
            ŷ = from_transformed_numerical(pred, y, ty)
            (x̂, ŷ, empty(x̂), empty(ŷ), empty(ŷ)), (;)
        end
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

"""
    linear(; interval=automatic, level=0.95, dropcollinear=false, npoints=200)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `weights` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent,
for a given coverage `level` (the default `0.95` equates `alpha = 0.05`).
Valid values of `interval` are `:confidence`, to delimit the uncertainty of the predicted
relationship, and `:prediction`, to delimit estimated bounds for new data points.
Use `interval = nothing` to only compute the line fit, without any uncertainty estimate.
By default, this analysis errors on singular (collinear) data. To avoid that,
it is possible to set `dropcollinear=true`.
`npoints` is the number of points used by Makie to draw the shaded band.

Weighted data is supported via the keyword `weights` (passed to `mapping`).

Rows with `missing` or `NaN` in any numeric input are dropped; `Inf`/`-Inf` errors.

This transformation creates two `ProcessedLayer`s labelled `:prediction` and `:ci`, which can be styled separately with `[subvisual](@ref)`.
"""
linear(; options...) = transformation(LinearAnalysis(; options...))
