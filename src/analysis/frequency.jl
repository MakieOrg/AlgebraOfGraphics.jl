struct NamedSparseArray{S<:Tuple, V<:AbstractVector}
    keys::S
    values::V
    function NamedSparseArray(args::AbstractVector...)
        keys = Base.front(args)
        values = last(args)
        return new{typeof(keys), typeof(values)}(keys, values)
    end
end

# Turn named sparse array into a dense one, while remembering the labels.
function dense(kv::NamedSparseArray)
    keys, values = kv.keys, kv.values
    labels = map(collect∘uniquesorted, keys)
    indices = map(Base.OneTo∘length, labels)
    converter = map((k, v) -> Dict(zip(k, v)), labels, indices)
    d = zeros(eltype(values), indices)
    for (k, v) in zip(StructArray(keys), values)
        I = map(getindex, converter, k)
        d[I...] = v
    end
    return labels, d
end

function groupapply(f, key, data=nothing)
    gp = GroupPerm(fast_sortable(key))
    itr = (s[sp[first(range)]] => f(data, sortperm(gp), range) for range in gp)
    keys, values = fieldarrays(StructArray(itr, unwrap = t -> t <: Tuple))
    namedarray =  NamedSparseArray(fieldarrays(keys)..., values)
    return dense(namedarray)
end

function _frequency(args...)
    labels, values = groupapply((_, _, range) -> length(range), StructArray(args))
    plottypes = [:BarPlot, :Heatmap, :Volume]
    return mapping(labels..., values) * visual(plottypes[length(labels)])
end

"""
    frequency(data...)

Compute a frequency table of the arguments.
"""
const frequency = Analysis(_frequency)

function _reducer(args...; agg::OnlineStat=Mean())
    key, data = StructArray(Base.front(args)), last(args)
    labels, values = groupapply(key, data) do v, perm, range
        init = deepcopy(agg)
        for i in range
            fit!(init, v[perm[i]])
        end
        return value(init)
    end
    return mapping(labels..., values)
end

"""
    reducer(args...; agg=Mean())

Reduce the last argument conditioned on the preceding ones using the online
statistic `agg`.
"""
const reducer = Analysis(_reducer)