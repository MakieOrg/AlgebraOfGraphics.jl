# From StatsMakie
function _linear(x::AbstractVector{T}, y::AbstractVector;
                 n_points = 100, interval = :confidence) where T
    try
        y = collect(y)
        x = collect(x)
        lin_model = GLM.lm([ones(T, length(x)) x], y)
        x_min, x_max = extrema(x)
        x_new = range(x_min, x_max, length = n_points)
        y_new, lower, upper = GLM.predict(lin_model,
                                          [ones(T, n_points) x_new],
                                          interval=interval)
        # the GLM predictions always return matrices
        x, y, l, u = x_new, vec(y_new), vec(lower), vec(upper)
        lines = style(x, y)
        band = style(x, l, u)
        return spec(:Lines) * lines + spec(:Band, alpha = 0.2) * band
    catch e
        @warn "Linear fit not possible for the given data"
        return null
    end
end

const linear = Analysis(_linear)

function _smooth(x, y; length = 100, kwargs...)
    min, max = extrema(x)
    min < max || return null
    model = Loess.loess(x, y; kwargs...)
    us = collect(range(min, stop = max, length = length))
    vs = Loess.predict(model, us)
    return spec(:Lines) * style(us, vs)
end

const smooth = Analysis(_smooth)

