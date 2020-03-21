abstract type AbstractContext end

context_pair(c::AbstractContext, p) = c => p
context_pair(c::AbstractContext, p::Pair{<:AbstractContext}) = p
context_pair(c::AbstractContext, m::MixedTuple) = map(x -> context_pair(c, x), m)

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

