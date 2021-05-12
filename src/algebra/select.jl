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

function apply_context(data, axs, names::ArrayLike)
    return map(name -> apply_context(data, axs, name), names)
end

apply_context(data, axs, name::StringLike) = getcolumn(data, Symbol(name))

function apply_context(data, axs, idx::Integer)
    name = columnnames(data)[idx]
    return getcolumn(data, name)
end

function apply_context(data, axs::NTuple{N, Any}, d::DimsSelector) where N
    sz = ntuple(N) do n
        return n in d.dims ? length(axs[n]) : 1
    end
    return reshape(CartesianIndices(sz), 1, sz...)
end

struct Labeled{S, T}
    label::S
    value::T
end

Labeled(x) = Labeled(getlabel(x), getvalue(x))

getlabel(x::Labeled) = x.label
getvalue(x::Labeled) = x.value

getlabel(x) = ""
getvalue(x) = x
