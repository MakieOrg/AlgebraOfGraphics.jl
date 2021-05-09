struct LinearAnalysis
    options::Dict{Symbol, Any}
end

LinearAnalysis(; kwargs...) = LinearAnalysis(Dict{Symbol, Any}(kwargs))

add_intercept_column(x::AbstractVector{T}) where {T} = [ones(T, length(x)) x]

# TODO: add multidimensional version
function (l::LinearAnalysis)(le::Entry)
    return splitapply(le) do entry
        labels, mappings = map(getlabel, entry.mappings), map(getvalue, entry.mappings)
        x, y = mappings.positional
        wts = get(mappings, :wts, similar(x, 0))
        npoints = get(l.options, :npoints, 200)
        interval = get(l.options, :interval, length(wts) > 0 ? nothing : :confidence)
        dropcollinear = false
        lin_model = try
            GLM.lm(add_intercept_column(x), collect(y); wts, dropcollinear)
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
            labeled_result = map(Labeled, vcat(labels.positional, ["", ""]), [x̂, ŷ, lower, upper])
        else
            ŷ = vec(pred) # GLM prediction returns matrix
            default_plottype = Lines
            labeled_result = map(Labeled, labels.positional, [x̂, ŷ])
        end
        return Entry(
            AbstractPlotting.plottype(entry.plottype, default_plottype),
            Arguments(labeled_result),
            entry.attributes
        )
    end
end

"""
    linear(; interval)

Compute a linear fit of `y ~ 1 + x`. An optional named mapping `wts` determines the weights.
Use `interval` to specify what type of interval the shaded band should represent.
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
"""
linear(; kwargs...) = Layer((LinearAnalysis(; kwargs...),))