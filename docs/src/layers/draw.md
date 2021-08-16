# Drawing Layers

A [`AlgebraOfGraphics.Layer`](@ref) or [`AlgebraOfGraphics.Layers`](@ref) object can be plotted
using the functions [`draw`](@ref) or [`draw!`](@ref).

Whereas `draw` automatically adds colorbar and legend, `draw!` does not, as it
would be hard to infer a good default placement that works in all scenarios.

Colorbar and legend, should they be necessary, can be added separately with the
[`colorbar!`](@ref) and [`legend!`](@ref) helper functions. See also
[Nested layouts](@ref) for a complex example.
