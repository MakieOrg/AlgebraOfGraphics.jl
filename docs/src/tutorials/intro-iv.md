# Intro to AoG - IV - Data transformations

In the previous chapters, we have seen two different abilities of the `mapping` function, column selection and labelling:

```@example tut
using AlgebraOfGraphics
using CairoMakie
using PalmerPenguins
using DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))

layer = data(penguins) *
    mapping(
        :bill_length_mm => "Bill length (mm)",
        :bill_depth_mm => "Bill depth (mm)",
        color = :species => "Species",
    ) *
    visual(Scatter)
draw(layer)
```

