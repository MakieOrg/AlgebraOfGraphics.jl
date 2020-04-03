abstract type AbstractGraphical end

const GraphicalOrContextual = Union{AbstractGraphical, AbstractContextual}

struct Spec{T} <: AbstractGraphical
    args::Tuple
    kwargs::NamedTuple
end
Spec() = Spec{Any}((), NamedTuple())

spec(args...; kwargs...) = Spec{Any}(args, values(kwargs))
spec(T::Union{Type, Symbol}, args...; kwargs...) = Spec{T}(args, values(kwargs))

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    args = (t1.args..., t2.args...)
    kwargs = merge(t1.kwargs, t2.kwargs)
    return Spec{T}(args, kwargs)
end

function Base.:(==)(s1::Spec, s2::Spec)
    return plottype(s1) === plottype(s2) && s1.args == s2.args && s1.kwargs == s2.kwargs
end

Base.hash(a::Spec, h::UInt64) = hash((a.args, a.kwargs), hash(typeof(a), h))

struct Analysis{F} <: AbstractGraphical
    f::F
    kwargs::NamedTuple
end

Analysis(f; kwargs...) = Analysis(f, values(kwargs))

(a::Analysis)(; kwargs...) = Analysis(a.f, merge(a.kwargs, values(kwargs)))

(a::Analysis)(c) = a.f(c)

struct Layers <: AbstractGraphical
    layers::Vector{Pair{Spec, ContextualMap}}
end
Layers(s::GraphicalOrContextual) = Layers(layers(s))

layers(s::Layers)             = s.layers
layers(s::Analysis)           = layers(Spec{Any}((s,), NamedTuple()))
layers(s::Spec)               = Pair{Spec, ContextualMap}[s => ContextualMap()]
layers(s::AbstractContextual) = Pair{Spec, ContextualMap}[Spec() => ContextualMap(s)]

Base.:(==)(s1::Layers, s2::Layers) = layers(s1) == layers(s2)

function Base.:*(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    v = Pair{Spec, ContextualMap}[]
    for el1 in l1
        for el2 in l2
            push!(v, merge(first(el1), first(el2)) => last(el1) * last(el2))
        end
    end
    return Layers(v)
end

function Base.:+(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    return Layers(vcat(l1, l2))
end

# plotting tools

function extract_names(d::NamedTuple)
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

struct Scale
    scale::Observable
    values::Observable
end

to_scale(nt::NamedTuple) = map(to_scale, nt)
function to_scale(v)
    Scale(convert(Observable, v), Observable(Any[]))
end
to_scale() = to_scale(Observable(nothing))

function getrank(value, values)
    for (i, v) in enumerate(unique(sort(values)))
        v == value && return i
    end
    return nothing
end

function attr!(s::Scale, value)
    value in s.values[] || (s.values[] = push!(s.values[], value))
    map(s.scale, s.values) do scale, values
        n = getrank(value, values)
        scale === nothing ? n : scale[mod1(n, length(scale))]
    end
end

const PairList = Vector{Pair{<:NamedTuple, <:NamedTuple}}

for (f!, f_at!) in [(:push!, :pushat!), (:append!, :appendat!)]
    @eval function $f_at!(d::AbstractDict{<:Any, T}, key, val) where {T <: AbstractVector}
        v = get!(d, key, T[])
        $f!(v, val)
    end
end

function spec_dict(ts::GraphicalOrContextual)
    d = OrderedDict{Spec, PairList}()
    for (sp, ctx) in layers(ts)
        f = foldl((a, b) -> b ∘ a, sp.args, init=identity)
        sp0 = Spec{plottype(sp)}((), sp.kwargs)
        res = f(LittleDict(sp0 => pairs(ctx)))
        for (key, val) in pairs(res)
            appendat!(d, key, val)
        end
    end
    return d
end

"""
    specs(ts::GraphicalOrContextual, palette)

Compute a vector of `OrderedDict{NamedTuple, Spec}` to be passed to the
plotting package. `palette[key]` must return a finite list of options, for
each `key` used as primary (e.g., `color`, `marker`, `linestyle`).
"""
function specs(ts::GraphicalOrContextual, palette)
    serieslist = OrderedDict{NamedTuple, Spec}[]
    for (m, itr) in spec_dict(ts)
        d = OrderedDict{NamedTuple, Spec}()
        l = (layout_x = nothing, layout_y = nothing)
        scales = to_scale(merge(palette, m.kwargs, l))
        for (primary, data) in itr
            theme = applytheme(scales, primary)
            names, data = extract_names(data)
            sp = merge(m, Spec{Any}(Tuple(positional(data)), (; keyword(data)..., theme...)))
            d[primary] = merge(sp, Spec{Any}((), (; names=names)))
        end
        push!(serieslist, d)
    end
    return serieslist
end

applytheme(scale, val) = attr!(scale, val)
function applytheme(scales, grp::NamedTuple{names}) where names
    res = map(names) do key
        applytheme(scales[key], grp[key])
    end
    return NamedTuple{names}(res)
end
