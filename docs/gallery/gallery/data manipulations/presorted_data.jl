# ---
# title: Pre-sorted data
# cover: assets/presorted_data.png
# description: Preserving the original order of categorical data.
# author: "Julius Krumbiegel"
# ---

using AlgebraOfGraphics, CairoMakie, DataFrames
set_aog_theme!() #src

# Sometimes we have datasets that have an inherent order we want to preserve.
# For example, this dataframe has countries sorted by `some_value`.

countries = ["Algeria", "Bolivia", "China", "Denmark", "Ecuador", "France"]
group = ["2", "3", "1", "1", "3", "2"]
some_value = exp.(sin.(1:6))

df = DataFrame(; countries, group, some_value)
sort!(df, :some_value)

df

# When we plot this, the categorical variable `countries` is sorted alphabetically by default:

spec = data(df) *
    mapping(:countries, :some_value, color = :group) *
    visual(BarPlot, direction = :x)
draw(spec)

# We don't want this, because we have purposefully sorted the dataframe to visualize which countries have the highest value.
# To retain the order, we can use the `presorted` helper.

spec = data(df) *
    mapping(:countries => presorted, :some_value, color = :group) *
    visual(BarPlot, direction = :x)
fg = draw(spec)

# We can also mark multiple variables as presorted, note how the order in the color legend shifts when we do the same for `group`:

spec = data(df) *
    mapping(:countries => presorted, :some_value, color = :group => presorted) *
    visual(BarPlot, direction = :x)
draw(spec)

# save cover image #src
mkpath("assets") #src
save("assets/presorted_data.png", fg) #src
