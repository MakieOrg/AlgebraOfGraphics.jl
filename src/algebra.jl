abstract type AbstractElement end

struct Product{T<:Tuple} <: AbstractElement
    elements::T
    Product(args...) = new{typeof(args)}(args)
end
Product(l::Product) = l

Base.iterate(p::Product) = iterate(p.elements)
Base.iterate(p::Product, st) = iterate(p.elements, st)
Base.length(p::Product) = length(p.elements)
Base.eltype(::Type{Product{T}}) where {T} = eltype(T)

function Base.show(io::IO, l::Product)
    print(io, "Product")
    _show(io, l.elements...)
end

*(a::AbstractElement, b::AbstractElement) = Product(a) * Product(b)
*(a::Product, b::Product) = Product(a.elements..., b.elements...)

combine(a, b) = merge(a, b)

function get(p::Product, T::Type, init = T())
    vals = p.elements
    foldl(combine, Iterators.filter(x -> isa(x, T), vals), init=init)
end

struct Sum{T<:Tuple} <: AbstractElement
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

*(t::Sum, b::AbstractElement) = Sum(map(el -> el * b, t.elements)...)
*(a::AbstractElement, t::Sum) = Sum(map(el -> a * el, t.elements)...)
function *(s::Sum, t::Sum)
    f = (s * first(t.elements))
    ls = (s * Sum(tail(t.elements)...))
    return f + ls
end
*(s::Sum, ::Sum{Tuple{}}) = Sum()

+(a::AbstractElement, b::AbstractElement) = Sum(a) + Sum(b)
+(a::Sum, b::Sum) = Sum(a.elements..., b.elements...)
