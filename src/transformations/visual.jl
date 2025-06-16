struct Visual
    plottype::PlotType
    attributes::NamedArguments
end
Visual(plottype::PlotType = Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs))

function (v::Visual)(input::ProcessedLayer)
    plottype = Makie.plottype(v.plottype, input.plottype)
    attributes = merge(input.attributes, v.attributes)
    return ProcessedLayer(input; plottype, attributes)
end

# In the future, consider switching from `visual(Plot{T})` to `visual(T)`.
"""
    visual(plottype; attributes...)

Create a [`Layer`](@ref) that will cause a plot spec multiplied with it to be visualized with
plot type `plottype`, together with optional `attributes`.

The available plotting functions are documented
[here](https://docs.makie.org/stable/reference/plots/overview). Refer to
plotting functions using upper CamelCase for `visual`'s first argument (e.g.
`visual(Scatter), visual(BarPlot)`). See the documentation of each plotting
function to discover the available attributes. These attributes can be passed
as additional keyword arguments to `visual`, or as part of the [`mapping`](@ref)
you define.

The `visual` function can in principle be used for any plotting function that is defined using
the `@recipe` macro from Makie. AlgebraOfGraphics just needs method definitions for
`aesthetic_mapping`, which define what arguments of the plotting function map to which visual
aesthetics. And for legend support, `legend_elements` must be overloaded for custom recipes as well,
as Makie's default legend mechanism relies on instantiated plot objects, while AlgebraOfGraphics
must go by the type and attributes alone.

Depending on its `aesthetic_mapping`, a plot type and its attributes may change certain semantics of a given `data(...) * mapping(...)` spec.
For example, `visual(BarPlot)` will show mapping 1 on the x axis and 2 on the y axis, while `visual(BarPlot, direction = :x)`
shows mapping 1 on y and 2 on x.
"""
visual(plottype::PlotType = Plot{plot}; kwargs...) = transformation(Visual(plottype; kwargs...))

# For backward compatibility, still allow `visual(Any)`.
@deprecate visual(::Type{Any}; kwargs...) visual(; kwargs...)
