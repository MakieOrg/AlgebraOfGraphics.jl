struct Visual
    plottype::PlotType
    attributes::NamedArguments
    target
end

Visual(plottype::PlotType = Plot{plot}; kwargs...) = Visual(plottype, NamedArguments(kwargs), nothing)

function (v::Visual)(input::ProcessedLayer)
    # If a target is specified on a single ProcessedLayer, it should match
    if !isnothing(v.target) && !target_matches(v.target, input)::Bool
        error("subvisual target did not match. Target was $(repr(v.target)), but layer has plottype $(input.plottype) and label $(repr(input.label))")
    end
    if target_matches(v.target, input)::Bool
        plottype = Makie.plottype(v.plottype, input.plottype)
        attributes = merge(input.attributes, v.attributes)
        return ProcessedLayer(input; plottype, attributes)
    else
        return input
    end
end

target_matches(::Nothing, input) = true
target_matches(t::Symbol, input) = input.label === t
target_matches(t::Type, input) = input.plottype <: t

function (v::Visual)(inputs::ProcessedLayers)
    # Check if target matches at least one layer when a target is specified
    if !isnothing(v.target)
        matches = map(pl -> target_matches(v.target, pl)::Bool, inputs.layers)
        if !any(matches)
            available_labels = [pl.label for pl in inputs.layers]
            available_plottypes = [pl.plottype for pl in inputs.layers]
            error("subvisual target $(repr(v.target)) did not match any layer in ProcessedLayers. Available labels are $(join([repr(a) for a in available_labels], ", ", " and ")), available plottypes are $(join([string(p) for p in available_plottypes], ", ", " and "))")
        end
    end
    return ProcessedLayers(
        map(inputs.layers) do pl
            if target_matches(v.target, pl)::Bool
                plottype = Makie.plottype(v.plottype, pl.plottype)
                attributes = merge(pl.attributes, v.attributes)
                return ProcessedLayer(pl; plottype, attributes)
            else
                return pl
            end
        end
    )
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

To suppress a layer's legend contribution, pass `legend = (; visible = false)` as an attribute.
This is an AlgebraOfGraphics-specific option that is intercepted before reaching Makie.
Other entries in the `legend` named tuple are forwarded to Makie's `LegendOverride` mechanism
as before.

```julia
data(...) * mapping(..., color = :group) * (visual(Scatter) + visual(Makie.Text, legend = (; visible = false)))
```

Depending on its `aesthetic_mapping`, a plot type and its attributes may change certain semantics of a given `data(...) * mapping(...)` spec.
For example, `visual(BarPlot)` will show mapping 1 on the x axis and 2 on the y axis, while `visual(BarPlot, direction = :x)`
shows mapping 1 on y and 2 on x.
"""
visual(plottype::PlotType = Plot{plot}; kwargs...) = transformation(Visual(plottype; kwargs...))

"""
    subvisual(target, args...; kwargs...)

Create a layer that works like `visual(args...; kwargs...)` but only applies to `ProcessedLayer`s that
match the `target` argument. This is intended for usage with transformation layers
which create multiple layers themselves.

The types of `target` that can be used are:
- `Symbol`: Can be used to pick processed layers by label if they have one. Transformations which create multiple processed layers should label them to facilitate this. For example, the `linear` transformation creates a `:prediction` and a `:ci` layer.
- `Type`: e.g. `BarPlot` or `Scatter`. Only layers with plot type `<:T` are selected.

Example:

```julia
data(...) * mapping(...) * linear() * subvisual(:prediction, ...) * subvisual(:ci, ...)
```
"""
subvisual(target, plot = Plot{plot}; kwargs...) = transformation(Visual(plot, NamedArguments(kwargs), target))


# For backward compatibility, still allow `visual(Any)`.
@deprecate visual(::Type{Any}; kwargs...) visual(; kwargs...)
