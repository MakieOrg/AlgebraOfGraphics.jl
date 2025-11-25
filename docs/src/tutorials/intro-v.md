# Intro to AoG - V - Alternative input data formats

So far, every example you've seen in this tutorial series was using a long-format or "tidy" dataframe in the tradition of ggplot2.

Sometimes, however, our data does not come in this format, and we don't want to spend the time to transform it before we start plotting. In this case, it's good to be aware of alternative methods of specifying and handling input data that AlgebraOfGraphics offers.

## Specify data directly in `mapping`

The first alternative is still about long-format data, but it omits the tables. Let's say we just happen to have three vectors of data lying around. We simulate that here by extracting them from the familiar `penguins` dataframe:

```@example tut
using AlgebraOfGraphics
using CairoMakie
using DataFrames

penguins = DataFrame(AlgebraOfGraphics.penguins())

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

## [Wide data](@id Wide-data-tutorial)

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

We can assign a separate label to each column by creating label pairs in the column vector. These labels will by default apply both to the y axes and the facets, because `dims` takes its labels from all the involved column arrays by default.

```@example tut
wide_spec_labeled = data(season_penguins) *
    mapping(
        :sex,
        [:body_mass_spring => "Spring", :body_mass_summer => "Summer", :body_mass_autumn => "Autumn", :body_mass_winter => "Winter"],
        col = dims(1)
    ) *
    visual(Violin)

draw(wide_spec_labeled)
```

We can either assign the same label to all y entries and use `renamer` on `col = dims(1)` to explicitly change only the facet labels.
Or we can keep the labels in place and simply change the y axis label globally using the scale settings. Once all axes have the same label again, automatic axis linking goes into effect, too.

```@example tut
wide_spec_final = data(season_penguins) *
    mapping(
        :sex,
        [:body_mass_spring => "Spring", :body_mass_summer => "Summer", :body_mass_autumn => "Autumn", :body_mass_winter => "Winter"],
        col = dims(1)
    ) *
    visual(Violin)

draw(wide_spec_final, scales(Y = (; label = "Body Mass (g)")))
```

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
matrix_of_columns
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

Wide data is still tabular data, but AlgebraOfGraphics has another trick up its sleeve when it comes to input data formats.
Sometimes, you may have data in an array-of-arrays format, where each inner array contains data for a group.

Let's start with a simple example. Here we have timestamps and measurements for some population.
Each subject's data is already contained in its own array.

```@example tut
times = [
    [1, 2, 5, 7, 8],
    [3, 4, 7, 8],
    [2, 3, 6, 9],
]
measurements = [
    [0.2, 5.0, 3.0, 2.0, 1.2],
    [0.3, 4.7, 1.5, 1.1],
    [0.1, 5.9, 0.7, 0.3],
]
nothing # hide
```

We can plot this data directly using the `pregrouped` function. This function is equivalent to doing `data(AlgebraOfGraphics.Pregrouped()) * mapping(...)`, so it's essentially a special version of `mapping`:

```@example tut
pregrouped_spec = pregrouped(times, measurements) * visual(Lines)

draw(pregrouped_spec)
```

Because it's `mapping` under the hood, we can pair labels in `pregrouped` like usual:

```@example tut
pregrouped_labeled = pregrouped(times => "Time", measurements => "Measurement") * visual(Lines)

draw(pregrouped_labeled)
```

As you can see, each subject has a separate line, because the data are inherently grouped through the array structure. Compare to the same plot but with merged input arrays, which we can pass via `mapping`. Now there is a single line which zig-zags back and forth.

```@example tut
times_merged = reduce(vcat, times)
measurements_merged = reduce(vcat, measurements)

merged_spec = mapping(times_merged, measurements_merged) * visual(Lines)

draw(merged_spec)
```

Because the pregrouped data already has a one-dimensional input shape (compare to the wide data above where we saw a one-dimensional and a two-dimensional input shape), we can even do a quick facet plot by using the `dims` helper:

```@example tut
pregrouped_faceted = pregrouped(
    times => "Time",
    measurements => "Measurement",
    layout = dims(1),
) * visual(Lines)

