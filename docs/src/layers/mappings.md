# Mappings

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
The main issue is that AlgebraOfGraphics mappings work on single rows instead of whole columns. For example, with `df::DataFrame`, this

```julia
data(df) * mapping(:bill_length_mm => (t -> t + 10) => "bill length (cm)")
```

avoids storing a renamed column in the `DataFrame`, which is also a reasonable
approach and could be done in the following way:

```julia
df.var"bill length (cm)" = map(t -> t + 10, df.bill_length_mm)
data(df) * mapping("bill length (cm)") # strings are also accepted for column names
```

### Row-by=row versus

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

Another point I noticed in the machine learning tutorial section: AlgebraOfGraphics allows giving multiple input variables as a tuple or array:

```julia
accuracy = (:species, :predicted_species) => isequal => "accuracy"
```

### Partial pair syntax

The "triple-pair" syntax is not necessary, one can also only pass the column name,
a column name => function pair, or a column name => new label pair.

## Helper functions

Some helper functions are provided, which can be used within the pair syntax to
either rename and reorder *unique values* of a categorical column on the fly or to
signal that a numerical column should be treated as categorical.

```@docs
AlgebraOfGraphics.renamer
AlgebraOfGraphics.nonnumeric
```

Examples

```julia
# column `train` has two unique values, `true` and `false`
:train => renamer(true => "training", false => "testing") => "Dataset"
# column `age` is expressed in integers and we want to treat it as categorical
:age => nonnumeric
```