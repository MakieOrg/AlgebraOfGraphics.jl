# Investigate link with transducers, potentially had shim to support OnlineStats
function _groupreduce(agg, summaries::Tuple, values...)
    init, op, value = agg.init, agg.op, agg.value
    results = map(_ -> init(), CartesianIndices(map(length, summaries)))
    keys, data = front(values), last(values)
    sa = StructArray(map(fast_hashed, keys))
    perm = sortperm(sa)
    for idxs in GroupPerm(sa, perm)
        key = sa[perm[first(idxs)]]
        acc = init()
        for idx in idxs
            val = data[perm[idx]]
            acc = op(acc, val)
        end
        I = map(searchsortedfirst, summaries, key)
        results[I...] = acc
    end
    return map(value, results)
end

function groupreduce(agg, e::Entry)
    summaries = map(front(e.positional)) do v
        return mapreduce(collect∘uniquesorted, mergesorted, v)
    end
    entry = map(e) do p, _
        positional, named = (summaries..., _groupreduce(agg, summaries, p...)), (;)
        return positional, named
    end
    default_plottype = categoricalplottypes[length(summaries)]
    plottype = Makie.plottype(entry.plottype, default_plottype)
    return Entry(entry; plottype)
end
