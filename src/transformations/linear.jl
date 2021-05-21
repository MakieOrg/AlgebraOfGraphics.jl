struct LinearAnalysis
    options::Dict{Symbol, Any}
end

LinearAnalysis(; kwargs...) = LinearAnalysis(Dict{Symbol, Any}(kwargs))

add_intercept_column(x::AbstractVector{T}) where {T} = [ones(T, length(x)) x]

# TODO: add multidimensional version
function (l::LinearAnalysis)(le::Entry)
    entry = map(le) do p, n
        x, y = p
        weights = get(n, :weights, similar(x, 0))
        npoints = get(l.options, :npoints, 200)
        interval = get(l.options, :interval, length(weights) > 0 ? nothing : :confidence)
        dropcollinear = get(l.options, :dropcollinear, false)
        lin_model = GLM.lm(add_intercept_column(x), collect(y); wts=weights, dropcollinear)
        isnothing(lin_model) && return Entry[]
        x̂ = range(extrema(x)..., length=npoints)
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
    linear(; interval)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `weights` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent.
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
"""
linear(; kwargs...) = Layer((LinearAnalysis(; kwargs...),))