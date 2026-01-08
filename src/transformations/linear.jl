Base.@kwdef struct LinearAnalysis{I}
    npoints::Int = 200
    dropcollinear::Bool = false
    interval::I = automatic
    level::Float64 = 0.95
    weighttype::Symbol = :fweights
    weighttransform = identity
    distr::GLM.Distribution = GLM.Normal()
end

function add_intercept_column(x::AbstractVector{T}) where {T}
    mat = similar(x, float(T), (length(x), 2))
    fill!(view(mat, :, 1), 1)
    copyto!(view(mat, :, 2), x)
    return mat
end

function get_weighttype(s::Symbol)
    weighttype = if s == :fweights
        StatsBase.fweights
    else
        throw(ArgumentError("Currently, GLM.jl only supports `StatsBase.fweights`."))
    end

    # TODO: Uncomment when GLM v2.0 is released
    #weighttype = if s == :aweights
    #    StatsBase.aweights
    #elseif s == :pweights
    #    StatsBase.pweights
    #elseif s == :fweights
    #    StatsBase.fweights
    #else
    #    throw(ArgumentError("Currently, GLM.jl only supports `aweights`, `pweights`, and `fweights`."))
    #end

    return weighttype
end

# TODO: add multidimensional version
function (l::LinearAnalysis)(input::ProcessedLayer)
    output = map(input) do p, n
        x, y = p
        weights = (get_weighttype(l.weighttype) ∘ l.weighttransform)(get(n, :weights, similar(x, 0)))
        default_interval = length(weights) > 0 ? :confidence : nothing
        interval = l.interval === automatic ? default_interval : l.interval
        # FIXME: handle collinear case gracefully
        lin_model = if isempty(weights)
            GLM.lm(add_intercept_column(x), y; l.dropcollinear)
        else
            GLM.glm(add_intercept_column(x), y, l.distr; wts = weights, l.dropcollinear)
        end
        x̂ = range(extrema(x)..., length = l.npoints)
        pred = GLM.predict(lin_model, add_intercept_column(x̂); interval, l.level)
        return if !isnothing(interval)
            ŷ, lower, upper = pred
            (x̂, ŷ, x̂, lower, upper), (;)
        else
            ŷ = pred
            (x̂, ŷ, empty(x̂), empty(ŷ), empty(ŷ)), (;)
        end
    end

    lineslayer = ProcessedLayer(
        map(output) do p, n
            x̂, ŷ, x, lower, upper = p
            (x̂, ŷ), (;)
        end, plottype = Lines, label = :prediction
    )

    bandlayer = ProcessedLayer(
        map(output) do p, n
            x̂, ŷ, x, lower, upper = p
            (x, lower, upper), (;)
        end, plottype = Band, label = :ci, attributes = dictionary([:alpha => 0.15])
    )

    return ProcessedLayers([bandlayer, lineslayer])
end

"""
    linear(; interval=automatic, level=0.95, dropcollinear=false, npoints=200, weighttype=:fweights, weighttransform=identity, distr=GLM.Normal())

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
Additional weight support is provided via the `weighttype`, `weighttransform`, and `distr` keywords.
`weightype` specifies the `StatsBase.AbstractWeights` type to use.
`weighttransform` accepts an optional function to transform the weights before they are passed to `GLM.glm`.
`distr` is forwarded to `GLM.glm`.
See the GLM.jl documentation for more on working with weighted data.

This transformation creates two `ProcessedLayer`s labelled `:prediction` and `:ci`, which can be styled separately with `[subvisual](@ref)`.
"""
linear(; options...) = transformation(LinearAnalysis(; options...))
