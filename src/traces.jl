struct Trace
    attributes::NamedTuple
    select::Select
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

Base.isless(::ByColumn, ::ByColumn) = false
extract_column(t, c::ByColumn) = c

function traces(p::Product)
    grp, select = groupselect(p)
    data, named_data = select.args, select.kwargs
    len = column_length(data)
    pcols = map(t -> t isa AbstractVector ? t : fill(t, len), grp.columns)
    sa = isempty(pcols) ? fill(NamedTuple(), len) : StructArray(pcols)
    keys = finduniquesorted(sa)

    ts = Trace[]
    for (key, idxs) in keys
        if any(x -> isa(x, ByColumn), key)
            m = maximum(ncols, data)
            for i in 1:m
                new_key = map(x -> x isa ByColumn ? i : x, key)
                push!(ts, Trace(new_key, extract_view(select, idxs, i)))
            end
        else
            push!(ts, Trace(key, extract_view(select, idxs)))
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

traces(args...) = traces(foldl(⊗, args))
