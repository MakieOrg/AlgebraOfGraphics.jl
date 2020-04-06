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

(a::Analysis)(args...; kwargs...) = a.f(args...; merge(a.kwargs, values(kwargs))...)

const LayerDict = OrderedDict{Spec, Vector{Style}}

struct Layers <: AbstractGraphical
    layers::LayerDict
end
Layers(s::GraphicalOrContextual) = Layers(layers(s))

layers(s::Layers)             = s.layers
layers(s::Analysis)           = layers(Spec{Any}((s,), NamedTuple()))
layers(s::Spec)               = LayerDict(s => [Style()])
layers(s::AbstractContextual) = LayerDict(Spec() => [Style(s)])

Base.:(==)(s1::Layers, s2::Layers) = layers(s1) == layers(s2)

function Base.:*(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    d = LayerDict()
    for (k1, v1) in pairs(l1)
        for (k2, v2) in pairs(l2)
            k = merge(k1, k2)
            v = Style[merge(a, b) for a in v1 for b in v2]
            d[k] = append!(get(d, k, Style[]), v)
        end
    end
    return Layers(d)
end

function Base.:+(s1::GraphicalOrContextual, s2::GraphicalOrContextual)
    l1, l2 = layers(s1), layers(s2)
    return Layers(merge(vcat, l1, l2))
end

# plotting tools

function extract_names(d::NamedTuple)
    ns = map(get_name, d)
    vs = map(strip_name, d)
    return ns, vs
end

const PairList = Vector{Pair{<:NamedTuple, <:NamedTuple}}

for (f!, f_at!) in [(:push!, :pushat!), (:append!, :appendat!)]
    @eval function $f_at!(d::AbstractDict{<:Any, Vector{T}}, key, val) where {T}
        v = get!(d, key, T[])
        $f!(v, val)
    end
end

function spec_dict(ts::GraphicalOrContextual)
    d = OrderedDict{Spec, PairList}()
    for (sp, ctx) in layers(ts)
        sp0 = Spec{plottype(sp)}((), sp.kwargs)
        init = LittleDict(sp0 => pairs(ctx))
        res = foldl((v, f) -> apply(f, v), sp.args, init=init)
        for (key, val) in pairs(res)
            appendat!(d, key, val)
        end
    end
    return d
end

function apply(f, c::AbstractDict)
    d = OrderedDict{Spec, PairList}()
    for (sp, itr) in c
        for (group, style) in itr
            res = f(positional(style)...; keyword(style)...)
            res isa Union{Tuple, NamedTuple, AbstractDict} || (res = (res,))
            res isa Tuple && (res = namedtuple(res...))
            res isa NamedTuple && (res = LittleDict(spec() => res))
            for (key, val) in pairs(res)
                pushat!(d, merge(sp, key), group => val)
            end
        end
    end
    return d
end

"""
    specs(ts::GraphicalOrContextual, palette)

Compute a vector of `OrderedDict{NamedTuple, Spec}` to be passed to the
plotting package. `palette[key]` must return a finite list of options, for
each `key` used as group (e.g., `color`, `marker`, `linestyle`).
"""
function specs(ts::GraphicalOrContextual, palette)
    serieslist = OrderedDict{NamedTuple, Spec}[]
    for (m, itr) in pairs(spec_dict(ts))
        d = OrderedDict{NamedTuple, Spec}()
        l = (layout_x = nothing, layout_y = nothing)
        discrete_scales = map(DiscreteScale, merge(palette, m.kwargs, l))
        continuous_scales = map(ContinuousScale, m.kwargs)
        for (group, style) in itr
            theme = applytheme(discrete_scales, group)
            names, style = extract_names(style)
            style = applytheme(continuous_scales, style)
            sp = merge(m, Spec{Any}(Tuple(positional(style)), (; keyword(style)..., theme...)))
            d[group] = merge(sp, Spec{Any}((), (; names=names)))
        end
        push!(serieslist, d)
    end
    return serieslist
end

function applytheme(scales, grp::NamedTuple{names}) where names
    res = map(names) do key
        haskey(scales, key) ? attr!(scales[key], grp[key]) : grp[key]
    end
    return NamedTuple{names}(res)
end
