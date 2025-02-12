using AlgebraOfGraphics, CairoMakie

resolution = (800, 600)
fig = Figure(; resolution)
ax = Axis(fig[1, 1], title="Some plot")

df = (
    x=rand(500),
    y=rand(500),
    i=rand(["a", "b", "c"], 500),
    j=rand(["d", "e", "f"], 500),
    k=rand(Bool, 500),
    l=rand(Bool, 500)
)
plt = data(df) * mapping(:x, :y, col=:i, row=:j, color=:k, marker=:l)

subfig = fig[1, 2:3]
ag = draw!(subfig, plt)
for ae in ag
    ae.axis.xticklabelrotation[] = π/2
end
legend!(fig[end+1, 2], ag, orientation=:horizontal, tellheight=true)
fig

resolution = (800, 600)
f = Figure(; resolution)
ax = Axis(f[1, 1], title="Some plot")
subfig = f[1, 2]
ax2 = Axis(subfig[1, 1])

df = (
    x=rand(500),
    y=rand(500),
    c=rand(["a", "b", "c"], 500),
)
plt = data(df) * mapping(:x, :y, color=:c)

draw!(subfig[2, 1], plt)
f

resolution = (800, 300)
f = Figure(; resolution)
ax1 = Axis(f[1, 1])
ax2 = Axis(f[1, 2])

df = (x=rand(100), y=rand(100), c=rand(["a", "b", "c"], 100))
plt = data(df) * mapping(:x, :y, color=:c)

scatter!(ax1, rand(10), rand(10), color=:black)
grid = draw!(ax2, plt)
legend!(f[1, 3], grid)

f

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

