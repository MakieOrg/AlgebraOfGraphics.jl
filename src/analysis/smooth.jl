# From StatsMakie
function _linear(x::AbstractVector{T}, y::AbstractVector;
                 n_points = 100, wts = similar(x, 0),
                 interval = length(wts) > 0 ? nothing : :confidence) where T
    # Note: confidence intervals are currently not supported for WLS in GLM.jl
    try
        y = collect(y)
        x = collect(x)
        wts = collect(wts)
        lin_model = GLM.lm([ones(T, length(x)) x], y, wts=wts)
        x_min, x_max = extrema(x)
        x_new = range(x_min, x_max, length = n_points)
        pred = GLM.predict(lin_model,
                           [ones(T, n_points) x_new],
                           interval=interval)
        if !isnothing(interval)
            y_new, lower, upper = pred
        else
            y_new = pred
        end
        # the GLM predictions always return matrices
        x, y = x_new, vec(y_new)
        lines = style(x, y)
        if !isnothing(interval)
            band = style(x, vec(lower), vec(upper))
            return spec(:Lines) * lines + spec(:Band, alpha = 0.2) * band
        else 
            return spec(:Lines) * lines
        end
    catch e
        @warn "Linear fit not possible for the given data"
        return AlgebraicList()
    end
end

const linear = Analysis(_linear)

function _smooth(x, y; length = 100, kwargs...)
    min, max = extrema(x)
    min < max || return AlgebraicList()
    model = Loess.loess(x, y; kwargs...)
    us = collect(range(min, stop = max, length = length))
    vs = Loess.predict(model, us)
    return spec(:Lines) * style(us, vs)
end

const smooth = Analysis(_smooth)

