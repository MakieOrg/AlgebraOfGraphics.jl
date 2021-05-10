struct Layer
    transformations::Tuple
    data::Any
    positional::Tuple
    named::NamedTuple
end

Layer(transformations::Tuple=()) = Layer(transformations, nothing, (), (;))

data(df) = Layer((), columns(df), (), (;))
mapping(args...; kwargs...) = Layer((), nothing, args, values(kwargs))

function Base.:*(l1::Layer, l2::Layer)
    t1, t2 = l1.transformations, l2.transformations
    d1, d2 = l1.data, l2.data
    p1, p2 = l1.positional, l2.positional
    n1, n2 = l1.named, l2.named
    transformations = (t1..., t2...)
    data = isnothing(d2) ? d1 : d2
    positional =(p1..., p2...)
    named = merge(n1, n2)
    return Layer(transformations, data, positional, named)
end
