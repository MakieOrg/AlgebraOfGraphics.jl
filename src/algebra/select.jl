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

getlabeledvector(data, name::StringLike) = string(name), getcolumn(data, Symbol(name))

function getlabeledvector(data, idx::Integer)
    name = columnnames(data)[idx]
    return getlabeledvector(data, name)
end

# function getlabeledvector(data::NTuple{N, Any}, d::DimsSelector) where N
#     sz = ntuple(N) do n
#         return n in d.dims ? length(shape[n]) : 1
#     end
#     return "", reshape(CartesianIndices(sz), 1, sz...)
# end

function getlabeledvector(data, x::Pair{<:Any, <:StringLike})
    name, label = x
    _, v = getlabeledvector(data, name)
    return label, v
end

function getlabeledvector(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    # consider supporting automated labeling for multiple names here
    label, v = getlabeledvector(data, name)
    return label, map(transformation, v)
end

function getlabeledvector(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa ArrayLike ? name : fill(name)
    vs = map(name -> last(getlabeledvector(data, name)), names)
    v = map(transformation, vs...)
    return label, v
end

"""
    getlabeledarray(layer::Layer, s)

Return a label and an array from a selector `s`.
"""
getlabeledarray(layer::Layer, s) = getlabeledarray(layer, fill(s))

function getlabeledarray(layer::Layer, selectors::ArrayLike)
    labelsvectors = map(s -> getlabeledvector(layer.data, s), selectors)
    return map(first, labelsvectors), map(last, labelsvectors)
end
