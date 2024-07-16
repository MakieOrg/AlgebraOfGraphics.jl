# Release Notes

## v0.7

### Breaking Changes

- The `palette` keyword of `draw` linking palettes to keyword arguments was removed. Instead, palettes need to be passed to specific scales like `draw(..., scales(Color = (; palette = :Set1_3)))`
- All recipes need to have the new function `aesthetic_mapping` defined for all sets of positional arguments that should be supported, as can be seen in `src/aesthetics.jl`. This breaks usage of all custom recipes. Additionally, not all Makie plots have been ported to the new system yet. If you encounter missing plots, or missing attributes of already ported plots, please open an issue.
- All custom recipes that should be displayed in a legend, need to have `legend_elements(P, attributes, scale_args)` defined as can be seen in `src/guides/legend.jl`. AlgebraOfGraphics cannot use the same default mechanism as Makie, which can create a legend from an existing plot, because AlgebraOfGraphics needs to create the legend before the plot is instantiated.
- Pregrouped data cannot be passed anymore to the plain `mapping(...)` without any `data(tabular)`. Instead, you should use `pregrouped(...)` which is a shortcut for `data(Pregrouped()) * mapping(...)`.
- `Contour` and `Contourf` generally do not work anymore with `visual()`. Instead, the `contours()` and `filled_contours()` analyses should be used. `Contour` can still be used with categorical colors, but not with continuous ones.
- All colormap properties for continuous color scales need to be passed via `scales` now, and not through `visual`. This is to have central control over the scale as it can be used by multiple `visual`s simultaneously.

### New Features

- Horizontal barplots, violins, errorbars, rangebars and other plot types that have two different orientations work correctly now. Axis labels switch accordingly when the orientation is changed.
- Plotting functions whose positional arguments don't correspond to X, Y, Z work correctly now. For example, `HLines` (1 => Y) or `rangebars` (1 => X, 2 => Y, 3 => Y).
- It is possible to add categories beyond those present in the data with the `categories` keyword within a scale's settings. It is also possible to reorder or otherwise transform the existing categories by passing a function to `categories`.
- The supported attributes are not limited anymore to a specific set of names, for example, `strokecolor` can work the same as `color` did before, and the two can share a scale via their shared aesthetic type.
- There can be multiple scales of the same aesthetic now. This allows to have separate legends for different plot types using the same aesthetics. Scale separation works by pairing a variable in `mapping` with a `scale(id_symbol)`.
- Legend entries can be reordered using the `legend = (; order = ...)` option in `draw`. Specific scales can opt out of the legend by passing `legend = false` in `scales`.
- Labels can now be anything that Makie supports, primarily `String`s, `LaTeXString`s or `rich` text.
- Legend elements now usually reflect all attributes set in their corresponding `visual`.
- Simple column vectors of data can now be passed directly to `mapping` without using `data` first. Additionally, scalar values are accepted as a shortcut for columns with the same repeated value.
- Columns from outside a table source in `data` can now be passed to `mapping` by wrapping them in the `direct` function. Scalar values are accepted as a shortcut for columns with the same repeated value. For example, to create a label for columns `x` and `y` from a dataframe passed to `data`, one could now do `mapping(:x, :y, color = direct("label"))` without having to create a column full of `"label"` strings first.
- The numbers at which categorical values are plotted on x and y axis can now be changed via `scales(X = (; palette = [1, 2, 4]))` or similar.
- Continuous marker size scales can now be shown in the legend. Numerical values are proportional to area and not diameter now, which makes more sense with respect to human perception. The min and max marker size can be set using the `sizerange` property for the respective scale in `scales`.

## v0.6

### Breaking Changes

- Default axis linking behavior has changed: now only axes corresponding to the same variable are linked. For consistency with `row`/`col`, `layout` will hide decorations of linked axes and span axis labels if appropriate.

### New Features

- Customizable axis linking behavior.
- Customizable legend and colorbar position and look.
- In v0.6.1, support `level` in `linear` analysis for confidence interval.
- In v0.6.8, added `choropleth` recipe to supersede `geodata` for geographical data.
- In v0.6.11, added `paginate` for pagination of large facet plots. 

### Internal changes

- In v0.6.1, replaced tuples and named tuples in `Layer` and `Entry` with dictionaries from [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl).
- In v0.6.1, split internal `Entry` type into `ProcessedLayer` (to be used for analyses) and `Entry` (to be used for plotting).

## v0.5

### Breaking Changes

- `Axis(ae)` has been replaced by `ae.axis`.
- `Legend(fg)` has been replaced by `legend!(fg)` and `colorbar!(fg)`.

### New Features

- `legend!` and `colorbar!` API allows for custom legend placement.

## v0.4

### Breaking Changes

- Removed deprecations for `style` and `spec` (now only `mapping` and `visual` are allowed).
- Analyses now require parentheses (i.e. `linear()` instead of `linear`).
- Rename `layout_x` and `layout_y` to `col` and `row`.
- Rename `wts` keyword argument to `weights`.
- `categorical` has been replaced by `nonnumeric`.