struct Trace{NT<:NamedTuple, S<:Select}
    attributes::NT
    select::S
end

function groupselect(p::Product)
    grp = get_type(p, Group)
    select = get_type(p, Select)
    df = get_type(p, Data).table
    df === nothing && return grp, select
    t = columntable(df)
    grp = Group(; extract_columns(t, grp.columns)...)
    select = Select(
                    extract_columns(t, select.args)...;
                    extract_columns(t, select.kwargs)...
                   )
    return grp, select
end

struct ByColumn end
const bycolumn = ByColumn()

extract_column(t, c::ByColumn) = c

function traces(p::Product)
    grp, select = groupselect(p)
    data, named_data = select.args, select.kwargs
    pcols = keepvectors(grp.columns)
    sa = StructArray(map(pool, pcols))
    keys = isempty(pcols) ? (NamedTuple() => Colon(),) : finduniquesorted(sa)

    # Should we use the shape of data rather than presence of `ByColumn`
    # to decide which branch to pick?
    ts = if any(x -> isa(x, ByColumn), grp.columns)
        m = maximum(ncols, data)
        map(Iterators.product(keys, 1:m)) do ((key, idxs), i)
            # everything that is not a `AbstractVector` is a `ByColumn`
            # we replace them with the integer `i`
            key′ = merge(map(_ -> i, grp.columns), key)
            Trace(key′, extract_view(select, idxs, i))
        end
    else
        map(keys) do (key, idxs)
            Trace(key, extract_view(select, idxs))
        end
    end

    analysis = adjust_globally(get_type(p, Analysis), ts)
    metadata = filter(p.elements) do el
        !(el isa Union{Analysis, Data, Group, Select})
    end
    ts′ = [Trace(trace.attributes, analysis(trace.select)) for trace in ts]
    return metadata => ts′
end

traces(s::Sum) = map(traces, s.elements)

traces(args...) = traces(foldl(*, args))
