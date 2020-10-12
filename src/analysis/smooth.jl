# From StatsMakie
function _linear(x::AbstractVector{T}, y::AbstractVector;
                 npoints = 100, wts = similar(x, 0),
                 interval = length(wts) > 0 ? nothing : :confidence) where T
    # Note: confidence intervals are currently not supported for WLS in GLM.jl
    try
        y = collect(y)
        x = collect(x)
        wts = collect(wts)
        lin_model = GLM.lm([ones(T, length(x)) x], y, wts=wts)
        x_min, x_max = extrema(x)
        x_new = range(x_min, x_max, length = npoints)
        pred = GLM.predict(lin_model,
                           [ones(T, npoints) x_new],
                           interval=interval)
        if !isnothing(interval)
            y_new, lower, upper = pred
        else
            y_new = pred
        end
        # the GLM predictions always return matrices
        x, y = x_new, vec(y_new)
        lines = mapping(x, y)
        if !isnothing(interval)
            band = mapping(x, vec(lower), vec(upper))
            return visual(:Lines) * lines + visual(:Band, alpha = 0.2) * band
        else 
            return visual(:Lines) * lines
        end
    catch e
        @warn "Linear fit not possible for the given data"
        return AlgebraicList()
    end
end

"""
    linear(x, y; wts = similar(x, 0), interval = length(wts) > 0 ? nothing : :confidence)

Compute a linear fit of `y ~ 1 + x`. Weighted data is supported via the keyword `wts`.
Use `interval` to specify what type of interval the shaded band should represent.
Valid values of interval are `:confidence` delimiting the uncertainty of the predicted
relationship, and `:prediction` delimiting estimated bounds for new data points.
"""
const linear = Analysis(_linear)

# TODO: multidimensional case as a heatmap or surface plot
function _smooth(x, y; npoints = 100, kwargs...)
    min, max = extrema(x)
    min < max || return AlgebraicList()
    model = Loess.loess(Float64.(x), Float64.(y); kwargs...)
    us = collect(range(min, stop = max, length = npoints))
    vs = Loess.predict(model, us)
    return visual(:Lines) * mapping(us, vs)
end

"""
    smooth(x, y, span=0.75, degreee=2)

Fit a loess model. `span` is the degree of smoothing, typically in `[0,1]`.
Smaller values result in smaller local context in fitting. `degree` is the polynomial
degree used in the loess model.
"""
const smooth = Analysis(_smooth)
