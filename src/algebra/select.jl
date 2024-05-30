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

select(data, d::DimsSelector) = (d,) => identity => "" => nothing

function select(data, name::Union{Symbol, AbstractString})
    v = getcolumn(data, Symbol(name))
    return (v,) => identity => to_string(name) => nothing
end

function select(data, idx::Integer)
    name = columnnames(data)[idx]
    return select(data, name)
end

select(::Nothing, v::AbstractArray) = (v,) => identity => "" => nothing

function select(data, x::Pair{<:Any, <:Union{Symbol, AbstractString}})
    name, label = x
    vs, _ = select(data, name)
    return vs => identity => to_string(label) => nothing
end

function select(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    if name isa Tuple
        vs = map(n -> only(first(select(data, n))), name)
        label = ""
    else
        vs, (_, label) = select(data, name)
    end
    return vs => transformation => label => nothing
end

function select(data, x::Pair{<:Any, <:Pair})
    name, transformation_label = x
    transformation, label = transformation_label
    names = name isa Tuple ? name : (name,)
    vs = map(n -> only(first(select(data, n))), names)
    return vs => transformation => label => nothing
end

function select(data, x::Pair{<:Any, <:Pair{<:Any, ScaleID}})
    (vs, (transf, (label, _))) = select(data, x[1] => x[2][1])
    return vs => transf => label => x[2][2]
end

function select(data, x::Pair{<:Any, ScaleID})
    (vs, (transf, (label, _))) = select(data, x[1])
    return vs => transf => label => x[2]
end
