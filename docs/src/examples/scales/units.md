```@meta
ShareDefaultModule = true
```

# Units

AlgebraOfGraphics supports input data with units, currently [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) and [DynamicQuantities.jl](https://github.com/SymbolicML/DynamicQuantities.jl) have extensions implemented.

Let's first create a unitful version of the penguins dataset:

```@example
using AlgebraOfGraphics
using CairoMakie
using Unitful
using DataFrames

df = DataFrame(AlgebraOfGraphics.penguins())
df.bill_length = df.bill_length_mm .* u"mm"
df.bill_depth = uconvert.(u"cm", df.bill_depth_mm .* u"mm")
df.flipper_length = df.flipper_length_mm .* u"mm"
df.body_mass = df.body_mass_g .* u"g"
select!(df, Not([:bill_length_mm, :bill_depth_mm, :flipper_length_mm, :body_mass_g]))

first(df, 5)
```

When we plot columns with units, the units are automatically appended to the respective labels:

```@example
spec = data(df) *
    mapping(:bill_length, :bill_depth, color = :body_mass) *
    visual(Scatter)
draw(spec)
```

Labels are separate from units, so we can relabel without affecting the unit suffixes:

```@example
spec = data(df) *
    mapping(:bill_length => "Bill length", :bill_depth => "Bill depth", color = :body_mass => "Body mass") *
    visual(Scatter)
draw(spec)
```

We can choose a different display unit per scale via the `unit` scale property:

```@example
draw(
    spec,
    scales(
        X = (; unit = u"cm"),
        Y = (; unit = u"mm"),
        Color = (; unit = u"kg")
    )
)
```

If we plot different units on the same scale, all the units have to be dimensionally compatible and will be auto-converted to the same unit.

```@example
layer1 = data(df) * mapping(:bill_length, color = direct("Bill length")) * visual(Density)
layer2 = data(df) * mapping(:bill_depth, color = direct("Bill depth")) * visual(Density)

draw(layer1 + layer2)
```

AlgebraOfGraphics will complain if we try to plot dimensionally incompatible units on the same scale:

```@example
struct UnexpectedSuccess <: Exception end #hide
try  #hide
layer1 = data(df) * mapping(:bill_length, color = direct("Bill length")) * visual(Density)
layer2 = data(df) * mapping(:body_mass, color = direct("Body mass")) * visual(Density)

draw(layer1 + layer2)
throw(UnexpectedSuccess()) #hide
catch e; e isa UnexpectedSuccess ? rethrow(e) : showerror(stderr, e); end  #hide
```

In the next example, we make a facet plot with wide data, and even though there are two y axes, there's just one underlying Y scale being fit.
Therefore, both columns get unit-converted:

```@example
spec_wide = data(df) *
    mapping(:sex, [:bill_length => "Bill length", :bill_depth => "Bill depth"], layout = dims(1)) *
    visual(Violin)

draw(spec_wide)
```

Again, we can force a different display unit via the scale options.

```@example
draw(spec_wide, scales(Y = (; unit = u"cm"), Layout = (; show_labels = false)))
```

