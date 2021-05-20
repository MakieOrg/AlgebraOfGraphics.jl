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

getlabeledvector(data, shape, name::StringLike) = string(name), getcolumn(data, Symbol(name))

function getlabeledvector(data, shape, idx::Integer)
    name = columnnames(data)[idx]
    return getlabeledvector(data, shape, name)
end

function getlabeledvector(data, shape::NTuple{N, Any}, d::DimsSelector) where N
    sz = ntuple(N) do n
        return n in d.dims ? length(shape[n]) : 1
    end
    return "", reshape(CartesianIndices(sz), 1, sz...)
end

getlabeledvector(layer::Layer, name::Union{StringLike, Integer, DimsSelector}) =
    getlabeledvector(layer.data, shape(layer), name)

function getlabeledvector(layer::Layer, x::Pair{<:Any, <:StringLike})
    name, label = x
    _, v = getlabeledvector(layer, name)
    return label, v
end

function getlabeledvector(layer::Layer, x::Pair{<:Any, <:Any})
    name, transformation = x
    # consider supporting automated labeling for multiple names here
    label, v = getlabeledvector(layer, name)
    return label, map(transformation, v)
end

function getlabeledvector(layer::Layer, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa ArrayLike ? name : fill(name)
    vs = map(name -> last(getlabeledvector(layer, name)), names)
    v = map(transformation, vs...)
    return label, v
end

"""
    getlabeledarray(layer::Layer, s)

Return a label and an array from a selector `s`.
"""
getlabeledarray(layer::Layer, s) = getlabeledarray(layer, fill(s))

function getlabeledarray(layer::Layer, selectors::ArrayLike)
    labelsvectors = map(s -> getlabeledvector(layer, s), selectors)
    return map(first, labelsvectors), map(last, labelsvectors)
end
