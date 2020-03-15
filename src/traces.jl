struct Traces{S}
    list::S # iterates attributes => Select pairs
end
Traces(t::Traces) = t

Traces(s::Select) = Traces([NamedTuple() => s])

function combine(t1::Traces, t2::Traces)
    itr = zip(t1.list, t2.list)
    Traces[combine(a1, a2) => combine(sel1, sel2) for ((a1, sel2), (a2, sel2)) in itrs]
end

combine(s::Select, t::Traces) = combine(Traces(s), t)
combine(t::Traces, s::Select) = combine(t, Traces(s))

Traces(s::Select, g::Group) = Traces(Traces(s), g)

function Traces(t::Traces, g::Group)
    isempty(g.columns) && return t
    sa = StructArray(map(pool, pcols))
    itr = finduniquesorted(sa)
    list = [merge(a, k) => extract_view(s, idxs) for (k, idxs) in itr for (a, s) in t.list]
    return Traces(list)
end

function Traces(p::Product)
    data = get(p, Data, Data())
    grp = extract_columns(data, get(p, Group, Group()))
    ts = extract_columns(data, get(p, Union{Select, Traces}, Select()))
    an = get(p, Analysis, Analysis())
    return an(Traces(ts, grp))
end

function metadata(p::Product)
    AoG = Union{Data, Group, Analysis, Traces, Select}
    Iterators.filter(x -> !isa(x, AoG), p.elements)
end
