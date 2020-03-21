struct AbstractContext end

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

function Base.collect(tr::AbstractTrace)
    ctx = context(tr)
    collect_context(ctx, apply_context(ctx, tr))
end

function Base.collect(c::ColumnContext, tr::AbstractTrace)
    p, d, m = primary(tr), data(tr), metadata(tr)
    cols = (p.args..., p.kwargs...)
    vecs = to_vectors(cols...)
    if vecs === nothing
        [Trace(nothing, _rename(map(getindex, cols), p), d, m)]
    else
        # TODO do not create unnecessary vectors
        sa = StructArray(map(pool, vecs))
        map(finduniquesorted(sa)) do (k, idxs)
            Trace(nothing, _rename(k, p), extract_view(d, idxs), m)
        end
    end
end

struct GroupedContext{T} <: AbstractContext
    array::T
end

