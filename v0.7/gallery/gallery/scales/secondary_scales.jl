using AlgebraOfGraphics, CairoMakie

nevents = 500
ngroups = 3
time = repeat(1:nevents, ngroups)
y = reduce(vcat, [cumsum(randn(length(time))) for _ in 1:ngroups])
group = repeat(["A", "B", "C"], inner = nevents)
df1 = (; time, y, group)
df2 = (; time = [30, 79, 250, 400], event = ["X", "Y", "Y", "X"])

spec_a = data(df1) * mapping(:time, :y, color = :group) * visual(Lines)
spec_b = data(df2) * mapping(:time, color = :event) * visual(VLines)

draw(spec_a + spec_b)

split_spec = spec_a + spec_b * mapping(color = :event => scale(:secondary))
draw(split_spec)

fg = draw(split_spec, scales(secondary = (;
    palette = [:gray70, :gray30]
)))

draw(
    split_spec,
    scales(
        secondary = (; palette = [:gray70, :gray30])
    );
    legend = (; order = [[:Color, :secondary] => "Legend"])
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
