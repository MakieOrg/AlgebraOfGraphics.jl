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

function Base.:(==)(s1::Spec, s2::Spec)
    return plottype(s1) === plottype(s2) && s1.args == s2.args && s1.kwargs == s2.kwargs
end

function extract_names(d::NamedTuple)
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

specs(tree::Tree, palette) = specs(outputs(tree), palette)

function specs(ts, palette, rks = rankdicts(ts))
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
            names, data = extract_names(data)
            sp = merge(m, spec(positional(data)...; keyword(data)..., theme...))
            d[primary] = merge(sp, spec(names=names))
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
(t::Spec)(s::Series) = Series(merge(s.spec, t), s.series)

Base.:(==)(s1::Series, s2::Series) = s1.spec == s2.spec && s1.series == s2.series

function merge_primary_data(s1::Series, pd)
    return Series(s1.spec, merge_primary_data(s1.series, pd))
end
