Base.@kwdef struct LinearAnalysis{I}
    npoints::Int=200
    dropcollinear::Bool=false
    interval::I=automatic
    level::Float64=0.95
    degree::Int=1
end

function make_design_matrix(x::AbstractVector{T}, d::Int) where {T}
    mat = similar(x, float(T), (length(x), d+1))
    fill!(view(mat, :, 1), 1)
    for i in 1:d
        copyto!(view(mat, :, i+1), x .^ i)
    end
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
        lin_model = GLM.lm(make_design_matrix(x, l.degree), y; wts=weights, l.dropcollinear)
        x̂ = range(extrema(x)..., length=l.npoints)
        pred = GLM.predict(lin_model, make_design_matrix(x̂, l.degree); interval, l.level)
        return if !isnothing(interval)
            ŷ, lower, upper = pred
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
Valid values of `interval` are `:confidence`, to delimit the uncertainty of the predicted
relationship, and `:prediction`, to delimit estimated bounds for new data points.
Use `interval = nothing` to only compute the line fit, without any uncertainty estimate. 
By default, this analysis errors on singular (collinear) data. To avoid that,
it is possible to set `dropcollinear=true`.
`npoints` is the number of points used by Makie to draw the shaded band.

Weighted data is supported via the keyword `weights` (passed to `mapping`).
"""
linear(; options...) = transformation(LinearAnalysis(; options...))