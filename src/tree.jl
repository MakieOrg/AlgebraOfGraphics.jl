# Rooted tree type
struct Tree{T}
    list::LinkedList{T}
end
Tree(s::Tree) = s

tree(m) = Tree(list(m => list()))

Base.iterate(t::Tree) = iterate(t.list)
Base.iterate(t::Tree, i) = iterate(t.list, i)
Base.length(t::Tree) = length(t.list)
Base.eltype(::Type{Tree{T}}) where {T} = T

function Base.show(io::IO, s::Tree)
    print(io, "Tree")
end

# Join trees by the root
Base.:+(a::Tree, b::Tree) = Tree(cat(a.list, b.list))

atleaves(::Nil, l::LinkedList) = l
atleaves(l::LinkedList, l′::LinkedList) = map(((k, v),) -> k => atleaves(v, l′), l)

# Attach the second tree on each leaf of the first
Base.:*(a::Tree, b::Tree) = Tree(atleaves(a.list, b.list))

applylist(::Nil) = list()
applylist(tr, ::Nil) = list(tr => list())
applylist(tr, l::LinkedList) = applylist(map(((k, v),) -> k(tr) => v, l))
applylist(l::LinkedList) = cat(applylist(first(l)...), applylist(tail(l)))

(t::Tree)() = Tree(applylist(t.list))
(t::Tree)(x::Tree) = (x * t)()

outputs(t::Tree) = map(first, t())

