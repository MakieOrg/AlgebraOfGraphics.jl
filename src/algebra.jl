struct Sum{T<:Tuple}
    elements::T
    function Sum(v)
        t = Tuple(v)
        return new{typeof(t)}(t)
    end
end
Sum(l::Sum) = l

_primary(by, i) = mapfoldl(b -> primary(; b => fill(i)), *, by)
Sum(v, by...) = Sum(el * _primary(by, i) for (i, el) in enumerate(v))

const null = Sum(())

to_sum(s::AbstractSpec) = Sum((s,))
to_sum(s::Sum) = s

Base.iterate(p::Sum) = iterate(p.elements)
Base.iterate(p::Sum, st) = iterate(p.elements, st)
Base.length(p::Sum) = length(p.elements)
Base.eltype(::Type{Sum{T}}) where {T} = eltype(T)

function Base.show(io::IO, l::Sum)
    print(io, "Sum")
    _show(io, l.elements...)
end

function *(a::AbstractSpec, b::AbstractSpec)
    consistent(a, b) ? merge(a, b) : null
end

*(t::Sum, b::AbstractSpec) = *(t, to_sum(b))
*(a::AbstractSpec, t::Sum) = *(to_sum(a), t)
*(s::Sum, t::Sum) = foldl(+, (a * b for a in s for b in t), init=null)

+(a::AbstractSpec, b::AbstractSpec) = to_sum(a) + to_sum(b)
+(a::Sum, b::AbstractSpec) = a + to_sum(b)
+(a::AbstractSpec, b::Sum) = to_sum(a) + b
+(a::Sum, b::Sum) = Sum((a.elements..., b.elements...))

function ^(a::Union{Sum, AbstractSpec}, n::Int)
    return foldl(*, ntuple(_ -> a, n))
end


