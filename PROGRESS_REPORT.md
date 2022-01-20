# Progress Report

## Test

- Reworked internal representation of layers and processed layers to enable "Makie-independent testing" in [#312](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/312), [#313](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/313), and [#316](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/316).

- Added tests for the following analyses (in [#319](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/319)):
    - density (1d and 2d),
    - expectation (1d and 2d),
    - frequency (1d and 2d),
    - histogram (1d and 2d),
    - weighted histogram (1d and 2d),
    - linear regression,
    - weighted linear regression,
    - smooth regression.

## Faceted plots

- Improved performance by blocking MakieLayout updates while building the figure. Done as part of [#316](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/pull/316).

TODO: support pagination of large facet plots.

## Categorical conversions 

At the moment, aggressive categorical conversion can interfere with custom recipes, especially if they rely on custom types.

TODO: discuss possible strategies to address this, [see comment](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/issues/300#issuecomment-949541900).

## Non-standard recipes / axis interaction

TODO: handle recipes that modify the axis (e.g., `hlines!`).

TODO: handle recipes that require multiple axes (e.g. `corrplot`)?