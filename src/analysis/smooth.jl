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
        return (x, y), (x, l, u)
    catch e
        @warn "Linear fit not possible for the given data"
        return nothing
    end
end

_push!(acc, c) = map(push!, acc, c)
_push!(::Nothing, c) = map(StructArray∘vcat, c)
_wrap(c) = map(vcat, c)
function _linear(c::AbstractContextual; kwargs...)
    acc = mapfoldl(_push!, pairs(c), init=nothing) do (p, d)
        (p, _wrap.(_linear(positional(d)...; keyword(d)..., kwargs...))...)
    end
    ps, ls, bs = map(fieldarrays, acc)
    return primary(; ps...) * (data(ls...) * spec(:Lines) + data(bs...) * spec(:Band, alpha=0.5))
end

const linear = Analysis(_linear)

# struct Smooth{S, T}
#     x::Vector{S}
#     y::Vector{T}
# end

# convert_arguments(P::PlotFunc, l::Smooth) = PlotSpec{Lines}(Point2f0.(l.x,l.y))

# function smooth(x, y; length = 100, kwargs...)
#     model = loess(x, y; kwargs...)
#     min, max = extrema(x)
#     us = collect(range(min, stop = max, length = length))
#     vs = Loess.predict(model, us)
#     return Smooth(us, vs)
# end

# smooth(; kwargs...) = (args...) -> smooth(args...; kwargs...)

