# From StatsMakie
# TODO refactor common part as a fallback for Analysis
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
        return namedtuple(x, y), namedtuple(x, l, u)
    catch e
        @warn "Linear fit not possible for the given data"
        return nothing
    end
end

function _linear(c::AbstractDict; kwargs...)
    d = OrderedDict{Spec, PairList}()
    for (sp, itr) in c
        for (primary, data) in itr
            res = _linear(positional(data)...; keyword(data)..., kwargs...)
            res === nothing && continue
            l, b = res
            pushat!(d, merge(sp, spec(:Lines)), primary => l)
            pushat!(d, merge(sp, spec(:Band)), primary => b)
        end
    end
    return d
end

const linear = Analysis(_linear)

function _smooth(x, y; length = 100, kwargs...)
    model = Loess.loess(x, y; kwargs...)
    min, max = extrema(x)
    us = collect(range(min, stop = max, length = length))
    vs = Loess.predict(model, us)
    return namedtuple(us, vs)
end

function _smooth(c::AbstractDict; kwargs...)
    d = OrderedDict{Spec, PairList}()
    for (sp, itr) in c
        for (primary, data) in itr
            res = _smooth(positional(data)...; keyword(data)..., kwargs...)
            pushat!(d, merge(sp, spec(:Lines)), primary => res)
        end
    end
    return d
end

const smooth = Analysis(_smooth)

