# Mapping

Mappings determine how the date is translated into a plot.
Positional mappings correspond to the `x`, `y` or `z` axes of the plot,
whereas the keyword arguments correspond to plot attributes that can vary
continuously or discretely, such as `color` or `markersize`.

Mapping variables  are split according to the categorical attributes in it,
and then converted to plot attributes using a default palette.

```@example
using AlgebraOfGraphics
mapping(:weight_mm => "weight (mm)", :height_mm => "height (mm)", marker = :gender)
```

## Pair syntax

A convenience `pair`-based syntax can be used to transform variables on-the-fly
and rename the respective column.

Let us assume the table `df` contains a column called `bill_length_mm`.
We can apply an element-wise transformation and rename the column on the fly as
follows.

```julia
data(df) * mapping(:bill_length_mm => (t -> t / 10) => "bill length (cm)")
```

A possible alternative, if `df` is a `DataFrame`, would be to store a renamed,
modified column directly in `df`, which can be achieved in the following way: 

```julia
df.var"bill length (cm)" = map(t -> t / 10, df.bill_length_mm)
data(df) * mapping("bill length (cm)") # strings are also accepted for column names
```

### Row-by-row versus whole-column operations

The pair syntax acts *row by row*, unlike, e.g., `DataFrames.transform`.
This has several advantages.

- Simpler for the user in most cases.
- Less error prone especially
   - with grouped data (should a column operation apply to each group or the whole dataset?)
   - when several datasets are used

Naturally, this also incurs some downsides, as whole-column operations, such as
z-score standardization, are not supported:
they should be done by adding a new column to the underlying dataset beforehand.

### Functions of several arguments

In the case of functions of several arguments, such as `isequal`, the input
variables must be passed as a `Tuple`.

```julia
accuracy = (:species, :predicted_species) => isequal => "accuracy"
```

### Partial pair syntax

The "triple-pair" syntax is not necessary, one can also only pass the column name,
a column name => function pair, or a column name => new label pair.

## Helper functions

Some helper functions are provided, which can be used within the pair syntax to
either rename and reorder *unique values* of a categorical column on the fly or to
signal whether a numerical column should be treated as categorical.

The complete API of helper functions is available at [Mapping helpers](@ref).

### Examples

```julia
# column `train` has two unique values, `true` and `false`
:train => renamer([true => "training", false => "testing"]) => "Dataset"
# column `price` has three unique values, `"low"`, `"medium"`, and `"high"`
:price => sorter(["low", "medium", "high"])
# column `age` is expressed in integers and we want to treat it as categorical
:age => nonnumeric
# column `labels` is expressed in strings and we do not want to treat it as categorical
:labels => verbatim
```
