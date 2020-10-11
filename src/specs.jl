Base.@kwdef struct Spec{T} <: AbstractElement
    analyses::Tuple=()
    pkeys::NamedTuple=NamedTuple()
    bind::Bind=Bind()
    options::NamedTuple=NamedTuple()
end

Spec(ctx::AbstractContext) = Spec{Any}(bind=Bind(ctx))
Spec(bind::Bind) = Spec{Any}(bind=bind)
Spec(s::Spec) = s

visual(args...; kwargs...) = Spec{Any}(options=namedtuple(args...; kwargs...))
visual(T::Union{Type, Symbol}, args...; kwargs...) = Spec{T}(options=namedtuple(args...; kwargs...))

@deprecate spec(args...; kwargs...) visual(args...; kwargs...)

plottype(::Spec{T}) where {T} = T

function Base.merge(t1::Spec{T1}, t2::Spec{T2}) where {T1, T2}
    T = T2 === Any ? T1 : T2
    analyses = (t1.analyses..., t2.analyses...)
    pkeys = merge(t1.pkeys, t2.pkeys)
    bind = merge(t1.bind, t2.bind)
    options = merge(t1.options, t2.options)
    return Spec{T}(analyses, pkeys, bind, options)
end

Base.:*(a1::AbstractElement, a2::AbstractElement) = merge(Spec(a1), Spec(a2))

layers(g::AbstractElement) = AlgebraicList([Spec(g)])
layers(g::AlgebraicList) = g

Base.:*(s1::AbstractElement, s2::AlgebraicList) = layers(s1) * s2
Base.:*(s1::AlgebraicList, s2::AbstractElement) = s1 * layers(s2)

const ElementOrList = Union{AbstractElement, AlgebraicList}

Base.:+(s1::ElementOrList, s2::ElementOrList) = layers(s1) + layers(s2)

# pipeline

# Expand pairs and run the analyses
function expand(sp::Spec{T}) where {T}
    analyses, pkeys, bind, options = sp.analyses, sp.pkeys, sp.bind, sp.options
    @assert isempty(pkeys)
    v = [Spec{T}(bind=val, pkeys=key, options=options) for (key, val) in pairs(bind)]
    list = AlgebraicList(v)
    return foldl((ls, an) -> apply(an, ls), analyses, init=list)
end

global_options(f, d::AlgebraicList) = NamedTuple()

# default fallback to apply a callable to a vector of key => value pairs
# if customized, it must return a vector of key => value pairs
function apply(f, d::AlgebraicList)
    global_kwargs = global_options(f, d)
    v = map(parent(d)) do layer
        analyses, pkeys, bind, options = layer.analyses, layer.pkeys, layer.bind, layer.options
        T = plottype(layer)
        args, kwargs = split(bind.value)
        res = f(args...; global_kwargs..., kwargs...) * Spec{T}(analyses=analyses, options=options, pkeys=pkeys)
        return parent(layers(res))
    end
    return AlgebraicList(reduce(vcat, v))
end

# Expand binds, apply analyses, compute scales, and return vector of traces
function run_pipeline(s::ElementOrList)
    nested = [parent(expand(layer)) for layer in layers(s)]
    computescales(reduce(vcat, nested))
end
