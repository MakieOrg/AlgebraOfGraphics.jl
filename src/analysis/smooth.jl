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
        return AlgebraicDict(
                             spec(:Lines) => AlgebraicDict(NamedTuple() => lines),
                             spec(:Band, alpha = 0.2) => AlgebraicDict(NamedTuple() => band)
                            )
    catch e
        @warn "Linear fit not possible for the given data"
        return spec()
    end
end

function _linear(d::AlgebraicDict; kws...)
    acc = AlgebraicDict()
    for (sp, val) in d
        for (p, st) in val
            pre = AlgebraicDict(sp => AlgebraicDict(p => style()))
            args, kwargs = split(st.value)
            acc += pre * _linear(args...; kws..., kwargs...)
        end
    end
    return acc
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

