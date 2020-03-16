abstract type AbstractElement end

*(a::AbstractElement, b::AbstractElement) = merge(a, b)

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

*(t::Sum, b::AbstractElement) = Sum(map(el -> *(el, b), t.elements)...)
*(a::AbstractElement, t::Sum) = Sum(map(el -> *(a, el), t.elements)...)
function *(s::Sum, t::Sum)
    f = *(s, first(t.elements))
    ls = *(s, Sum(tail(t.elements)...))
    return f + ls
end
*(s::Sum, ::Sum{Tuple{}}) = Sum()

+(a::AbstractElement, b::AbstractElement) = Sum(a) + Sum(b)
+(a::Sum, b::Sum) = Sum(a.elements..., b.elements...)

function merge(t1::Traces, t2::Traces)
    itr = Iterators.filter(consistent, Iterators.product(t1.list, t2.list))
    list = [merge(a1, a2) => merge(sel1, sel2) for ((a1, sel1), (a2, sel2)) in itr]
    return Traces(list)
end

# function Traces(g::Group, t::Traces)
#     isempty(g.columns) && return t
#     sa = StructArray(map(pool, g.columns))
#     itr = finduniquesorted(sa)
#     list = [merge(k, a) => extract_view(s, idxs) for (k, idxs) in itr for (a, s) in t.list]
#     return Traces(list)
# end

# function Traces(p::Product)
#     data = get(p, Data, Data())
#     grp = extract_columns(data, get(p, Group, Group()))
#     ts = extract_columns(data, get(p, Union{Select, Traces}, Select()))
#     an = get(p, Analysis, Analysis())
#     return an(Traces(grp, ts))
# end

