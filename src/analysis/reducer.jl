function reduce_permuted(agg::OnlineStat, data, perm, rg)
    acc = deepcopy(agg)
    for i in rg
        fit!(acc, data[perm[i]])
    end
    return value(acc)
end

function reduce_permuted(agg, data, perm, rg)
    acc = data[perm[first(rg)]]
    for i in rg[2:end]
        acc = agg(acc, data[perm[i]])
    end
    return acc
end

function _reducer(args...; agg=Mean())
    key, data = StructArray(Base.front(args)), last(args)
    gp = GroupPerm(fast_sortable(key))
    perm = sortperm(gp)
    itr = (key[perm[first(rg)]] => reduce_permuted(agg, data, perm, rg) for rg in gp)
    keys, values = components(StructArray(itr, unwrap = t -> t <: Tuple))
    return mapping(components(keys)..., values)
end

"""
    reducer(args...; agg=Mean())

Reduce the last argument conditioned on the preceding ones using the online
statistic or binary function `agg`.
"""
const reducer = Analysis(_reducer)