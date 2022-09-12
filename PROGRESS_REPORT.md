# Progress Report

## Test

- Reworked internal representation of layers and processed layers to enable "Makie-independent testing" in [#312](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/312), [#313](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/313), and [#316](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/316).

- Added tests for the following analyses (in [#319](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/319)):
    - density (1d and 2d),
    - expectation (1d and 2d),
    - frequency (1d and 2d),
    - histogram (1d and 2d),
    - weighted histogram (1d and 2d),
    - linear regression,
    - weighted linear regression,
    - smooth regression.

- Added tests for categorical scales (in [#338](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/338)).

- Simplified and tested logic for facet layout (in [#336](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/336)):
    - simplified faceting code (removed around 150 lines of code),
    - tested processing of `linkxaxes, linkyaxes, hidexdecorations, hideydecorations` keywords,
    - avoid silently ignoring misspelled attributes in `facet`,
    - tested correct computation and placement of facet labels and spanned guide labels,
    - tested correct linking behavior in facet wrap and grid, also in the presence of missing subplots,
    - tested correct decoration hiding behavior in facet wrap and grid, also in the presence of missing subplots,
    - fixed incorrect decoration hiding behavior in facet grid with missing subplot,
    - fixed minor grid bug (issue [#325](https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/325)).

- TODO: finalize and test wide and pregrouped APIs (see [#345](https://github.com/MakieOrg/AlgebraOfGraphics.jl/discussions/345))
- TODO: test logic from `ProcessedLayer` to plot
- TODO: test legend construction
- TODO: unit tests for grouping machinery (esp. `_groupreduce`)
- TODO: optimize and test plotting for geometrical objects (GeoInterface)

## Faceted plots

- Improved performance by blocking MakieLayout updates while building the figure. Done as part of [#316](https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/316).

TODO: support pagination of large facet plots.

## Categorical conversions

At the moment, aggressive categorical conversion can interfere with custom recipes, especially if they rely on custom types.

TODO: discuss possible strategies to address this, [see comment](https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/300#issuecomment-949541900).

## Non-standard recipes / axis interaction

TODO: handle recipes that modify the axis (e.g., `hlines!`).

TODO: handle recipes that require multiple axes (e.g. `corrplot`)?
