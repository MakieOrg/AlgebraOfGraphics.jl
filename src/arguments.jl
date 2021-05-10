struct Arguments
    positional::Vector{Any}
    named::Dict{Symbol, Any}
end

Arguments(v::AbstractVector) = Arguments(v, Dict{Symbol, Any}())

function arguments(args...; kwargs...)
    positional = collect(Any, args)
    named = Dict{Symbol, Any}(kwargs)
    return Arguments(positional, named)
end

Base.get(args::Arguments, i::Int, default) = get(args.positional, i, default)
Base.get(args::Arguments, sym::Symbol, default) = get(args.named, sym, default)

Base.haskey(args::Arguments, i::Int) = haskey(args.positional, i)
Base.haskey(args::Arguments, sym::Symbol) = haskey(args.named, sym)

Base.getindex(args::Arguments, i::Int) = args.positional[i]
Base.getindex(args::Arguments, sym::Symbol) = args.named[sym]

Base.setindex!(args::Arguments, val, i::Int) = (args.positional[i] = val)
Base.setindex!(args::Arguments, val, sym::Symbol) = (args.named[sym] = val)

Base.pop!(args::Arguments, i::Int, default) = pop!(args.positional, i, default)
Base.pop!(args::Arguments, sym::Symbol, default) = pop!(args.named, sym, default)

Base.copy(args::Arguments) = Arguments(copy(args.positional), copy(args.named))

function Base.map(f, a::Arguments, as::Arguments...)
    is = eachindex(a.positional)
    ks = keys(a.named)
    function g(i)
        vals = map(t -> t[i], (a, as...))
        return f(vals...)
    end
    positional = collect(Any, Iterators.map(g, is))
    named = Dict{Symbol, Any}(k => g(k) for k in ks)
    return Arguments(positional, named)
end

function Base.mergewith!(op, a::Arguments, b::Arguments)
    la, lb = length(a.positional), length(b.positional)
    for i in 1:lb
        (i ≤ la) ? (a[i] = op(a[i], b[i])) : push!(a.positional, b[i])
    end
    mergewith!(op, a.named, b.named)
    return a
end

latter(_, b) = b

Base.merge!(a::Arguments, b::Arguments) = mergewith!(latter, a, b)

Base.merge(a::Arguments, b::Arguments) = merge!(copy(a), b)

function separate!(continuous::Arguments)
    discrete = Dict{Symbol, Any}()
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