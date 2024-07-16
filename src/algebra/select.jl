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

function select(data::Columns, name::Union{Symbol, AbstractString})
    v = getcolumn(data.columns, Symbol(name))
    return (v,) => identity => to_string(name) => nothing
end

function select(data::Columns, idx::Integer)
    name = columnnames(data.columns)[idx]
    return select(data, name)
end

function select(::Nothing, shape, selector)
    if selector isa Pair
        vs, rest = selector
        fn(x::Pair) = fn(x[1], x[2])
        fn(x::Function) = x, "", nothing
        fn(x::ScaleID) = identity, "", x
        fn(x) = identity, x, nothing
        fn(x::Function, y::Pair) = x, y[1], y[2]
        fn(x::Function, y::ScaleID) = x, "", y
        fn(x::Function, y) = x, y, nothing
        fn(x, y::ScaleID) = identity, x, y

        f, label, scaleid = fn(rest)
    else
        vs = selector
        f = identity
        label = ""
        scaleid = nothing
    end

    # Makie doesn't like getting zero-dimensional arrays, so if we have only scalars
    # we make one-element vectors instead
    non_zerodim_shape(s::Tuple{}) = (Base.OneTo(1),)
    non_zerodim_shape(s) = s

    if !(vs isa AbstractArray)
        vs = [vs for _ in CartesianIndices(non_zerodim_shape(shape))]
    end

    return (vs,), (f, (label, scaleid))
end

select(::Pregrouped, v::AbstractArray) = (v,) => identity => "" => nothing

function select(data, x::Pair{<:Any, <:Union{Symbol, AbstractString}})
    name, label = x
    vs, _ = select(data, name)
    return vs => identity => to_string(label) => nothing
end

function select(data::Columns, direct::DirectData{T}) where T
    arr = if T <: AbstractArray{1}
        direct.data
    elseif T <: AbstractArray
        throw(ArgumentError("It's currently not allowed to use arrays that are not one-dimensional (column vectors) as direct data."))
    else
        nrows = length(rows(data.columns))
        fill(direct.data, nrows)
    end
    (arr,) => identity => "" => nothing
end

function select(data, x::Pair{<:Any, <:Any})
    name, transformation = x
    if name isa Tuple
        vs = map(name) do n
            only(first(select(data, n)))
        end
        label = ""
    else
        vs, (_, (label, _)) = select(data, name)
    end
    return vs => transformation => label => identity
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
