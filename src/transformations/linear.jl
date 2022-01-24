Base.@kwdef struct LinearAnalysis{I}
    npoints::Int=200
    dropcollinear::Bool=false
    interval::I=automatic
    level::Float64=0.95
end

function add_intercept_column(x::AbstractVector{T}) where {T}
    mat = similar(x, float(T), (length(x), 2))
    fill!(view(mat, :, 1), 1)
    copyto!(view(mat, :, 2), x)
    return mat
end

# TODO: add multidimensional version
function (l::LinearAnalysis)(input::ProcessedLayer)
    output = map(input) do p, n
        x, y = p
        weights = get(n, :weights, similar(x, 0))
        default_interval = length(weights) > 0 ? nothing : :confidence
        interval = l.interval === automatic ? default_interval : l.interval
        # FIXME: handle collinear case gracefully
        lin_model = GLM.lm(add_intercept_column(x), y; wts=weights, l.dropcollinear)
        x̂ = range(extrema(x)..., length=l.npoints)
        pred = GLM.predict(lin_model, add_intercept_column(x̂); interval, l.level)
        return if !isnothing(interval)
            # TODO: fix this in GLM https://github.com/JuliaStats/GLM.jl/pull/467
            ŷ, lower, upper = map(vec, pred) # GLM prediction returns matrices
            (x̂, ŷ), (; lower, upper)
        else
            ŷ = pred
            (x̂, ŷ), (;)
        end
    end
    default_plottype = isempty(output.named) ? Lines : LinesFill
    plottype = Makie.plottype(output.plottype, default_plottype)
    return ProcessedLayer(output; plottype)
end

"""
    linear(; interval=automatic, level=0.95, dropcollinear=false, npoints=200)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `weights` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent,
for a given coverage `level` (the default `0.95` equates `alpha = 0.05`).
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
By default, this analysis errors on singular (collinear) data. To avoid that,
it is possible to set `dropcollinear=true`.
`npoints` is the number of points used by Makie to draw the line
"""
linear(; options...) = transformation(LinearAnalysis(; options...))