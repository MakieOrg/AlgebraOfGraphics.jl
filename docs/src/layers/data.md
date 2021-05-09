# Data

The `data` field of a layer contains the dataset that will be used to populate the plot.
There are no type restrictions on this dataset, as long as it respects the Tables interface.
In particular, any one of [these formats](https://github.com/JuliaData/Tables.jl/blob/main/INTEGRATIONS.md)
should work out of the box.

The `data` helper function creates an under-defined layer, where only the `data` field is populated..

```@example
using AlgebraOfGraphics
df = (a = rand(10), b = rand(10))
data(df)
```