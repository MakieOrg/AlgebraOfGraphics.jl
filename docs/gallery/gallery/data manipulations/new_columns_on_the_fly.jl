# ---
# title: Renaming and transforming variables
# cover: assets/new_columns_on_the_fly.png
# description: Transforming data before generating the plot
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
layers = linear() + mapping(color=:z)

plt = data(df) * layers * mapping(:x => (x -> x^2) => L"x^2", :y => L"This variable is called $y$")
fg = draw(plt)

# Use a `Tuple` to pass combine several columns into a unique operation.

plt = data(df) * layers * mapping(:x, (:x, :y, :z) => (+) => L"the new variable $x + y + z$", layout=:c)
fg = draw(plt)

# save cover image #src
mkpath("assets") #src
save("assets/new_columns_on_the_fly.png", fg) #src
