const scales = Observable{Any}(Dict())

abstract type AbstractScale end

struct DiscreteScale <: AbstractScale
    scale::Observable
    values::Observable
end

DiscreteScale(v) = DiscreteScale(convert(Observable, v), Observable(Set()))
DiscreteScale() = DiscreteScale(nothing)

struct ContinuousScale <: AbstractScale
    scale::Observable
    values::Observable
end

ContinuousScale(v) = ContinuousScale(convert(Observable, v), Observable((Inf, -Inf)))
ContinuousScale() = ContinuousScale(nothing)

function add_value!(s::DiscreteScale, value)
    v = s.values[]
    foreach(t -> push!(v, t), value)
    s.values[] = v
end

function add_value!(s::ContinuousScale, value)
    m, n = s.values[]
    m′, n′ = extrema(value)
    s.values[] = (min(m, m′), max(n, n′))
end

function get_attr(d::DiscreteScale, value)
    map(d.scale, d.values) do scale, values
        map(value) do v
            n = sum(≤(v), values)
            scale === nothing ? n : scale[mod1(n, length(scale))]
        end
    end
end

function get_attr(c::ContinuousScale, value)
    map(c.scale, c.values) do scale, values
        scale === nothing && return value
        min, max = values
        smin, smax = scale
        @. smin + value * (smax - smin) / (max - min)
    end
end

function attr!(s::AbstractScale, value)
    add_value!(s, value)
    return get_attr(s, value)
end