draw(pregrouped_faceted)
```

Or the same thing with color, and renaming of the dims:

```@example tut
pregrouped_faceted = pregrouped(
    times => "Time",
    measurements => "Measurement",
    color = dims(1) => renamer(string.("Subject ", 1:3)),
) * visual(Lines)

draw(pregrouped_faceted)
```

If we already have a vector of categorical values, we can also directly use that for one of the named arguments in `pregrouped`. For categorical values, due to the way that AlgebraOfGraphics structures grouped data, each group should have one entry, and not an array filled with the same value.

So instead of this...

```julia
subjects = [
    ["Subject 1", "Subject 1", "Subject 1", "Subject 1", "Subject 1"],
    ["Subject 2", "Subject 2", "Subject 2", "Subject 2"],
    ["Subject 3", "Subject 3", "Subject 3", "Subject 3"],
]
```

...we need a simple structure like this:

```@example tut
subjects = ["Subject 1", "Subject 2", "Subject 3"]

pregrouped_faceted_subjects = pregrouped(
    times => "Time",
    measurements => "Measurement",
    color = subjects,
) * visual(Lines)

draw(pregrouped_faceted_subjects)
```

The categorical values don't need to be unique within the vectors, you will still get one plot per entry due to the array structure:

```@example tut
same_subjects = ["Subject 1", "Subject 1", "Subject 1"]

pregrouped_faceted_same = pregrouped(
    times => "Time",
    measurements => "Measurement",
    color = same_subjects,
) * visual(Lines)

draw(pregrouped_faceted_same)
```

### Even more dimensions

Here's one more example for `pregrouped` data that can demonstrate the possibility for multidimensional structure even more.
In this scenario, imagine you are profiling some code in a loop, testing three different algorithms on four different branches of a repo and three different Julia versions.
The data could come from code like this:

```@example tut
algorithms = ["Quick", "Merge", "Bubble"]
branches = ["master", "bugfix", "prerelease", "backport"]
julia_versions = ["1.10", "1.11", "nightly"]

timings = map(Iterators.product(algorithms, branches, enumerate(julia_versions))) do (algo, br, (i, jv))
    # here you would profile, we just generate random data with some structure
    20 .+ randn(100) .- 3 * i .+ randn()
end

size(timings)
```

As you can see, we have an array of arrays with shape `(3, 4, 3)`, so we can pass that directly via `pregrouped` and use `dims` to assign the three dimensions to different aesthetics:

```@example tut
multidim_pregrouped = pregrouped(
    timings => "Timings (s)",
    row = dims(1) => renamer(algorithms) => "Algorithm",
    col = dims(2) => renamer(branches),
    color = dims(3) => renamer(julia_versions) => "Julia version",
) * visual(Density)

draw(multidim_pregrouped)
```

Isn't that impressively little code to get a quick visualization out of multidimensional non-tabular data?

### Experimental: Passing matrices directly

Tables as 1D data structures are somewhat impractical when it comes to 2D data. With `pregrouped`, you can take advantage of the fact that AlgebraOfGraphics allows you to pass multidimensional numeric arrays to Makie as well.

!!! note
    This feature is considered experimental as it is a side effect from implementation details and the rules are not really fleshed out, yet.

```@example tut
ns = 3:8
xs = [range(0, 3, n+1) for n in ns]
ys = [range(2, 5, n+1) for n in ns]
matrices = [randn(n, n) for n in ns]

spec = pregrouped(
    xs,
    ys,
    matrices,
    layout = dims(1) => renamer(string.(ns))
) * visual(Heatmap)

draw(spec)
```

## Summary

In this chapter you have seen alternative ways of passing input data to AoG, circumventing `data` by passing columns to `mapping` directly, supplying additional columns using `direct`, as well as using multidimensional wide and pregrouped data.

In the next chapter, we're going to see how we can combine AoG plots with elements from Makie, and how we can modify the Makie objects that AoG creates.
