abstract type AbstractContextual end

struct Style <: AbstractContextual
    nt::NamedTuple
end
Style(s::Style) = s
Style() = Style(NamedTuple())

style(args...; kwargs...) = Style(namedtuple(args...; kwargs...))

Base.merge(s1::Style, s2::Style) = Style(merge(s1.nt, s2.nt))
