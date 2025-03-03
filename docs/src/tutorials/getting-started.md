# Basics of AlgebraOfGraphics

Welcome to AlgebraOfGraphics! If you're new to this package, this tutorial will teach you the basic concepts you need to get started.

## What is AlgebraOfGraphics?

AlgebraOfGraphics, or AoG for short, is a package for data visualization. There are many different approaches to visualizing data but AlgebraOfGraphics follows in the tradition of [ggplot2](https://ggplot2.tidyverse.org/), which popularized the concept of a "grammar of graphics". The idea was that visualizations should not be drawn imperatively by executing lots of low-level commands like "draw a line" or "draw a point" or "place some text", but instead by describing a higher-level "intent" how your tabular data should be transformed into a visual end result using a "grammar" or domain specific language.

In the Julia ecosystem, [Makie.jl](https://docs.makie.org/) is one of the most-used data visualization libraries. While it is very flexible and gives users a lot of freedom, it follows the low-level imperative approach which leaves a lot of convenience on the table.

AlgebraOfGraphics was built on top of Makie to give users the ability to easily create their most commonly needed visualizations in a clear and descriptive way, while still retaining the ability to apply all of Makie's underlying feature set to make more unusual modifications which are hard to cover with a generic descriptive API. In contrast, ggplot2 turns plot specifications into relatively obscure data structures that are not necessarily easy to change later. Therefore, users have to rely much more on the availability of packages (of which there are admittedly many in the ggplot2 ecosystem) that solve specific visualization problems for them instead of being able to drop down to lower-level methods.

Here's a short overview of similarities and differences between ggplot2 and AlgebraOfGraphics:

|ggplot2|AlgebraOfGraphics|
|:---|:---|
|Uses "tidy" (long format) tables as input.|"Tidy" tables are the most common input type, but wide data, pregrouped arrays, and other input types are also supported.|
|Adds layers, attributes and scales to one big specification object using the `+` operator | Layers are built using the `+` ("stack on top") and `*` ("merge together") operators, forming an algebra which can remove code shared between layers. Scales and other global attributes are specified separately.|
|Defines all of the visual infrastructure itself, outputs low level graphics objects that are hard to modify directly.|Creates high-level Makie building blocks like `Figure`, `Axis` or `Legend` as well as plot objects like `Lines` or `Scatter` which can be modified more easily.|
|`geom`s specify visual components and `stats` statistical transformations, but some `geoms` have default `stat`s and vice versa | Layers with the `visual` transformation feed their associated data directly to Makie plotting functions. Layers with other `transformation`s apply more complex modifications to the data first and can result in multiple output layers.|

Now let's actually start plotting some things to see how AlgebraOfGraphics works!
But before we can do that, we have to load the necessary packages and the `penguins` dataset from RDatasets. CairoMakie is one of [Makie's backend packages](https://docs.makie.org/stable/explanations/backends/backends) which we need to actually turn our plots into images. CairoMakie is the most commonly used backend with AlgebraOfGraphics because it focuses on 2D plots and vector graphics.

```@example tut
using AlgebraOfGraphics
using CairoMakie
using PalmerPenguins
using DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))
```

## Layers: `data`, `mapping`, `visual` and `transformation`

Layers form the backbone of AoG plots. A layer combines the specification of three major components:
- the input `data`
- a `mapping` specifying which parts of the input data should be used as the arguments of Makie plotting functions or AoG transformations
- the Makie plotting function used to visualize a layer's data (via `visual`) or some other `transformation` that should be applied (think statistical transformation plus possibly multiple `visual`s rolled into one)

One of the most common basic plots is the scatter plot which plots one variable on the x axis against another on the y axis. Let's see how we can express this using AoG's layers.

For reference, an empty layer looks like this, it has no input `data`, no positional or named arguments which form the `mapping`, and no `transformation`, `visual` or otherwise:

```example tut
Layer()
```

To specify the input data, we use the `data` function which creates a partially specified layer:

```@example tut
data(penguins)
```

You can see that `positional` and `named` arguments are still unset, and the `transformation` component is set to the `identity` function which doesn't do anything.
The `data` component, however, reflects that we have added a `DataFrame` source.

Next, we need to specify which columns from our data source we want to use as arguments to our layer's plotting function, the scatter plot (which we have also not specified, yet). A `Scatter` plot in Makie takes x as the first positional argument and y as the second. So what do we want our x and y to be? Let's pick `bill_length_mm` as x and `bill_depth_mm` as y. We can express that using `mapping`:

```@example tut
mapping(:bill_length_mm, :bill_depth_mm)
```

By itself, `mapping` just creates a partial layer where, in our case, two positional arguments have been specified. But `bill_length_mm` and `bill_depth_mm` don't mean anything on their own, they have to be combined with our table source first. We can do combine our partial layers with the `*` operator:

```@example tut
data(penguins) * mapping(:bill_length_mm, :bill_depth_mm)
```

Now, we're just missing the information which plot type we want to use these two columns with. In our first example, we use Makie's `Scatter` plot type. Let's look at the partial layer that is created by `visual`, which has no data source and no positional or named arguments:

```@example tut
visual(Scatter)
```

You can see that the `transformation` field has been set to a `Visual` object that specifies we want to use a `Scatter` plot.
And now we combine all three parts, forming a fully specified layer:

```@example tut
layer = data(penguins) * mapping(:bill_length_mm, :bill_depth_mm) * visual(Scatter)
```

## `draw`

Finally, we can turn our layer into Makie plot objects. This is done using the `draw` function. Contrary to the name, `draw` doesn't actually "draw" anything, that part is done by CairoMakie using the output from `draw`. Therefore, it could also be called `turn_into_makie_plot` or something like that.

Nevertheless, returning the output from `draw` in an environment that knows how to display Makie plots, will actually draw something for us, so let's do that now:

```@example tut
draw(layer)
```

Our first AlgebraOfGraphics plot!

## `visual` attributes

We have successfully passed two columns from our dataset to Makie's `scatter` function, but other than that we have left everything at its default. Like in base Makie, we can use lots of attributes to change how plotting functions are rendered. For example, we can modify the `marker`, `markersize`, `color` or `alpha` attributes. Every keyword attribute that we could usually pass to `scatter(...; )` in Makie, we can pass with AlgebraOfGraphics as well, via the `visual` function:

```@example tut
new_layer = layer * visual(marker = :rtriangle, markersize = 15, color = :teal, alpha = 0.5)
draw(new_layer)
```

Note how we can just multiply these settings on top of our existing layer, the visual transformations are chained together. The first one will set the `Scatter` plot type and the second one will set the attributes.