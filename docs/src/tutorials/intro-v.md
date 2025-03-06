# Intro to AoG - V - Alternative input data formats

So far, every example you've seen in this tutorial series was using a long-format or "tidy" dataframe in the tradition of ggplot2.

Sometimes, however, our data does not come in this format, and we don't want to spend the time to transform it before we start plotting. In this case, it's good to be aware of alternative methods of specifying and handling input data that AlgebraOfGraphics offers.

## Specify data directly in `mapping`

The first alternative is still about long-format data, but it omits the tables. Let's say we just happen to have three vectors of data lying around. We simulate that here by extracting them from the familiar `penguins` dataframe:

```@example tut
using AlgebraOfGraphics
using CairoMakie
using PalmerPenguins
using DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))

bill_lengths = penguins.bill_length_mm
bill_depths = penguins.bill_depth_mm
species = penguins.species
nothing # hide
```

Of course we could form a table from them first and pass them with `data`, but there's a shorter way. We omit `data` and just pass the columns directly to `mapping`:

```@example tut
no_data = mapping(bill_lengths, bill_depths, color = species) * visual(Scatter)

draw(no_data)
```

Note that we lose the labels that the column names usually provide. We can provide them as usual in the `scales` or by pairing them:

```@example tut
no_data_labeled = mapping(
    bill_lengths => "Bill length (mm)",
    bill_depths => "Bill depth (mm)",
    color = species => "Species",
) * visual(Scatter)

draw(no_data_labeled)
```

## Add columns using `direct`

Another special case with long-format data is when we do have a table, but we also have some outside information as a vector or scalar. In this case it's annoying having to construct a new table just to pass our additional data in. To directly pass in columns, you can use the `direct` helper function in conjunction with `data`.

Let's pretend we have computed a "cuteness score" for our penguins using some classifier, which we now have in a vector. We can create a plot where we mix that data with the `penguins` dataframe without having to construct a new table:

```@example tut
using Statistics

cuteness = randn(size(penguins, 1))

cuteness_spec = data(penguins) * mapping(:flipper_length_mm, direct(cuteness) => "cuteness", color = :species)

draw(cuteness_spec)
```

We can also specify scalars in `direct` which sometimes comes in handy when we define groups on the fly.
For example, if we had two dataframes which we didn't want to merge into long format, but just plot in a facet each, we could add two layers that specify a `layout` value using `direct`, without having to construct a column with the correct length for each:

```@example tut
first_half = penguins[1:end÷2,:]
second_half = penguins[end÷2+1:end,:]

two_halves_base = (data(first_half) * mapping(layout = direct("First Half")) + data(second_half) * mapping(layout = direct("Second Half")))
two_halves = two_halves_base * mapping(:bill_length_mm, :bill_depth_mm) * visual(Scatter)

draw(two_halves)
```

## Wide data

One special power of AlgebraOfGraphics is its ability to handle wide format data.
While every wide dataframe can be converted back and forth from a long one using `stack` and `unstack`, doing so certainly adds a bit of mental overhead which we generally like to avoid in exploratory plotting.

For example, let's say we had four different weight measurements, one for each season.
We pretend that penguins start thinner in spring, grow in summer and autumn and then lose weight again going into winter.

```@example tut
season_penguins = transform(
    penguins,
    :body_mass_g .=>
        [col -> col .* x for x in [0.8, 0.9, 1.1, 0.95]] .=>
        string.("body_mass_", ["spring", "summer", "autumn", "winter"])
    )

first(season_penguins[:, end-3:end], 5)
```

To get a long format dataframe, we could then apply the `stack` function:

```@example tut
stacked_penguins = stack(season_penguins, [:body_mass_spring, :body_mass_summer, :body_mass_autumn, :body_mass_winter])

first(stacked_penguins, 5)
```

This long dataframe we could then plot with our usual workflow. Note that after a stacking operation it's a little bit less descriptive what we're plotting because our columns are now called `variable` and `value`:

