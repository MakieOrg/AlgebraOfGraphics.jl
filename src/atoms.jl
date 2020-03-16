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

merge(g1::Group, g2::Group) = Group(; merge(g1.columns, g2.columns)...)

struct Analysis{T, N<:NamedTuple} <: AbstractElement
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end

function Base.show(io::IO, an::Analysis)
    print(io, "Analysis(")
    show(io, an.f)
    print(io, ")")
end

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
function (an::Analysis)(args...; kwargs...)
    return an.f(args...; kwargs..., an.kwargs...)
end
# (an::Analysis)(t::Traces) = Traces([a => an(s) for (a, s) in t.list])

merge(a1::Analysis, a2::Analysis) = a2 ∘ a1

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

merge(d1::Data, d2::Data) = d2

struct Select{T<:Tuple, NT<:NamedTuple} <: AbstractElement
    a::Analysis
    d::Data
    g::Group
    o::NamedTuple
    args::T
    kwargs::NT
    function Select(args...; kwargs...)
        a = foldl(merge, keeptype(args, Analysis), init=Analysis())
        d = foldl(merge, keeptype(args, Data), init=Data())
        g = foldl(merge, keeptype(args, Group), init=Group())
        o = foldl(merge, keeptype(args, NamedTuple), init=NamedTuple())
        args′ = droptype(args, Union{Analysis, Data, Group, NamedTuple})
        nt = values(kwargs)
        return new{typeof(args′), typeof(nt)}(a, d, g, o, args′, nt)
    end
end
Select(s::Select) = s

function Base.show(io::IO, s::Select)
    print(io, "Select{ }")
end

function merge(s1::Select, s2::Select)
    a = merge(s1.a, s2.a)
    g = merge(s1.g, s2.g)
    d = merge(s1.d, s2.d)
    o = merge(s1.o, s2.o)
    args = (s1.args..., s2.args...)
    kwargs = merge(s1.kwargs, s2.kwargs)
    return Select(a, g, d, o, args; kwargs...)
end

merge(a1::AbstractElement, a2::AbstractElement) = merge(Select(a1), Select(a2))
merge(a::AbstractElement, b::NamedTuple) = merge(a, Select(b))
merge(a::NamedTuple, b::AbstractElement) = merge(Select(a), b)

Analysis() = Analysis(Select)
(an::Analysis)(s::Select) = Select(an(s.args...; s.kwargs...))
