const categoricalplottypes = [:BarPlot, :Heatmap, :Volume]

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
function dense(kv::NamedSparseArray; default::T=zero(eltype(kv.values))) where T
    keys, values = kv.keys, kv.values
    labels = map(collect∘uniquesorted, keys)
    indices = map(Base.OneTo∘length, labels)
    converter = map((k, v) -> Dict(zip(k, v)), labels, indices)
    U = promote_type(T, eltype(values))
    d = U[default for _ in Iterators.product(indices...)]
    for (k, v) in zip(StructArray(keys), values)
        I = map(getindex, converter, k)
        d[I...] = v
    end
    return labels, d
end
