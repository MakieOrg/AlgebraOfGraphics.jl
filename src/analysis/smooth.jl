# From StatsMakie
# TODO PR for Band in AbstractPlotting
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
        return LittleDict(
                          spec(:Lines) => namedtuple(x, y),
                          spec(:Band) => namedtuple(x, l, u)
                         )
    catch e
        @warn "Linear fit not possible for the given data"
        return nothing
    end
end

const linear = Analysis(_linear)

function _smooth(x, y; length = 100, kwargs...)
    model = Loess.loess(x, y; kwargs...)
    min, max = extrema(x)
    us = collect(range(min, stop = max, length = length))
    vs = Loess.predict(model, us)
    return LittleDict(spec(:Lines) => namedtuple(us, vs))
end

const smooth = Analysis(_smooth)

