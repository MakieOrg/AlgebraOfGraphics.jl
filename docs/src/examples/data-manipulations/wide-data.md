# Long vs Wide Data Formats

AlgebraOfGraphics works with both long and wide data formats. Understanding the difference helps you choose the right approach and write clearer plotting code.

## What is Long Format?

In long format (also called "tidy" format), each row represents one observation. If you have multiple groups or categories, they're indicated by values in a categorical column rather than spread across separate columns.

Here's an example of long format data:

| x | y | group |
|---|---|-------|
| 1 | 1.0 | y1 |
| 2 | 1.5 | y1 |
| 1 | 1.1 | y2 |
| 2 | 1.6 | y2 |

Long format is the most convenient for AlgebraOfGraphics. Mappings are straightforward because you just reference column names directly:

```julia
mapping(:x, :y, color = :group)
```

## What is Wide Format?

In wide format, multiple related measurements are spread across different columns. This is often how data comes naturally from experiments, spreadsheets, or measurement devices.

The same data in wide format:

| x | y1 | y2 |
|---|----|----|
| 1 | 1.0 | 1.1 |
| 2 | 1.5 | 1.6 |

Wide format can be used with AlgebraOfGraphics, but requires more complex multidimensional mappings. You specify a vector of column names and use helpers like `dims()` to create categorical groupings.

## Converting Between Formats

You can convert between formats using DataFrames functions.

**Wide to Long** (using `stack`):

```@example stack_unstack
using DataFrames

# Wide format
df_wide = DataFrame(x = [1, 2], y1 = [1.0, 1.5], y2 = [1.1, 1.6])

# Convert to long format
df_long = stack(df_wide, [:y1, :y2])
rename!(df_long, :value => :y, :variable => :group)
```

**Long to Wide** (using `unstack`):

```@example stack_unstack
# Long format
df_long = DataFrame(x = [1, 2, 1, 2], y = [1.0, 1.5, 1.1, 1.6], group = ["y1", "y1", "y2", "y2"])

# Convert to wide format
df_wide = unstack(df_long, :x, :group, :y)
```

## Plotting with Long vs Wide Format

Let's see how the same plots look with each format. We'll use a practical example with multiple y-values for each x:

````@example wide_data
using AlgebraOfGraphics, CairoMakie, DataFrames

# Create sample data
function make_y(v, n)
    m = Matrix{Float64}(undef, length(v), n)
    for i in 1:n
        e = 0.4 + i * 0.1
        m[:, i] = v .^ e
    end
    return m
end

xs = 0.0:10
m = hcat(xs, make_y(xs, 5))
ys = ["y$n" for n in 1:5]
nms = vcat("x", ys)

# Wide format
df = DataFrame(m, nms)

# Long format
dfl = stack(df, ys)
# just to rename the y-data as "y" and data group as "group"
rename!(dfl, :value => :y, :variable => :group) 

nothing # hide
````

### Example 1: Lines without color differentiation

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys) * visual(Lines) |> draw
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, group = :group) * visual(Lines) |> draw
````

In long format, we need the `group` mapping to create separate lines. Without it, all points would connect into one zigzagging line.

### Example 2: Lines differentiated by color

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys, color = dims(1) => renamer(ys)) * visual(Lines) |> draw
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, color = :group) * visual(Lines) |> draw
````

Notice how the long format version is simpler: just `color = :group`. The wide format needs `dims(1)` to create a categorical variable from the dimension, and `renamer(ys)` to give the categories proper names.

### Example 3: Custom color palette

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys, color = dims(1) => renamer(ys)) * visual(Lines) |>
    draw(scales(Color = (; palette = :Set1_5)))
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, color = :group) * visual(Lines) |>
    draw(scales(Color = (; palette = :Set1_5)))
````

The `scales` function works the same way for both formats.

### Example 4: Lines differentiated by style

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys, linestyle = dims(1) => renamer(ys)) * visual(Lines) |> draw
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, linestyle = :group) * visual(Lines) |> draw
````

### Example 5: Scatter plot with color

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys, color = dims(1) => renamer(ys)) * visual(Scatter) |> draw
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, color = :group) * visual(Scatter) |> draw
````

### Example 6: Scatter plot with different markers

**Wide format:**
````@example wide_data
data(df) * mapping(:x, ys, marker = dims(1) => renamer(ys)) * visual(Scatter) |> draw
````

**Long format:**
````@example wide_data
data(dfl) * mapping(:x, :y, marker = :group) * visual(Scatter) |> draw
````

## Understanding Wide Format Mappings

When you use wide format, you're creating a multidimensional mapping. Each element of the array gets processed through the full grouping pipeline.

In the example `mapping(:x, ys)` where `ys = ["y1", "y2", "y3", "y4", "y5"]`, you're creating a one-dimensional array with 5 elements. These elements refer to columns of the data, and each column becomes a separate trace in the plot.

The `dims(1)` helper creates a categorical variable along the first dimension of this array. This is what allows you to map that dimension to aesthetics like `color` or `linestyle`. The `renamer(ys)` function gives meaningful names to the categories instead of generic labels.

## Advanced: Axes are linked when they correspond to the same variable

When using wide format with faceting, AlgebraOfGraphics intelligently links axes that represent the same variable:

````@example wide_data
df_facet = (
    sepal_length = 1 .+ rand(100),
    sepal_width = 2 .+ rand(100),
    petal_length = 3 .+ rand(100),
    petal_width = 4 .+ rand(100)
)
xvars = ["sepal_length", "sepal_width"]
yvars = ["petal_length" "petal_width"]
layers = linear() + visual(Scatter)
plt = data(df_facet) * layers * mapping(xvars, yvars, col=dims(1), row=dims(2))
draw(plt)
````

You can control axis linking behavior:

````@example wide_data
draw(plt, facet = (; linkxaxes = :all, linkyaxes = :all))
````

````@example wide_data
draw(plt, facet = (; linkxaxes = :none, linkyaxes = :none))
````
