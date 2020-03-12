struct Select
    args::Tuple
    kwargs::NamedTuple
    Select(args...; kwargs...) = new(args, values(kwargs))
end
Select(t::Tuple) = Select(t...)
Select(s::Select) = s

function combine(s1::Select, s2::Select)
    return Select(s1.args..., s2.args...; merge(s1.kwargs, s2.kwargs)...)
end

struct Analysis{T, N<:NamedTuple}
    f::T
    kwargs::N
    function Analysis(f::T; kwargs...) where {T}
        nt = values(kwargs)
        new{T, typeof(nt)}(f, nt)
    end
end
Analysis() = Analysis(Select)

(an::Analysis)(; kwargs...) = Analysis(an.f; kwargs..., an.kwargs...)
function (an::Analysis)(args...; kwargs...)
    return Select(an.f(args...; kwargs..., an.kwargs...))
end
(an::Analysis)(s::Select) = an(s.args...; s.kwargs...)

combine(a1::Analysis, a2::Analysis) = a2

adjust_globally(a::Analysis, ts) = a

struct Group
    columns::NamedTuple
    Group(; kwargs...) = new(values(kwargs))
end

combine(g1::Group, g2::Group) = Group(; merge(g1.columns, g2.columns)...)

struct Data{T}
    table::T
end
Data() = Data(nothing)

combine(d1::Data, d2::Data) = d2
