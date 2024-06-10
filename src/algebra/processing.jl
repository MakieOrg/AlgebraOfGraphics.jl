## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function permutation_ranges(cols)
    isempty(cols) && return nothing, [:]
    grouping_sa = StructArray(map(fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return sortperm(gp), collect(gp)
end

shape(pl::ProcessedLayer) = Broadcast.combine_axes(pl.primary..., pl.positional..., pl.named...)

function shape(l::Layer)
    containers = (l.positional, l.named)
    wrappedvars = (v isa AbstractArray ? v : fill(v) for vs in containers for v in vs)
    return Broadcast.combine_axes(wrappedvars...)
end

function assert_equal(a, b)
    if !isequal(a, b)
        msg = "$a and $b must be equal"
        throw(ArgumentError(msg))
    end
    return a
end

getuniquevalue(v) = reduce(assert_equal, v)

function getnewindex(u, c)
    v = Broadcast.broadcastable(u)
    return v[Broadcast.newindex(v, c)]
end

function subgroups(vs, perm, rgs, axs)
    return map(Iterators.product(rgs, CartesianIndices(axs))) do (rg, c)
        v = getnewindex(vs, c)
        return ndims(v) == 0 || rg === (:) ? v : view(v, perm[rg])
    end
end

function shiftdims(v)
    w = Broadcast.broadcastable(v)
    return ndims(w) == 0 ? w[] : reshape(w, 1, axes(w)...)
end

function group(processedlayer::ProcessedLayer)
    grouping = Tuple(only(v) for v in values(processedlayer.primary) if ndims(v) == 0)
    perm, rgs = permutation_ranges(grouping)
    axs = shape(processedlayer)

    primary = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.primary)
    positional = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.positional)
    named = map(vs -> subgroups(vs, perm, rgs, axs), processedlayer.named)

    labels = map(shiftdims, processedlayer.labels)
    return ProcessedLayer(processedlayer; primary, positional, named, labels)
end

function getlabeledarray(layer::Layer, s)
    data, axs = layer.data, shape(layer)
    isdims = s isa DimsSelector || s isa Pair && first(s) isa DimsSelector
    if isdims
        vs, (f, (label, scaleid)) = select(data, s)
        d = only(vs) # multiple dims selectors in the same mapping are disallowed
        sz = ntuple(length(axs)) do n
            return n in d.dims ? length(axs[n]) : 1
        end
        arr = map(fill∘f, CartesianIndices(sz))
    elseif isnothing(data)
        vs, (f, (label, scaleid)) = select(data, s)
        isprim = any(iscategoricalcontainer, vs)
        arr = isprim ? map(fill∘f, vs...) : map(x -> map(f, x...), zip(vs...)) 
    else
        selector = s isa AbstractArray ? s : fill(s)
        labeled_arr = map(selector) do s
            local vs, (f, (label, scaleid)) = select(data, s)
            return label, scaleid, map(f, vs...)
        end
        label = map(first, labeled_arr)
        scaleid = map(x -> x[2], labeled_arr)
        arr = map(last, labeled_arr)
    end
    return label, scaleid, arr
end

function extract_values!(pairs, labels)
    merge!(labels, Dictionary(map(first, pairs)))
    return map(last, pairs)
end

function process_mappings(layer::Layer)
    # the labels extracted here are directly related to their positional or named arguments
    # but some may later be remapped using `positional_mapping`
    labels = MixedArguments()

    label_scaleid_positional = map(v -> getlabeledarray(layer, v), layer.positional)
    pos_labels = map(first, label_scaleid_positional)
    pos_scaleids = map(x -> x[2], label_scaleid_positional) 
    positional = map(last, label_scaleid_positional)

    label_scaleid_named = map(v -> getlabeledarray(layer, v), layer.named)
    nam_labels = map(first, label_scaleid_named)
    nam_scaleids = map(x -> x[2], label_scaleid_named) 
    named = map(last, label_scaleid_named)

    labels = merge(Dictionary(pos_labels), nam_labels)
    scaleids = merge(Dictionary(pos_scaleids), nam_scaleids)

    # not sure if this logic should work in all cases, maybe multiple scales per
    # mapping entry could be possible with wide data
    uniqueelement(x) = x
    function uniqueelement(a::AbstractArray)
        u = unique(a)
        if length(u) != 1
            error("Found a collection of scale ids that does not contain a single unique value: $a")
        end
        return only(u)
    end

    unique_scales = map(uniqueelement, scaleids)
    unique_scales_without_nothings = filter(x -> x isa ScaleID, unique_scales)
    scale_mapping = map(scaleid -> scaleid.id, unique_scales_without_nothings)

    primary, named = separate(iscategoricalcontainer, named)

    return ProcessedLayer(; primary, positional, named, labels, scale_mapping)
end

function process(layer::Layer)
    processedlayer = process_mappings(layer)
    grouped_entry = isnothing(layer.data) ? processedlayer : group(processedlayer)
    primary = map(vs -> map(getuniquevalue, vs), grouped_entry.primary)
    transformed_processlayer = layer.transformation(ProcessedLayer(grouped_entry; primary))
    attributes = merge(mandatory_attributes(transformed_processlayer.plottype), transformed_processlayer.attributes)
    possibly_without_visual = ProcessedLayer(transformed_processlayer; attributes)
    return set_missing_visual(possibly_without_visual)
end

function set_missing_visual(p::ProcessedLayer)
    if p.plottype !== Plot{plot}
        p
    else
        plottype = Makie.plottype(p.plottype, p.positional...)
        if plottype === Plot{plot}
            error("Failed to determine default plot type for positional arguments of type $(typeof(p.positional))")
        end
        ProcessedLayer(p; plottype)
    end
end
