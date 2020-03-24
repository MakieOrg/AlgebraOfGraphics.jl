# Combine different `Trace`s in a `Tree` object

struct Tree{T}
    list::LinkedList{T}
end
Tree(s::Tree) = s
Tree(t::AbstractTrace) = tree(t)

tree(m) = Tree(list(m => list()))

Base.iterate(t::Tree) = iterate(t.list)
Base.iterate(t::Tree, i) = iterate(t.list, i)
Base.length(t::Tree) = length(t.list)
Base.eltype(::Type{Tree{T}}) where {T} = T

function Base.show(io::IO, s::Tree)
    print(io, "Tree")
end

function Base.:+(a::Union{AbstractTrace, Tree}, b::Union{AbstractTrace, Tree})
    a = Tree(a)
    b = Tree(b)
    return Tree(cat(a.list, b.list))
end

function leafconcat(l1::LinkedList, l2::LinkedList)
    isempty(l1) && return list()
    trace, ll = first(l1)
    t = isempty(ll) ? l2 : leafconcat(ll, l2)
    return cons(trace => t, leafconcat(tail(l1), l2))
end

function Base.:*(a::Union{AbstractTrace, Tree}, b::Union{AbstractTrace, Tree})
    a = Tree(a)
    b = Tree(b)
    return Tree(leafconcat(a.list, b.list))
end

function applylist(l::LinkedList)
    l′ = map(l) do (tr, ll)
        (_ -> tr) => ll
    end
    return applylist(l′, nothing)
end

function applylist(l::LinkedList, x)
    isempty(l) && return list()
    trace, ll = first(l)
    t = isempty(ll) ? list(trace(x)) : applylist(ll, trace(x))
    return cat(t, applylist(tail(l), x))
end

shallowtree(ls::LinkedList) = Tree(map(val -> val => list(), ls))

(t::Tree)() = shallowtree(applylist(t.list))
(t::Tree)(x) = shallowtree(applylist(t.list, x))

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

primarytable(t::AbstractTrace) = fieldarrays(StructArray(p for (p, _) in pairs(t)))

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

rankdicts(ts) = map(rankdict, jointable(map(primarytable, ts)))
