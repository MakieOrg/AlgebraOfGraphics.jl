# AlgebraOfGraphics.jl v0.4 Release Notes

## Breaking changes

- Removed deprecations for `style` and `spec` (now only `mapping` and `visual` are allowed).
- Analyses now require parentheses (i.e. `linear()` instead of `linear`).
- Rename `layout_x` and `layout_y` to `col` and `row`.
- Rename `wts` keyword argument to `weights`.
- `categorical` has been replaced by `nonnumeric`