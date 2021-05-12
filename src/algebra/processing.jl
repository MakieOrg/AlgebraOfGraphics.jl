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

struct Labeled{T}
    label::AbstractString
    value::T
end

Labeled(x) = Labeled(getlabel(x), getvalue(x))

getlabel(x::Labeled) = x.label
getvalue(x::Labeled) = x.value

getlabel(x) = ""
getvalue(x) = x

function process_data(data, positional′, named′)
    positional, named = map((positional′, named′)) do tup
        return map(x -> map(Base.Fix1(NameTransformationLabel, data), maybewrap(x)), tup)
    end
    axs = Broadcast.combine_axes(positional..., named...)
    labeledarrays = map((positional, named)) do tup
        return map(tup) do ntls
            names = map(ntl -> ntl.name, ntls)
            transformations = map(ntl -> ntl.transformation, ntls)
            labels = map(ntl -> ntl.label, ntls)
            res = map(transformations, names) do transformation, name
                cols = apply_context(data, axs, maybewrap(name))
                map(transformation, cols...)
            end
            return Labeled(join(unique(labels), ' '), unnest(res))
        end
    end
    return Entry(Any, labeledarrays..., Dict{Symbol, Any}())
end

process_transformations(layers::Layers) = map(process_transformations, layers)

function process_transformations(layer::Layer)
    init = process_data(layer.data, layer.positional, layer.named)
    res = foldl(process_transformations, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process_transformations(v::AbstractArray{Entry}, f) = map(f, v)

process_transformations(le::Entry, f) = f(le)
