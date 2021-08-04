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