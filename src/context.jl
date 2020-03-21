abstract type AbstractContext end

function merge(c::Union{Nothing, AbstractContext}, s1::AbstractTrace, s2::AbstractTrace)
    primary = merge(s1.primary, s2.primary)
    data = merge(s1.data, s2.data)
    metadata = merge(s1.metadata, s2.metadata)
    return Trace(c, primary, data, metadata)
end

apply_context(c::AbstractContext, m::AbstractTrace) = m

struct NullContext <: AbstractContext end
const nullcontext = NullContext()
context() = context(nullcontext)

struct ColumnContext{T} <: AbstractContext
    cols::T
end
table(x) = context(ColumnContext(columntable(x)))

function apply_context(c::ColumnContext, tr::AbstractTrace)
    p = extract_column(c.cols, primary(tr))
    d = extract_column(c.cols, data(tr))
    m = metadata(tr) # TODO: add labels here
    return Trace(nothing, p, d, m)
end

function group(tr::AbstractTrace)
    ctx = context(tr)
    group(ctx, apply_context(ctx, tr))
end

function _rename(t::Tuple, m::MixedTuple)
    mt = _rename(tail(t), MixedTuple(tail(m.args), m.kwargs))
    MixedTuple((first(t), mt.args...), mt.kwargs)
end
function _rename(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return MixedTuple((), NamedTuple{names}(t))
end

function to_vectors(vs...)
    i = findfirst(t -> isa(t, AbstractVector), vs)
    i === nothing && return nothing
    map(vs) do v
        v isa AbstractVector ? v : fill(v[], length(vs[i]))
    end
end

function group(c::ColumnContext, tr::AbstractTrace)
    p, d, m = primary(tr), data(tr), metadata(tr)
    cols = (p.args..., p.kwargs...)
    vecs = to_vectors(cols...)
    if vecs === nothing
        p1 = [_rename(map(getindex, cols), p)]
        d1 = [d]
    else
        # TODO do not create unnecessary vectors
        sa = StructArray(map(pool, vecs))
        itr = Base.Generator(finduniquesorted(sa)) do (k, idxs)
            _rename(k, p) => extract_view(d, idxs)
        end
        p1, d1 = fieldarrays(StructArray(itr))
    end
    return Trace(groupedcontext, soa(p1), soa(d1), m)
end

struct GroupedContext <: AbstractContext end
const groupedcontext = GroupedContext()

group(::GroupedContext, t::AbstractTrace) = t
group(t::AbstractTraceList) = TraceList(map(group, t))

function merge_mixed(m1::MixedTuple, m2::MixedTuple, l1, l2)
    n1 = map(arg -> repeat(arg, inner = l2), m1)
    n2 = map(arg -> repeat(arg, outer = l1), m2)
    return merge(n1, n2)
end

function merge(c::GroupedContext, t1::AbstractTrace, t2::AbstractTrace)
    m = merge(metadata(t1), metadata(t2))
    p1, p2 = map(collect, primary(t1)), map(collect, primary(t2))
    d1, d2 = map(collect, data(t1)), map(collect, data(t2))
    pd1, pd2 = merge(p1, d1), merge(p2, d2)
    l1 = isempty(pd1) ? 1 : length(first(pd1))
    l2 = isempty(pd2) ? 1 : length(first(pd2))
    p = merge_mixed(p1, p2, l1, l2)
    d = merge_mixed(d1, d2, l1, l2)
    return Trace(c, p, d, m)
end
