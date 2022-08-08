# AlgebraOfGraphics.jl v0.6 Release Notes

## Breaking Changes

- Default axis linking behavior has changed: now only axes corresponding to the same variable are linked. For consistency with `row`/`col`, `layout` will hide decorations of linked axes and span axis labels if appropriate.

## New Features

- Customizable axis linking behavior.
- Customizable legend and colorbar position and look.
- In v0.6.1, support `level` in `linear` analysis for confidence interval.
- In v0.6.8, added `choropleth` recipe to supersede `geodata` for geographical data.
- In v0.6.11, added `paginate` for pagination of large facet plots. 

## Internal changes

- In v0.6.1, replaced tuples and named tuples in `Layer` and `Entry` with dictionaries from [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl).
- In v0.6.1, split internal `Entry` type into `ProcessedLayer` (to be used for analyses) and `Entry` (to be used for plotting).

# AlgebraOfGraphics.jl v0.5 Release Notes

## Breaking Changes

- `Axis(ae)` has been replaced by `ae.axis`.
- `Legend(fg)` has been replaced by `legend!(fg)` and `colorbar!(fg)`.

## New Features

- `legend!` and `colorbar!` API allows for custom legend placement.

# AlgebraOfGraphics.jl v0.4 Release Notes

## Breaking Changes

- Removed deprecations for `style` and `spec` (now only `mapping` and `visual` are allowed).
- Analyses now require parentheses (i.e. `linear()` instead of `linear`).
- Rename `layout_x` and `layout_y` to `col` and `row`.
- Rename `wts` keyword argument to `weights`.
- `categorical` has been replaced by `nonnumeric`.