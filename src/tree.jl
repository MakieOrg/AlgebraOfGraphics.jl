abstract type AbstractTree end
abstract type AbstractRoot <: AbstractTree end

children(s::AbstractRoot) = list(s => list())

# Rooted tree type
struct Tree{T} <: AbstractTree
    list::LinkedList{T}
end
Tree(s::Tree) = s
children(s::Tree) = s.list

Base.iterate(t::Tree) = iterate(t.list)
Base.iterate(t::Tree, i) = iterate(t.list, i)
Base.length(t::Tree) = length(t.list)
Base.eltype(::Type{Tree{T}}) where {T} = T

function Base.show(io::IO, s::Tree)
    print(io, "Tree")
end

# Join trees by the root
Base.:+(a::AbstractTree, b::AbstractTree) = Tree(cat(children(a), children(b)))

atleaves(::Nil, l::LinkedList) = l
atleaves(l::LinkedList, l′::LinkedList) = map(((k, v),) -> k => atleaves(v, l′), l)

# Attach the second tree on each leaf of the first
Base.:*(a::AbstractTree, b::AbstractTree) = Tree(atleaves(children(a), children(b)))

applylist(::Nil) = list()
applylist(tr, ::Nil) = list(tr => list())
applylist(tr, l::LinkedList) = applylist(map(((k, v),) -> k(tr) => v, l))
applylist(l::LinkedList) = cat(applylist(first(l)...), applylist(tail(l)))

@static if VERSION < v"1.3.0"
    (t::Tree)() = Tree(applylist(children(t)))
else
    (t::AbstractTree)() = Tree(applylist(children(t)))
end

outputs(t::Tree) = map(first, t())

