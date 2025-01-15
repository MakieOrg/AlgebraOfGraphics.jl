# Changelog

## Unreleased

- Added the ability to use multiple different X and Y scales within one facet layout. The requirement is that not more than one X and Y scale is used per facet. `Row`, `Col` and `Layout` scales got the ability to set `show_labels = false` in `scales`. Also added the `zerolayer` function which can be used as a basis to build up the required mappings iteratively [#586](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/586).
- Increased compat to Makie 0.22 and GeometryBasics 0.5 [#587](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/587).

## v0.8.13 - 2024-10-21

- Added aesthetics for `Stairs` [#573](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/573).

## v0.8.12 - 2024-10-07

- Added `legend` keyword in `visual` to allow overriding legend element attributes [#570](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/570).

## v0.8.11 - 2024-09-25

- Fixed lexicographic natural sorting of tuples (this would fall back to default sort order before) [#568](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/568).

## v0.8.10 - 2024-09-24

- Fixed markercolor in `ScatterLines` legends when it did not match `color` [#567](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/567).

## v0.8.9 - 2024-09-24

- Added ability to include layers in the legend without using scales by adding `visual(label = "some label")` [#565](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/565).

## v0.8.8 - 2024-09-17

- Fixed aesthetics of `errorbar` so that x and y stay labelled correctly when using `direction = :x` [#560](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/560).
- Added ability to specify `title`, `subtitle` and `footnotes` plus settings in the `draw` function [#556](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/556).
- Added `dodge_x` and `dodge_y` keywords to `mapping` that allow to dodge any plot types that have `AesX` or `AesY` data [#558](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/558).

## v0.8.7 - 2024-09-06

- Added ability to return `ProcessedLayers` from transformations, thereby enabling multi-layer transformations, such as scatter plus errorbars [#549](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/549).
- Fixed bug where `mergesorted` applied on string vectors used `isless` instead of natural sort [#553](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/553).

## v0.8.6 - 2024-09-02

- Added `bar_labels` to `BarPlot`'s aesthetic mapping [#544](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/544).
- Added ability to hide legend or colorbar by passing, e.g., `legend = (; show = false)` to `draw` [#547](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/547).

## v0.8.5 - 2024-08-27

- Added `presorted` helper function to keep categorical data in the order encountered in the source table, instead of sorting it alphabetically [#529](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/529).
- Added `from_continuous` helper function which allows to sample continuous colormaps evenly to use them as categorical palettes without having to specify how many categories there are [#541](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/541).

## v0.8.4 - 2024-08-26

- Added `fillto` to `BarPlot` aesthetics [#535](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/535).
- Fixed bug when giving `datalimits` of `density` as a (low, high) tuple [#536](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/536).
- Fixed bug where facet-local continuous scale limits were used instead of the globally merged ones, possibly leading to mismatches between data and legend [#539](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/539).

## v0.8.3 - 2024-08-23

- Fixed incorrect x/y axis assignment for the `violin` plot type [#528](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/528).

## v0.8.2 - 2024-08-21

- Enable use of `LaTeXString`s and `rich` text in `renamer` [#525](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/525).
- Fixed widths of boxplots with color groupings [#524](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/524).

## v0.8.1 - 2024-08-20

- Added back support for `Hist`, `CrossBar`, `ECDFPlot` and `Density` [#522](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/522).

## v0.8.0 - 2024-07-26

- **Breaking**: Columns with element types of `Union{Missing,T}` are not treated as categorical by default anymore, instead `T` decides if data is seen as categorical, continuous or geometrical. If you relied on numerical vectors with `missing`s being treated as categorical, you can use `:columnname => nonnumeric` in the `mapping` instead.
- **Breaking**: `AbstractString` categories are now sorted with natural sort order by default. This means that where you got `["1", "10", "2"]` before, you now get `["1", "2", "10"]`. You can use `sorter`, the `categories` keyword or categorical arrays to sort your data differently if needed.

## v0.7.0 - 2024-07-16

- **Breaking**: The `palette` keyword of `draw` linking palettes to keyword arguments was removed. Instead, palettes need to be passed to specific scales like `draw(..., scales(Color = (; palette = :Set1_3)))`
- **Breaking**: All recipes need to have the new function `aesthetic_mapping` defined for all sets of positional arguments that should be supported, as can be seen in `src/aesthetics.jl`. This breaks usage of all custom recipes. Additionally, not all Makie plots have been ported to the new system yet. If you encounter missing plots, or missing attributes of already ported plots, please open an issue.
- **Breaking**: All custom recipes that should be displayed in a legend, need to have `legend_elements(P, attributes, scale_args)` defined as can be seen in `src/guides/legend.jl`. AlgebraOfGraphics cannot use the same default mechanism as Makie, which can create a legend from an existing plot, because AlgebraOfGraphics needs to create the legend before the plot is instantiated.
- **Breaking**: Pregrouped data cannot be passed anymore to the plain `mapping(...)` without any `data(tabular)`. Instead, you should use `pregrouped(...)` which is a shortcut for `data(Pregrouped()) * mapping(...)`.
- **Breaking**: `Contour` and `Contourf` generally do not work anymore with `visual()`. Instead, the `contours()` and `filled_contours()` analyses should be used. `Contour` can still be used with categorical colors, but not with continuous ones.
- **Breaking**: All colormap properties for continuous color scales need to be passed via `scales` now, and not through `visual`. This is to have central control over the scale as it can be used by multiple `visual`s simultaneously.
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

## v0.6.11 - 2022-08-08

- Added `paginate` for pagination of large facet plots. 

## v0.6.8 - 2022-06-14

- Added `choropleth` recipe to supersede `geodata` for geographical data.

## v0.6.1 - 2022-01-28

- Support `level` in `linear` analysis for confidence interval.
- Replaced tuples and named tuples in `Layer` and `Entry` with dictionaries from [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl).
- Split internal `Entry` type into `ProcessedLayer` (to be used for analyses) and `Entry` (to be used for plotting).

## v0.6.0 - 2021-10-24

- **Breaking**: Default axis linking behavior has changed: now only axes corresponding to the same variable are linked. For consistency with `row`/`col`, `layout` will hide decorations of linked axes and span axis labels if appropriate.
- Customizable legend and colorbar position and look.
- Customizable axis linking behavior.

## v0.5 - 2021-08-05

- **Breaking**: `Axis(ae)` has been replaced by `ae.axis`.
- **Breaking**: `Legend(fg)` has been replaced by `legend!(fg)` and `colorbar!(fg)`.
- `legend!` and `colorbar!` API allows for custom legend placement.

## v0.4 - 2021-05-21

- **Breaking**: Removed deprecations for `style` and `spec` (now only `mapping` and `visual` are allowed).
- **Breaking**: Analyses now require parentheses (i.e. `linear()` instead of `linear`).
- **Breaking**: Rename `layout_x` and `layout_y` to `col` and `row`.
- **Breaking**: Rename `wts` keyword argument to `weights`.
- **Breaking**: `categorical` has been replaced by `nonnumeric`.