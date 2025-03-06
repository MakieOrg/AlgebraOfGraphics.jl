# Intro to AoG - VI - Modifying and composing with Makie

In the last chapters we have concentrated on creating standalong AlgebraOfGraphics figures, without focusing to much on fiddling with the visual results.
However, in practice, many people spend a lot of time on tweaking their figures until they are satisfied with the smallest details.

Too often, such edits still happen in vector graphics software like Inkscape these days, which is both time consuming and non-reproducible, and should therefore be avoided if at all possible. Luckily, AlgebraOfGraphics is built on Makie, and Makie has a special focus on layouting and interactive editing. This means that it is easy to combine multiple AoG plots in a figure, as well as changing the underlying plot objects programmatically if that's desired.

Let's first bring our trusty old penguin dataset back in and draw a basic facet plot. We store the output of `draw` in a variable `figuregrid`, too:

```@example tut
using AlgebraOfGraphics
using CairoMakie
using PalmerPenguins
using DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))

spec = data(penguins) *
    mapping(
        :bill_length_mm => "Bill length (mm)",
        :bill_depth_mm => "Bill depth (mm)",
        row = :sex,
        col = :island,
        color = :species => "Species"
    ) *
    visual(Scatter)

figuregrid = draw(spec)
```

The type of `figuregrid` is:

```@example tut
typeof(figuregrid)
```

True to its name, it stores two fields, `figure` and `grid`.

The `figure` contains the Makie `Figure` object in which every other element is drawn.
We can do basic modifications to its underlying `Scene` object, like changing its background color (check Makie's [scene tutorial](https://docs.makie.org/stable/tutorials/scenes) for more information on `Scene`s):

```@example tut
figure = figuregrid.figure

figure.scene.backgroundcolor = Makie.to_color(:gray90)

figure
```

We can also resize the figure:

```@example tut
resize!(figure, 500, 300)

figure
```

## Drawing into an existing `Figure`

But we can also add further objects to our `Figure`.
And we can do this directly with AlgebraOfGraphics by using the `draw!` function instead of `draw` (the `!` is a naming convention in Julia that hints that something is being modified by a function, here a `Figure`).

Let's say we wanted to also show flipper length vs body mass in a separate plot.
We can do that by `draw!`ing the specification into a grid position of the underlying figure layout (check, for example, [the layout tutorial in the Makie docs](https://docs.makie.org/stable/tutorials/layout-tutorial) to learn more about grid layouts). 

To know where to put our new plot, it can be helpful to look at the current layout first:

```@example tut
figure.layout
```

This `[1:2, 1:4]` layout has 2 rows and 4 columns, so if we wanted to put something to the right of it, that could live in fifth column and cross over both rows.
Let's execute that idea by specifying the grid position `figure[:, 5]`. This means all rows, 5th column (which will be created if it doesn't exist):

```@example tut
flipper_spec = data(penguins) *
    mapping(:flipper_length_mm => "Flipper length (mm)", :body_mass_g => "Body mass (g)", color = :species)

figuregrid_flipper = draw!(figure[:, 5], flipper_spec)

figure
```

As you can see, our `flipper_spec`, while using a color scale, did not create its own legend. AlgebraOfGraphics doesn't automatically draw legends when `draw!` is used, because it's likely that the position should be something special anyway. We could draw the legend by calling `legend!(figure[row, col], figuregrid_flipper)` but we don't need it here because it would be redundant. If you skip redundant legends, make sure that they really are the same though, and you didn't accidentally assign colors differently in one of the graphs!

Our composed figure is a bit squished, so we could resize again:

```@example tut
resize!(figure, 700, 400)

figure
```

## Layout modifications

Maybe we don't like the position of the shared legend. In Makie, we can move layout elements around whenever we want, we just need to get ahold of them first.
We can get the only `Legend` object in different ways, one would be to get it from the `figure.content` vector:

```@example tut
legend = only(filter(x -> x isa Legend, figure.content))
```

Another way would be to use its layout position `[1:2, 4]` that we printed above, and grab it with Makie's `content` function:

```@example tut
legend = content(figure[1:2, 4])
```

We can move the legend to any other place by assigning it to a new layout position. I want to place it centered below both other plots, for which I will also change its orientation to horizontal:

```@example tut
legend.orientation = :horizontal
legend.titleposition = :left
figure[end+1, :] = legend

figure
```

The legend has moved correctly, although it has also left a hole in column 4. We can delete that column with the `deletecol!` function from `GridLayoutBase`, which is the package that implements Makie's layouts:

```@example tut
Makie.GridLayoutBase.deletecol!(figure.layout, 4)

figure
```

To label our two subplots, we can add Makie's `Label` objects to our figure.
By using the `TopLeft()` side, we place the labels outside of the main grid and left-aligned into the gap space:

```@example tut
Label(figure[1, 1, TopLeft()], "A", font = :bold, fontsize = 24, halign = :left)
Label(figure[1, 4, TopLeft()], "B", font = :bold, fontsize = 24, halign = :left)
figure
```

Maybe the fourth column is a little thin with 25%, we could push it up to 40% to balance out the look:

```@example tut
colsize!(figure.layout, 4, Relative(0.4))

figure
```

## Axis modifications

We haven't looked at the `grid` field of `figuregrid`, yet.
It contains `AxisEntries` objects which store references to all the axes in a plot's facet layout.
So if we want to make some axis modifications after the fact, we can grab them from there, too:

Let's pretend that the data in row 2, column 2 of our original facet plot is somehow of high importance, which we'd like to signal with a reddish background color:

```@example tut
figuregrid.grid[2, 2].axis.backgroundcolor = :rosybrown1

figure
```

To explain why we colored one axis red, we can add a small footnote-like `Label` to the figure:

```@example tut
Label(
    figure[end+1, :],
    rich(
        rich("⬛", color = :rosybrown1, fontsize = 18),
        " The male penguins on Dream island have to be mentioned specifically.",
        fontsize = 10
    ),
    halign = :right,
)

figure
```

## Free modifications

One last example to really emphasize the flexibility of plotting with Makie and AlgebraOfGraphics home.
As the `Figure` is basically just a drawing canvas, we can freely plot into it wherever we want.
You could imagine drawing connections between different axes or labels, annotations outside the margins, whatever you can think of.

Let's say we wanted to distribute our figure during review, and wanted to mark it as a draft.
We can achieve this by plotting a `text` into the main `Scene` of the figure, effectively plotting across all other content.

```@example tut
text!(figure.scene, 0.5, 0.5, space = :relative, fontsize = 200, text = "DRAFT",
    color = (:gray, 0.1), rotation = pi/8, font = :bold, align = (:center, :center))

figure
```

## Summary

In this chapter, you have seen how to draw compose multiple AlgebraOfGraphics plots in a Makie `Figure`, make layout, legend and axis modifications, and achieve even more unusual effects by plotting directly into the figure's main scene. Making use of all of these options can save you a lot of time that you would otherwise spend editing and re-editing your plots manually. For more techniques and possibilities, refer to sources like [Makie's documentation](https://docs.makie.org/stable/) or the gallery [Beautiful Makie](https://beautiful.makie.org/).

