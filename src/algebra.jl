struct Sum{T<:Tuple}
    elements::T
    Sum(args...) = new{typeof(args)}(args)
end
Sum(l::Sum) = l

Base.iterate(p::Sum) = iterate(p.elements)
Base.iterate(p::Sum, st) = iterate(p.elements, st)
Base.length(p::Sum) = length(p.elements)
Base.eltype(::Type{Sum{T}}) where {T} = eltype(T)

function Base.show(io::IO, l::Sum)
    print(io, "Sum")
    _show(io, l.elements...)
end

function *(a::AbstractSpec, b::AbstractSpec)
    consistent(a, b) ? merge(a, b) : Sum()
end

*(t::Sum, b::AbstractSpec) = Sum(map(el -> *(el, b), t.elements)...)
*(a::AbstractSpec, t::Sum) = Sum(map(el -> *(a, el), t.elements)...)

function *(s::Sum, t::Sum)
    f = *(s, first(t.elements))
    ls = *(s, Sum(tail(t.elements)...))
    return f + ls
end
*(s::Sum, ::Sum{Tuple{}}) = Sum()

+(a::AbstractSpec, b::AbstractSpec) = Sum(a) + Sum(b)
+(a::Sum, b::AbstractSpec) = a + Sum(b)
+(a::AbstractSpec, b::Sum) = Sum(a) + b
+(a::Sum, b::Sum) = Sum(a.elements..., b.elements...)
