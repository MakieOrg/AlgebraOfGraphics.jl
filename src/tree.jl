abstract type AbstractEdge end

children(s::AbstractEdge) = list(s => nil(AbstractEdge))

# Rooted tree type
struct Tree{T}
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

const TreeLike = Union{Tree, AbstractEdge}

# Join trees by the root
Base.:+(a::TreeLike, b::TreeLike) = Tree(cat(children(a), children(b)))

atleaves(::Nil, l::LinkedList) = l
atleaves(l::LinkedList, l′::LinkedList) = map(((k, v),) -> k => atleaves(v, l′), l)

# Attach the second tree on each leaf of the first
Base.:*(a::TreeLike, b::TreeLike) = Tree(atleaves(children(a), children(b)))

applylist(::Nil) = nil(AbstractEdge)
applylist(tr, ::Nil) = list(tr => nil(AbstractEdge))
applylist(tr, l::LinkedList) = applylist(map(((k, v),) -> k(tr) => v, l))
applylist(l::LinkedList) = cat(applylist(first(l)...), applylist(tail(l)))

(t::Tree)() = Tree(applylist(children(t)))

outputs(t::Tree) = map(first, t())

