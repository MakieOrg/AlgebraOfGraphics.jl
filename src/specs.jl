struct Spec{T} <: AbstractEdge
    args::Tuple
    kwargs::NamedTuple
end

spec(args...; kwargs...) = Spec{Any}(args, values(kwargs))
spec(::Type{T}, args...; kwargs...) where {T} = Spec{T}(args, values(kwargs))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge(t1.kwargs, t2.kwargs)
    return Spec{T}(args, kwargs)
end

function specs(tree::Tree, palette)
    ts = outputs(tree)
    rks = rankdicts(ts)
    serieslist = OrderedDict{NamedTuple, Spec}[]
    for series in ts
        d = OrderedDict{NamedTuple, Spec}()
        m = series isa Series ? series.spec : spec()
        scales = Dict{Symbol, Any}()
        for (key, val) in palette
            scales[key] = get(m.kwargs, key, val)
        end
        for (primary, data) in pairs(series)
            theme = applytheme(scales, primary, rks)
            d[primary] = merge(m, spec(positional(data)...; keyword(data)..., theme...))
        end
        push!(serieslist, d)
    end
    return serieslist
end

function applytheme(scales, grp, rks)
    d = Dict{Symbol, Any}()
    for (key, val) in pairs(grp)
        # let's worry about interactivity later
        scale = to_value(get(scales, key, nothing))
        idx = rks[key][val]
        d[key] = scale === nothing ? idx : scale[mod1(idx, length(scale))]
    end
    return d
end

struct Series{T, S} <: AbstractEdge
    spec::Spec{T}
    series::S
end

Base.pairs(s::Series) = pairs(s.series)

(t::Spec)(s) = Series(t, s)
(t::Spec)(s::Series) = Series(merge(s.spec, t), s)

