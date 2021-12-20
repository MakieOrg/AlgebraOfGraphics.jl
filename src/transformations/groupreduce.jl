# Investigate link with transducers, potentially had shim to support OnlineStats
function _groupreduce(agg, summaries::Tuple, values::Tuple)
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
    N = length(e.positional)
    summaries = Any[mapreduce(collect∘uniquesorted, mergesorted, e.positional[idx]) for idx in 1:N-1]
    entry = map(e) do p, n
        positional = copy(summaries)
        push!(positional, _groupreduce(agg, Tuple(summaries), Tuple(p)))
        named = n
        return positional, named
    end
    default_plottype = categoricalplottypes[length(summaries)]
    plottype = Makie.plottype(entry.plottype, default_plottype)
    return Entry(entry; plottype)
end
