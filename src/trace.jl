struct Trace{T}
    args::Tuple
    kwargs::NamedTuple
end

trace(args...; kwargs...) = Trace{Any}(args, values(kwargs))
trace(::Type{T}, args...; kwargs...) where {T} = Trace{T}(args, values(kwargs))
plottype(::Trace{T}) where {T} = T

function Base.merge(t1::Trace{T1}, t2::Trace{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge(t1.kwargs, t2.kwargs)
    return Trace{T}(args, kwargs)
end

function traces(tree::Tree, palette)
    ts = outputs(tree)
    rks = rankdicts(ts)
    serieslist = OrderedDict{NamedTuple, Trace}[]
    for series in ts
        d = OrderedDict{NamedTuple, Trace}()
        m = spec(series)
        scales = Dict{Symbol, Any}()
        for (key, val) in palette
            scales[key] = get(m.kwargs, key, val)
        end
        for (primary, data) in pairs(series)
            theme = applytheme(scales, primary, rks)
            d[primary] = merge(m, trace(data.args...; data.kwargs..., theme...))
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
        d[key] = scale === nothing ? idxs : scale[mod1(idx, length(scale))]
    end
    return d
end
