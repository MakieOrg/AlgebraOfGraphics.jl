function specs(tree::Tree, palette)
    ts = outputs(tree)
    rks = rankdicts(ts)
    speclist = OrderedDict{NamedTuple, Spec}[]
    for trace in ts
        d = OrderedDict{NamedTuple, Spec}()
        m = spec(trace)
        scales = Dict{Symbol, Any}()
        for (key, val) in palette
            scales[key] = get(m.kwargs, key, val)
        end
        for (primary, data) in pairs(trace)
            theme = applytheme(scales, primary, rks)
            d[primary] = merge(m, to_spec(data.args...; theme...))
        end
        push!(speclist, d)
    end
    return speclist
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
