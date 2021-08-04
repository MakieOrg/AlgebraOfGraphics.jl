# Drawing Layers

A `Layer` or `Layers` object can be plotted using the functions `draw` or `draw!`.

```@docs
draw
draw!
```

Whereas `draw` automatically adds colorbar and legend, `draw!` does not, as it
would be hard to infer a good default placement that works in all scenarios.

Colorbar and legend, should they be necessary, can be added separately with the
`colorbar!` and `legend!` helper functions. See also
[Embedding AlgebraOfGraphics plots in a Makie figure](@ref) for a complex example.

```@docs
colorbar!
legend!
```
