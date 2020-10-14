function _reducer(args...; agg::OnlineStat=Mean())
    key, data = StructArray(Base.front(args)), last(args)
    gp = GroupPerm(fast_sortable(key))
    perm = sortperm(gp)
    function folder(range)
        init = deepcopy(agg)
        for i in range
            fit!(init, data[perm[i]])
        end
        return value(init)
    end
    itr = (s[sp[first(range)]] => folder(range) for range in gp)
    keys, values = fieldarrays(StructArray(itr, unwrap = t -> t <: Tuple))
    return mapping(keys..., values)
end

"""
    reducer(args...; agg=Mean())

Reduce the last argument conditioned on the preceding ones using the online
statistic `agg`.
"""
const reducer = Analysis(_reducer)