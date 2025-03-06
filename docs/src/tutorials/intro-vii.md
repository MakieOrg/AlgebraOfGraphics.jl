# Intro to AoG - VI - Split aesthetics

In the previous tutorials, you have already learned about aesthetics and the categorical or continuous scales that use them.
However, so far we've only used one scale of a given type within a plot, for example one color scale, or one set of markers.

There are situations where this is not enough and you need more flexibility.
AlgebraOfGraphics solves this problem by allowing you to give scales different ids.

One example for such a scenario is when you want to plot one column from a dataset against multiple others in a facet layout.
In the default case, every facet in an AoG layout will have the same x and y scale (even though as we've seen in the wide data tutorial, the axis labels may differ).

However, we can create multiple layers, where each layer assigns a different scale id to its x scale, which will allow categorical and continuous scales to coexist in the same layout.
For that to work, we just have to take care that the facets of these layers don't mix, that means, each layer gets its own facet.

```@example tut
using AlgebraOfGraphics
using CairoMakie
using PalmerPenguins
using DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))

# start with a completely empty layer stack
layers = zerolayer()

for (i, column) in enumerate([:flipper_length_mm, :island, :bill_depth_mm, :species])
    scaleid = Symbol("Y", i)
    plottype = penguins[!, column] isa AbstractVector{<:Number} ? Scatter : Violin
    layers += mapping(
        column => scale(scaleid), # this is the important bit
        :bill_length_mm;
        col = direct("$i"),
    ) * visual(plottype)
end

spec = data(penguins) * layers

draw(spec; axis = (; xticklabelrotation = pi/4, xticklabelspace = 55))
```


