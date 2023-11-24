# ---
# title: Figure tweaking
# cover: assets/figure_tweaking.png
# description: Setting figure attributes.
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
set_aog_theme!() #src

# To tweak figure attributes, simply use the `figure` keyword when plotting. For example

df = (x=rand(100), y=rand(100), z=rand(100), c=rand(["a", "b"], 100))
xyc = data(df) * mapping(:x, :y, layout=:c)
layers = linear() + mapping(color=:z)
plt = xyc * layers
fg = draw(
    plt,
    axis=(aspect=1,),
    figure=(figure_padding=10, backgroundcolor=:gray80, size=(800, 400))
)

# save cover image #src
mkpath("assets") #src
save("assets/figure_tweaking.png", fg) #src
