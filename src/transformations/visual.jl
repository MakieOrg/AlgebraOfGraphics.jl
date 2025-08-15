struct Target{T}
    target::T
end

"""
    target(x)

Create a `Target` object which can be used as the first argument to `visual`.
This makes the modifications of `visual` apply only to processed layers matching `x`.
This mechanism is intended primarily for cases where transformation layers create
multiple plot layers that should then be styled differently.

The types of `x` that can be used are:
- `Type`s, e.g. `BarPlot` or `Scatter`. Only layers with plot type `<:T` are selected.
- `Function`s of the form `f(p::ProcessedLayer)::Bool`. Only layers with return value `true` are selected.
"""
target(target) = Target(target)
struct Visual
    plottype::PlotType
    attributes::NamedArguments
    target::Target
end

Visual(plottype::PlotType = Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs), Target(nothing))

function (v::Visual)(input::ProcessedLayer)
    if target_matches(v.target, input)::Bool
        plottype = Makie.plottype(v.plottype, input.plottype)
        attributes = merge(input.attributes, v.attributes)
        return ProcessedLayer(input; plottype, attributes)
    else
        return input
    end
end

target_matches(::Target{Nothing}, input) = true
target_matches(t::Target{<:Type}, input) = input.plottype <: t.target
target_matches(t::Target{<:Function}, input) = t.target(input)::Bool

function (v::Visual)(inputs::ProcessedLayers)
    return ProcessedLayers(
        map(inputs.layers) do pl
            v(pl)
        end
    )
end

# In the future, consider switching from `visual(Plot{T})` to `visual(T)`.
"""
    visual(plottype; attributes...)
    visual(target(...), plottype; attributes...)

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

## Targeting Specific Layers

When transformations create multiple processed layers, you can add `target(...)` as the first 
argument to `visual` to specify which layers the visual should apply to. If the [`target`](@ref) function
receives a plot type, for example, the visual will only be applied to processed layers whose plot type
is a subtype of the specified target type. This is particularly useful when working with
transformations that generate multiple layers and you want to style them differently.

For example:
```julia
data(...) * mapping(...) * some_transformation() * visual(target(Scatter), ...) * visual(target(Lines), ...)
```
"""
visual(plottype::PlotType = Plot{plot}; kwargs...) = transformation(Visual(plottype; kwargs...))

visual(target::Target, plot = Plot{plot}; kwargs...) = transformation(Visual(plot, NamedArguments(kwargs), target))


# For backward compatibility, still allow `visual(Any)`.
@deprecate visual(::Type{Any}; kwargs...) visual(; kwargs...)