```@example tut
stacked_spec = data(stacked_penguins) *
    mapping(:sex, :value, col = :variable) *
    visual(Violin)

draw(stacked_spec)
```

The order of the seasons is also alphabetical, but let's ignore that for now.

Now let's see how we could do the same plot with the original dataframe.
We can specify an array of column selectors in `mapping` where so far we've only ever passed single column specifiers:

```@example tut
wide_spec = data(season_penguins) *
    mapping(
        :sex,
        [:body_mass_spring, :body_mass_summer, :body_mass_autumn, :body_mass_winter],
        col = dims(1)
    ) *
    visual(Violin)

draw(wide_spec)
```

Now, something interesting happened.

The order of seasons is correct in this version, however each y axis has its own label now (corresponding to the source columns) and all y axes are unlinked.
That is because AlgebraOfGraphics has the ability to extract labels across multiple input dimensions and it will not merge axes that are labeled differently.
The input shape in our case is `(4,)` which is equivalent to the size of our four-column vectors. So there are four labels.

The expression `col = dims(1)` means that we want to split the dataset into `col` facets using the indices of the first dimension of our input shape `(4,)`.
That results in the `CartesianIndex(1,)` to `CartesianIndex(4,)` titles of the column facets.

We can assign a separate label to each column by broadcasting (`.=>`) label pairs with the column vector. We could specify four different labels, but in this case, the y axis is always the same. So we just broadcast the same label to all of them:

```@example tut
wide_spec_labeled = data(season_penguins) *
    mapping(
        :sex,
        [:body_mass_spring, :body_mass_summer, :body_mass_autumn, :body_mass_winter] .=> "Body Mass (g)",
        col = dims(1)
    ) *
    visual(Violin)

draw(wide_spec_labeled)
```

The four y axis labels are now all the same again, so the axis linking also goes into effect as usual and the three redundant labels are hidden.
But the column labels are not nice, yet, because they just enumerate the indices of the first input dimension.
The simplest way to rename these is to use the `renamer` utility that we have seen before.

```@example tut
wide_spec_final = data(season_penguins) *
    mapping(
        :sex,
        [:body_mass_spring, :body_mass_summer, :body_mass_autumn, :body_mass_winter] .=> "Body Mass (g)",
        col = dims(1) => renamer(["Spring", "Summer", "Autumn", "Winter"])
    ) *
    visual(Violin)

draw(wide_spec_final)
```

That looks much better!

### More dimensions

To drive the point about multidimensional column selections home, here's another example where we have even more wide columns.
In this example, there's not only four seasons, but also three different years, which gives 12 columns overall.

```@example tut
seasons = ["spring", "summer", "autumn", "winter"]
years = [2010, 2011, 2012]
matrix_of_columns = string.("body_mass_", seasons, "_", years')

years_penguins = transform(
    penguins,
    :body_mass_g .=>
        [col -> col .* x * y for x in [0.8, 0.9, 1.1, 0.95], y in [0.8, 1.2, 1.0]] .=>
        matrix_of_columns
    )

names(years_penguins)
```

We now have a matrix of columns with shape `(4, 3)`:

```@example tut
size(matrix_of_columns)
```

When we then set `col = dims(1)` and `row = dims(2)`, we get 4 columns for the seasons and 3 rows for the years.

```@example tut
spec = data(years_penguins) *
    mapping(
        :sex,
        matrix_of_columns .=> "Body Mass (g)",
        col = dims(1) => renamer(seasons),
        row = dims(2) => renamer(years),
    ) *
    visual(Violin)

draw(spec)
```

It is quite common for tabular datasets to encode some sort of multidimensional structure with similarly concatenated column names, so knowing about multidimensional wide data can come in handy.

In general, whether you use the stack-to-long or the wide workflow is mostly a matter of taste, you should always be able to go back and forth between the representations.
But it's nice to have options, and especially for multidimensional cases, the necessary `stack` and split operations can be more complex.

## Pregrouped data
