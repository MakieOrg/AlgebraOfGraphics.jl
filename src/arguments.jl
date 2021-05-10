const KeyType = Union{Symbol, Int}

struct Arguments
    keys::Vector{KeyType}
    values::Vector{Any}
end

Arguments(v::AbstractVector) = Arguments(eachindex(v), v)

Base.keys(a::Arguments) = a.keys
Base.values(a::Arguments) = a.values
Base.pairs(a::Arguments) = Iterators.map(Pair, keys(a), values(a))

function arguments(args...; kwargs...)
    k = (keys(args)..., keys(kwargs)...)
    v = (values(args)..., values(kwargs)...)
    return Arguments(collect(KeyType, k), collect(Any, v))
end

Base.haskey(args::Arguments, key::KeyType) = key in keys(args)

to_idx(args::Arguments, key::KeyType) = findfirst(==(key), keys(args))
from_idx(args::Arguments, idx) = values(args)[idx]

function Base.get(args::Arguments, key::KeyType, default)
    idx = to_idx(args, key)
    return isnothing(idx) ? default : values(args)[idx]
end
Base.getindex(args::Arguments, key::KeyType) = from_idx(args, to_idx(args, key))

function Base.setindex!(args::Arguments, val, key::KeyType)
    idx = to_idx(args, key)
    if isnothing(idx)
        push!(keys(args), key)    
        push!(values(args), val)
    else
        values(args)[idx] = val
    end
    return val
end

function Base.pop!(args::Arguments, key::KeyType, default)
    idx = to_idx(args, key)
    if isnothing(idx)
        return default
    else
        deleteat!(keys(args), idx)
        return deleteat!(values(args), idx)
    end
end

Base.copy(args::Arguments) = Arguments(copy(keys(args)), copy(values(args)))

function Base.map(f, a::Arguments, as::Arguments...)
    keys = a.keys
    values = [f(map(t -> t[key], (a, as...))...) for key in keys]
    return Arguments(keys, values)
end

function Base.mergewith!(op, a::Arguments, b::Arguments)
    for (key, value) in pairs(b)
        idx = to_idx(a, key)
        if isnothing(idx)
            push!(keys(a), key)
            push!(values(a), value)
        else
            values(a)[idx] = op(values(a)[idx], value)
        end
    end
    return a
end

latter(_, b) = b

Base.merge!(a::Arguments, b::Arguments) = mergewith!(latter, a, b)

Base.merge(a::Arguments, b::Arguments) = merge!(copy(a), b)

function separate!(continuous::Arguments)
    discrete = LittleDict{Symbol, Any}()
    for (k, v) in continuous.named
        label, value = getlabel(v), getvalue(v)
        iscontinuous(value) && continue
        discrete[k] = Labeled(label, first(value))
        pop!(continuous.named, k)
    end
    return NamedTuple(discrete) => continuous
end

function recombine!(discrete, continuous)
    for (k, v) in pairs(discrete)
        label, value = getlabel(v), getvalue(v)
        continuous[k] = Labeled(label, fill(value))
    end
    return continuous
end