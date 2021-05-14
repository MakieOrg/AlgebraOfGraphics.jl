struct DimsSelector{N}
    dims::NTuple{N, Int}
end
dims(args...) = DimsSelector(args)

function (d::DimsSelector)(c::CartesianIndex{N}) where N
    t = ntuple(N) do n
        return n in d.dims ? c[n] : 1
    end
    return CartesianIndex(t)
end

Broadcast.broadcastable(d::DimsSelector) = Ref(d)

compute_label(data, name::StringLike) = string(name)
compute_label(data, name::Integer) = string(columnnames(data)[name])
compute_label(data, name::DimsSelector) = ""

struct NameTransformationLabel
    name::Any
    transformation::Any
    label::String
end

function NameTransformationLabel(name, transformation, label::Symbol)
    return NameTransformationLabel(name, transformation, string(label))
end

function NameTransformationLabel(data, x::Union{StringLike, Integer, DimsSelector})
    return NameTransformationLabel(x, identity, compute_label(data, x))
end

function NameTransformationLabel(data, x::Pair{<:Any, <:StringLike})
    name, label = x
    return NameTransformationLabel(name, identity, label)
end

function NameTransformationLabel(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    label = compute_label(data, name)
    return NameTransformationLabel(name, transformation, label)
end

function NameTransformationLabel(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    return NameTransformationLabel(name, transformation, label)
end

apply_context(data, shape, name::StringLike) = getcolumn(data, Symbol(name))

function apply_context(data, shape, idx::Integer)
    name = columnnames(data)[idx]
    return getcolumn(data, name)
end

function apply_context(data, shape::NTuple{N, Any}, d::DimsSelector) where N
    sz = ntuple(N) do n
        return n in d.dims ? length(shape[n]) : 1
    end
    return reshape(CartesianIndices(sz), 1, sz...)
end

apply_context(layer::Layer, name) = apply_context(layer.data, shape(layer), name)

"""
    getlabeledarray(layer::Layer, s)

Return a label and an array from a selector `s`.
"""
getlabeledarray(layer::Layer, s) = getlabeledarray(layer, fill(s))

function getlabeledarray(layer::Layer, s::ArrayLike)
    ntls = map(x -> NameTransformationLabel(layer.data, x), s)
    labels = map(ntl -> ntl.label, ntls)
    nested = map(ntls) do ntl
        names = Broadcast.broadcastable(ntl.name)
        cols = map(name -> apply_context(layer, name), names)
        return map(ntl.transformation, cols...)
    end
    v = unnest(nested)
    return labels, v
end
