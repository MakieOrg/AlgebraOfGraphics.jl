struct Layer
    transformations::Tuple
    data::Any
    mappings::Arguments
end

Layer(transformations::Tuple=()) = Layer(transformations, nothing, arguments())

data(df) = Layer((), columns(df), arguments())
mapping(args...; kwargs...) = Layer((), nothing, arguments(args...; kwargs...))

function Base.:*(l1::Layer, l2::Layer)
    t1, t2 = l1.transformations, l2.transformations
    d1, d2 = l1.data, l2.data
    m1, m2 = l1.mappings, l2.mappings
    transformations = (t1..., t2...)
    data = isnothing(d2) ? d1 : d2
    mappings = Arguments(
        vcat(m1.positional, m2.positional),
        merge(m1.named, m2.named)
    )
    return Layer(transformations, data, mappings)
end
