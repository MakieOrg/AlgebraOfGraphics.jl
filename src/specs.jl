struct Spec{T}
    args::Tuple
    kwargs::NamedTuple
end
Spec() = Spec{Any}((), NamedTuple())

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

struct SeriesList
    list::Vector{Pair{Spec, ContextualMap}}
end
SeriesList(s::SeriesList) = s
SeriesList(c::ContextualMap) = SeriesList(Pair{Spec, ContextualMap}[Spec() => c])
SeriesList(c::Spec) = SeriesList(Pair{Spec, ContextualMap}[c => ContextualMap()])

function Base.:*(
                 s1::Union{ContextualMap, SeriesList},
                 s2::Union{ContextualMap, SeriesList}
                )
    s1, s2 = SeriesList(s1), SeriesList(s2)
    l1, l2 = s1.list, s2.list
    v = Pair{Spec, ContextualMap}[]
    for el1 in l1
        for el2 in l2
            push!(v, merge(first(el1), first(el2)) => last(el1) * last(el2))
        end
    end
    return SeriesList(v)
end

function Base.:+(
                 s1::Union{ContextualMap, SeriesList},
                 s2::Union{ContextualMap, SeriesList}
                )
    s1, s2 = SeriesList(s1), SeriesList(s2)
    l1, l2 = s1.list, s2.list
    return SeriesList(vcat(l1, l2))
end

Base.:(==)(s1::SeriesList, s2::SeriesList) = s1.list == s2.list

spec(args...; kwargs...) = SeriesList(Spec{Any}(args, values(kwargs)))
spec(::Type{T}, args...; kwargs...) where {T} = SeriesList(Spec{T}(args, values(kwargs)))

# plotting tools

function extract_names(d::NamedTuple)
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

specs(c::ContextualMap, palette) = specs(SeriesList(c), palette)

function specs(ts::SeriesList, palette, rks = rankdicts(ts))
    serieslist = OrderedDict{NamedTuple, Spec}[]
    for (m, ctxmap) in ts.list
        d = OrderedDict{NamedTuple, Spec}()
        scales = Dict{Symbol, Any}()
        for (key, val) in palette
            scales[key] = get(m.kwargs, key, val)
        end
        for (primary, data) in pairs(ctxmap)
            theme = applytheme(scales, primary, rks)
            names, data = extract_names(data)
            sp = merge(m, Spec{Any}(Tuple(positional(data)), (; keyword(data)..., theme...)))
            d[primary] = merge(sp, Spec{Any}((), (; names=names)))
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

rankdicts(ts::SeriesList) = rankdicts(map(last, ts.list))
