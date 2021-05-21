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

select(data, d::DimsSelector) = (d,) => identity => ""

function select(data, name::StringLike)
    v = getcolumn(data, Symbol(name))
    return (v,) => identity => string(name)
end

function select(data, idx::Integer)
    name = columnnames(data)[idx]
    return select(data, name)
end

function select(data, x::Pair{<:Any, <:StringLike})
    name, label = x
    vs, _ = select(data, name)
    return vs => identity => string(label)
end

function select(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    # consider supporting automated labeling for multiple names here
    vs, (_, label) = select(data, name)
    return vs => transformation => label
end

function select(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa ArrayLike ? name : fill(name)
    vs = map(name -> only(first(select(data, name))), names)
    return vs => transformation => label
end
