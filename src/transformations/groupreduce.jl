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

function groupreduce(agg, le::Entry)
    summaries = Tuple(map(summary∘getvalue, front(le.positional)))
    return splitapply(le) do entry
        labels, values = map(getlabel, entry.positional), map(getvalue, entry.positional)
        results = _groupreduce(agg, summaries, values...)
        result = (summaries..., results)
        labeled_result = map(Labeled, labels, result)
        default_plottype = categoricalplottypes[length(summaries)]
        return Entry(
            AbstractPlotting.plottype(entry.plottype, default_plottype),
            labeled_result,
            (;),
            entry.attributes
        )
    end
end
