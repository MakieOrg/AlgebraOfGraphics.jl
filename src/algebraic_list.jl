# immutable list object that supports algebraic operations

struct AlgebraicList{T} <: AbstractVector{T}
    parent::Vector{T}
end
AlgebraicList(v) = AlgebraicList(collect(v)::Vector)

Base.parent(v::AlgebraicList) = v.parent

Base.getindex(v::AlgebraicList, i::Int) = parent(v)[i]
Base.axes(v::AlgebraicList) = axes(parent(v))
Base.size(v::AlgebraicList) = size(parent(v))

function Base.:+(l1::AlgebraicList, l2::AlgebraicList)
    v1, v2 = parent(l1), parent(l2)
    return AlgebraicList(vcat(v1, v2))
end

function Base.:*(l1::AlgebraicList, l2::AlgebraicList)
    return AlgebraicList(el1 * el2 for el1 in l1 for el2 in l2)
end