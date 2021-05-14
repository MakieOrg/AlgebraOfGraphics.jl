struct LinearAnalysis
    options::Dict{Symbol, Any}
end

LinearAnalysis(; kwargs...) = LinearAnalysis(Dict{Symbol, Any}(kwargs))

add_intercept_column(x::AbstractVector{T}) where {T} = [ones(T, length(x)) x]

# TODO: add multidimensional version
function (l::LinearAnalysis)(le::Entry)
    return splitapply(le) do entry
        x, y = entry.positional
        weights = get(entry.named, :weights, similar(x, 0))
        npoints = get(l.options, :npoints, 200)
        interval = get(l.options, :interval, length(weights) > 0 ? nothing : :confidence)
        dropcollinear = false
        lin_model = try
            GLM.lm(add_intercept_column(x), collect(y); wts=weights, dropcollinear)
        catch e
            @warn "linear fit not possible"
            nothing
        end
        isnothing(lin_model) && return Entry[]
        x̂ = range(extrema(x)..., length=npoints)
        pred = GLM.predict(lin_model, add_intercept_column(x̂); interval)
        if !isnothing(interval)
            ŷ, lower, upper = map(vec, pred) # GLM prediction returns matrices
            default_plottype = LinesFill
            positional, named = (x̂, ŷ), (; lower, upper)
        else
            ŷ = vec(pred) # GLM prediction returns matrix
            default_plottype = Lines
            positional, named = (x̂, ŷ), (;)
        end
        plottype = AbstractPlotting.plottype(entry.plottype, default_plottype)
        return Entry(entry; plottype, positional, named)
    end
end

"""
    linear(; interval)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `weights` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent.
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
"""
linear(; kwargs...) = Layer((LinearAnalysis(; kwargs...),))