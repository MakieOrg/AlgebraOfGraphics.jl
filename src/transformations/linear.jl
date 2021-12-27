Base.@kwdef struct LinearAnalysis{I}
    npoints::Int=200
    dropcollinear::Bool=false
    interval::I=automatic
end

add_intercept_column(x::AbstractVector{T}) where {T} = [ones(T, length(x)) x]

# TODO: add multidimensional version
function (l::LinearAnalysis)(le::Entry)
    entry = map(le) do p, n
        x, y = p
        weights = get(n, :weights, similar(x, 0))
        default_interval = length(weights) > 0 ? nothing : :confidence
        interval = l.interval === automatic ? default_interval : l.interval
        lin_model = GLM.lm(add_intercept_column(x), collect(y); wts=weights, l.dropcollinear)
        isnothing(lin_model) && return Entry[]
        x̂ = range(extrema(x)..., length=l.npoints)
        pred = GLM.predict(lin_model, add_intercept_column(x̂); interval)
        return if !isnothing(interval)
            ŷ, lower, upper = map(vec, pred) # GLM prediction returns matrices
            (x̂, ŷ), (; lower, upper)
        else
            ŷ = vec(pred) # GLM prediction returns matrix
            (x̂, ŷ), (;)
        end
    end
    default_plottype = isempty(entry.named) ? Lines : LinesFill
    plottype = Makie.plottype(entry.plottype, default_plottype)
    return Entry(entry; plottype)
end

"""
    linear(; npoints=200, interval=automatic, dropcollinear=false)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `weights` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent.
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
By default, this analysis errors on singular (collinear) data. To avoid that,
it is possible to set `dropcollinear=true`.
"""
linear(; options...) = transformation(LinearAnalysis(; options...))