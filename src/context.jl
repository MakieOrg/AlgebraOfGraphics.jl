abstract type AbstractContext end

struct GroupedContext <: AbstractContext end

group(::GroupedContext, t::AbstractTrace) = t
group(t::AbstractTraceList) = TraceList(map(group, t))

apply_context(c::Union{AbstractContext, Nothing}, m::AbstractTrace) = m

# Column Context

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

group(tr::AbstractTrace) =  group(context(tr), tr)

function _rename(t::Tuple, m::MixedTuple)
    mt = _rename(tail(t), MixedTuple(tail(m.args), m.kwargs))
    MixedTuple((first(t), mt.args...), mt.kwargs)
end
function _rename(t::Tuple, m::MixedTuple{Tuple{}, <:NamedTuple{names}}) where names
    return MixedTuple((), NamedTuple{names}(t))
end

function group(c::ColumnContext, tr::AbstractTrace)
    l = length(first(c.cols))
    p, d, m = primary(tr), data(tr), metadata(tr)
    d = map(wrap_cols, d)
    shape = Broadcast.combine_axes(d...)
    cidxs = CartesianIndices(shape)
    cols = (p.args..., p.kwargs...)
    st = if isempty(cols)
        values = aos(d)
        keys = fill(mixedtuple(), axes(values))
        StructArray((keys = vec(keys), values = vec(values)))
    else
        # TODO do not create unnecessary vectors
        sa = StructArray(map(pool, cols))
        itr = Base.Generator(finduniquesorted(sa)) do (k, idxs)
            v = map(d) do el
                map(t -> view(t, idxs), el)
            end
            values = aos(v)
            keys = [_rename(adjust_all(k, c), p) for c in cidxs]
            StructArray((keys = vec(keys), values = vec(values)))
        end
        collect_structarray_flattened(itr)
    end
    p1, d1 = fieldarrays(st)
    return Trace(GroupedContext(), soa(p1), soa(d1), m)
end

# Default context

struct DefaultContext <: AbstractContext end
context() = context(DefaultContext())

function group(::Union{Nothing, DefaultContext}, t::AbstractTrace)
    p = primary(t)
    d = data(t)
    shape = axes(aos(d))
    p = adjust(p, shape)
    return Trace(GroupedContext(), p, d, metadata(t))
end

