fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

splitapply(x::AbstractArray{<:Pair}) = x

splitapply(le::Entry) = splitapply(identity, le)

# TODO: make sure to also pool categorical positional mappings here
function splitapply(f, le::Entry)
    labels, positional, named = map(getlabel, le.mappings), map(getvalue, le.mappings)
    axs = Broadcast.combine_axes(mappings.positional..., values(mappings.named)...)
    iter = (m for (k, m) in mappings.named if m isa AbstractVector && !iscontinuous(m))
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