struct Group{NT<:NamedTuple} <: AbstractElement
    columns::NT
    function Group(; kwargs...)
        nt = values(kwargs)
        return new{typeof(nt)}(nt)
    end
end

function Base.show(io::IO, g::Group)
    print(io, "Group")
    _show(io; g.columns...)
end

combine(g1::Group, g2::Group) = Group(; merge(g1.columns, g2.columns)...)

struct Select{T<:Tuple, NT<:NamedTuple} <: AbstractElement
    args::T
    kwargs::NT
    function Select(args...; kwargs...)
        nt = values(kwargs)
        return new{typeof(args), typeof(nt)}(args, nt)
    end
end
Select(s::Select) = s

function Base.show(io::IO, s::Select)
    print(io, "Select")
    _show(io, s.args...; s.kwargs...)
end

function combine(s1::Select, s2::Select)
    return Select(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)
end

# Maybe store in memory as two separate lists?
struct Traces{S} <: AbstractElement
    list::S # iterates attributes => Select pairs
    function Traces(l)
        list = map(l) do (a, s)
            a => Select(s)
        end
        new{typeof(list)}(list)
    end
end
Traces(t::Traces) = t

Traces(s::Select) = Traces([NamedTuple() => s])

Base.iterate(p::Traces) = iterate(p.list)
Base.iterate(p::Traces, st) = iterate(p.list, st)
Base.length(p::Traces) = length(p.list)
Base.axes(p::Traces) = axes(p.list)
Base.eltype(::Type{Traces{T}}) where {T} = eltype(T)

Base.IteratorEltype(::Type{Traces{T}}) where {T} = Base.IteratorEltype(T)
Base.IteratorSize(::Type{Traces{T}}) where {T} = Base.IteratorSize(T)

function Base.show(io::IO, ts::Traces)
    print(io, "Traces(")
    _show(io, ts...)
    print(io, ")")
end

function combine(t1::Traces, t2::Traces)
    itr = Iterators.filter(consistent, Iterators.product(t1.list, t2.list))
    list = [combine(a1, a2) => combine(sel1, sel2) for ((a1, sel1), (a2, sel2)) in itr]
    return Traces(list)
end

combine(s::Select, t::Traces) = combine(Traces(s), t)
combine(t::Traces, s::Select) = combine(t, Traces(s))

Traces(g::Group, s::Select) = Traces(g, Traces(s))

Traces(a, b) = Traces(zip(a, b))

function Traces(g::Group, t::Traces)
    isempty(g.columns) && return t
    sa = StructArray(map(pool, g.columns))
    itr = finduniquesorted(sa)
    list = [merge(k, a) => extract_view(s, idxs) for (k, idxs) in itr for (a, s) in t.list]
    return Traces(list)
end

function Traces(p::Product)
    data = get(p, Data, Data())
    grp = extract_columns(data, get(p, Group, Group()))
    ts = extract_columns(data, get(p, Union{Select, Traces}, Select()))
    an = get(p, Analysis, Analysis())
    return an(Traces(grp, ts))
end

struct Analysis{T, N<:NamedTuple} <: AbstractElement
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end
Analysis() = Analysis(Select)

function Base.show(io::IO, an::Analysis)
    print(io, "Analysis(")
    show(io, an.f)
    print(io, ")")
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
function (an::Analysis)(args...; kwargs...)
    return an.f(args...; kwargs..., an.kwargs...)
end
(an::Analysis)(s::Select) = Select(an(s.args...; s.kwargs...))
(an::Analysis)(t::Traces) = Traces([a => an(s) for (a, s) in t.list])

combine(a1::Analysis, a2::Analysis) = a2 ∘ a1

struct Data{T} <: AbstractElement
    table::T
    function Data(t)
        nt = columntable(t)
        return new{typeof(nt)}(nt)
    end
    Data() = new{Nothing}(nothing)
end

function Base.show(io::IO, d::Data)
    print(io, "Data with columns ")
    show(io, columnnames(columns(d.table)))
end

combine(d1::Data, d2::Data) = d2
