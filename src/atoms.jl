abstract type AbstractElement end

abstract type AbstractSimple <: AbstractElement end

struct Select{T<:Tuple, NT<:NamedTuple} <: AbstractSimple
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

struct Analysis{T, N<:NamedTuple} <: AbstractSimple
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
    return Select(an.f(args...; kwargs..., an.kwargs...))
end
(an::Analysis)(s::Select) = an(s.args...; s.kwargs...)

combine(a1::Analysis, a2::Analysis) = a2

adjust_globally(a::Analysis, ts) = a

struct Group{NT<:NamedTuple} <: AbstractSimple
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

struct Data{T} <: AbstractSimple
    table::T
end
Data() = Data(nothing)

function Base.show(io::IO, d::Data)
    print(io, "Data with columns ")
    show(io, columnnames(columns(d.table)))
end

combine(d1::Data, d2::Data) = d2
