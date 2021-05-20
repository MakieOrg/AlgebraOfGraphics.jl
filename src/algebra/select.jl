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

function select(data, name::StringLike)
    v = getcolumn(data, Symbol(name))
    return (v,) => identity => string(name)
end

function select(data, idx::Integer)
    name = columnnames(data)[idx]
    return select(data, name)
end

# function select(data::NTuple{N, Any}, d::DimsSelector) where N
#     sz = ntuple(N) do n
#         return n in d.dims ? length(shape[n]) : 1
#     end
#     return "", reshape(CartesianIndices(sz), 1, sz...)
# end

function select(data, x::Pair{<:Any, <:StringLike})
    name, label = x
    _, v = select(data, name)
    return (v,) => identity => string(label)
end

function select(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    # consider supporting automated labeling for multiple names here
    label, v = select(data, name)
    return (v,) => transformation => label
end

function select(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa ArrayLike ? name : fill(name)
    vs = map(name -> last(select(data, name)), names)
    return vs => transformation => label
end

"""
    getlabeledarray(layer::Layer, s)

Return a label and an array from a selector `s`.
"""
getlabeledarray(layer::Layer, s) = getlabeledarray(layer, fill(s))

function getlabeledarray(layer::Layer, selectors::ArrayLike)
    labelsvectors = map(selectors) do s
        vs, (f, label) = select(layer.data, s)
        return label, map(f, vs...)
    end
    return map(first, labelsvectors), map(last, labelsvectors)
end
