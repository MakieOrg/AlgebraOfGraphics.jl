# Mappings

Mappings determine how the date is translated into a plot.
Positional mappings correspond to the `x`, `y` or `z` axes of the plot,
whereas the keyword arguments correspond to plot attributes that can vary
continuously or discretely, such as `color` or `markersize`.

Mapping variables  are split according to the categorical attributes in it,
and then converted to plot attributes using a default palette.

```@example
using AlgebraOfGraphics
mapping(:weight_mm => "weight (mm)", :height_mm => "height (mm)", marker = :gender)
```