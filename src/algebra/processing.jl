## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

splitapply(x::AbstractArray{<:Pair}) = x

splitapply(le::Entry) = splitapply(identity, le)

function splitapply(f, le::Entry)
    positional, named = map(getvalue, le.positional), map(getvalue, le.named)
    axs = Broadcast.combine_axes(positional..., named...)
    iter = (m for (_, m) in named if m isa AbstractVector && !iscontinuous(m))
    grouping_cols = Tuple(iter)
    list = Entry[]
    foreach(indices_iterator(grouping_cols)) do idxs
        for c in CartesianIndices(tail(axs))
            submappings = map(labels, mappings) do label, v
                I = ntuple(ndims(v)) do n
                    i = n == 1 ? idxs : c[n-1]
                    return adjust_index(axs[n], axes(v, n), i)
                end
                return Labeled(label, view(v, I...))
            end
            discrete, continuous = separate!(submappings)
            new_entries = maybewrap(f(Entry(le.plottype, continuous, le.attributes)))
            for new_entry in maybewrap(new_entries)
                push!(list, recombine!(discrete, new_entry))
            end
        end
    end
    return list
end

## Transform `Layers` into list of `Entry`

nested_map(f, (a, b)::Tuple) = map(f, a), map(f, b)

function process_data(data, positional′, named′)
    positional, named = nested_map((positional′, named′)) do x
        return map(y -> NameTransformationLabel(data, y), maybewrap(x))
    end
    axs = Broadcast.combine_axes(positional..., named...)
    labeledarrays = nested_map((positional, named)) do ntls
        return map(ntls) do ntl
            cols = apply_context(data, axs, maybewrap(ntl.name))
            Labeled(ntl.label, map(ntl.transformation, cols...))
        end
    end
    return Entry(Any, labeledarrays..., Dict{Symbol, Any}())
end

process_data(layer::Layer) = process_data(layer.data, layer.positional, layer.named)

process_transformations(layers::Layers) = map(process_transformations, layers)

function process_transformations(layer::Layer)
    init = process_data(layer)
    res = foldl(process_transformations, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process_transformations(v::AbstractArray{Entry}, f) = map(f, v)

process_transformations(le::Entry, f) = f(le)
