reftest("barplot") do
    data((; x = 1:4, y = ["A", "B", "C", "D"])) * mapping(:x, :y) * visual(BarPlot) |> draw
end

reftest("barplot one arg") do
    data((; y = ["A", "B", "C", "D"])) * mapping(:y) * visual(BarPlot) |> draw
end

reftest("barplot horizontal") do
    data((; x = 1:4, y = ["A", "B", "C", "D"])) * mapping(:x, :y) * visual(BarPlot, direction = :x) |> draw
end

reftest("barplot one arg horizontal") do
    data((; y = ["A", "B", "C", "D"])) * mapping(:y) * visual(BarPlot, direction = :x) |> draw
end

reftest("barplot cat color") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = ["X", "X", "Y", "Y"])) * mapping(:x, :y, color = :z) * visual(BarPlot, direction = :x) |> draw
end

reftest("barplot con color") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = 1:4)) * mapping(:x, :y, color = :z) * visual(BarPlot) |> draw
end

reftest("barplot cat color palette") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = ["X", "X", "Y", "Y"])) * mapping(:x, :y, color = :z) * visual(BarPlot, direction = :x) |>
        draw(scales(Color = (; palette = :Set1_3)))
end

reftest("barplot layout") do
    data((; x = ["A", "B", "C"], y = 1:3, z = ["X", "Y", "Z"])) * mapping(:x, :y; layout = :z) * visual(BarPlot) |> draw
end

reftest("barplot col layout") do
    data((; x = ["A", "B", "C"], y = 1:3, z = ["X", "Y", "Z"])) * mapping(:x, :y; col = :z) * visual(BarPlot) |> draw
end

reftest("barplot row layout") do
    data((; x = ["A", "B", "C"], y = 1:3, z = ["X", "Y", "Z"])) * mapping(:x, :y; row = :z) * visual(BarPlot) |> draw
end

reftest("barplot fillto") do
    df = (; x = 11:20, upper = 1:10, lower = 0:-1:-9)
    spec = data(df) * mapping(:x, :upper, fillto = :lower) * visual(BarPlot)
    draw(spec)
end

reftest("barplot fillto direction x") do
    df = (; x = 11:20, upper = 1:10, lower = 0:-1:-9)
    spec = data(df) * mapping(:x, :upper, fillto = :lower) * visual(BarPlot, direction = :x)
    draw(spec)
end

reftest("barplot labels") do
    df = (; x = 1:6, y = [1, 2, 3, 2, 4, 1], group = [1, 2, 3, 2, 3, 4], label = ["A", "B", "C", "D", "E", "F"])
    spec = data(df) * mapping(:x, :y, color = :group => nonnumeric, bar_labels = :label => verbatim) * visual(BarPlot, label_font = :bold)
    draw(spec)
end

for (plottype, name) in zip([Lines, Scatter], ["lines", "scatter"])
    reftest("$name") do
        data((; x = [1, 3, 2, 4], y = ["A", "B", "C", "D"])) * mapping(:x, :y) * visual(plottype) |> draw
    end

    reftest("$name one arg") do
        data((; y = [1, 3, 2, 4])) * mapping(:y) * visual(plottype) |> draw
    end

    reftest("$name cat color") do
        data((; x = [1, 3, 2, 4], y = ["A", "B", "C", "D"], group = ["A", "A", "B", "B"])) *
            mapping(:x, :y, color = :group) * visual(plottype) |> draw
    end

    reftest("$name con color") do
        data((; x = [1, 3, 2, 4], y = ["A", "B", "C", "D"], z = [1, 5, 3, 9])) *
            mapping(:x, :y, color = :z) * visual(plottype) |> draw
    end
end

reftest("lines group") do
    data((; x = 1:4, y = 2:5, z = string.([1, 1, 2, 2]))) *
        mapping(:x, :y, group = :z) *
        visual(Lines) |> draw
end

reftest("lines linestyle") do
    data((; x = 1:4, y = 2:5, z = string.([1, 1, 2, 2]))) *
        mapping(:x, :y, linestyle = :z) *
        visual(Lines) |> draw
end

reftest("lines continuous linewidth") do
    spec = data(
        (;
            x = repeat(0:1, 5),
            y = repeat(0:1, 5) .+ repeat(1:5, inner = 2),
            z = repeat([1, 2, 5, 10, 20], inner = 2),
        )
    ) * mapping(:x, :y, linewidth = :z, group = :z => nonnumeric) *
        visual(Lines)
    f = Figure()
    fg1 = draw!(f[1, 1], spec)
    legend!(f[1, 2], fg1)
    fg2 = draw!(f[2, 1], spec, scales(LineWidth = (; sizerange = (2, 10), ticks = [1, 2, 5, 10])))
    legend!(f[2, 2], fg2)
    f
end

reftest("scatter strokecolor") do
    data((; x = 1:4, y = 5:8, z = ["A", "B", "C", "D"])) *
        mapping(:x, :y, strokecolor = :z) *
        visual(Scatter, strokewidth = 5, markersize = 30, color = (:blue, 0.1)) |>
        draw(scales(Color = (; palette = :tab20)))
end

reftest("scatter second scale strokecolor") do
    data((; x = 1:4, y = 2:5, z = ["A", "B", "C", "D"], q = ["w", "x", "y", "z"])) *
        mapping(:x, :y, color = :z, strokecolor = :q => scale(:color2)) *
        visual(Scatter, markersize = 20, strokewidth = 4, strokecolor = :transparent, color = :transparent) |>
        draw(scales(color2 = (; palette = :Set1_5)))
end

reftest("scatter con color highclip lowclip") do
    data((; x1 = 1:4, x2 = 5:8, y = 1:4, z1 = 1:4, z2 = 5:8)) *
        (
        mapping(:x1, :y, color = :z1) * visual(Scatter, markersize = 20, colormap = :plasma) +
            mapping(:x2, :y, color = :z2) * visual(Scatter, markersize = 20)
    ) |>
        draw(scales(Color = (; colormap = :viridis, colorrange = (2, 7), lowclip = :red, highclip = :cyan)))
end

reftest("scatter con color layout") do
    data((; x = 1:8, y = 11:18, z = 1:8, group = repeat(["A", "B"], inner = 4))) *
        mapping(:x, :y, color = :z, layout = :group) * visual(Scatter, markersize = 20) |>
        draw
end

reftest("scatter marker") do
    data((; x = 1:4, y = 5:8, z = ["A", "B", "C", "D"])) * mapping(:x, :y, marker = :z) * visual(Scatter, markersize = 20) |> draw
end

reftest("scatter markersize") do
    data((; x = 1:10, y = 1:10, z = 1:10)) * mapping(:x, :y, markersize = :z) * visual(Scatter, color = :red) |> draw
end

reftest("scatter markersize sizerange") do
    data((; x = 1:10, y = 1:10, z = 1:10)) * mapping(:x, :y, markersize = :z) * visual(Scatter) |>
        draw(scales(MarkerSize = (; sizerange = (10, 30))))
end

reftest("scatter markersize tick options") do
    data((; x = 1:10, y = 1:10, z = 1:10)) * mapping(:x, :y, markersize = :z) * visual(Scatter) |>
        draw(scales(MarkerSize = (; ticks = [1, 5, 10], tickformat = "{:.2f}")))
end

reftest("violin cat color") do
    data((; x = ["A", "B", "C", "D"], y = [1, 2, 5, 9], z = ["U", "V", "W", "X"])) * mapping(:x, :y; color = :z) * visual(Violin) |> draw
end

reftest("violin cat color horizontal") do
    data((; x = ["A", "B", "C", "D"], y = [1, 2, 5, 9], z = ["U", "V", "W", "X"])) * mapping(:x, :y; color = :z) * visual(Violin, orientation = :horizontal) |> draw
end

reftest("violin cat color side") do
    data((; x = ["A", "B", "C", "D"], y = [1, 2, 5, 9], z = ["U", "V", "W", "X"], q = ["A", "A", "B", "B"])) * mapping(:x, :y; color = :z, side = :q) * visual(Violin) |> draw
end

reftest("hlines cat color") do
    data((; y = 1:4, q = ["A", "A", "B", "B"])) * mapping(:y, color = :q) * visual(HLines) |> draw
end

reftest("vlines cat color") do
    data((; x = 1:4, q = ["A", "A", "B", "B"])) * mapping(:x, color = :q) * visual(VLines) |> draw
end

reftest("vlines hlines linestyle") do
    spec = data((; x = 1:4, q = ["A", "B", "C", "D"])) * mapping(:x, linestyle = :q)
    f = Figure()
    fg1 = draw!(f[1, 1], spec * visual(VLines))
    legend!(f[1, 2], fg1)
    fg2 = draw!(f[2, 1], spec * visual(HLines))
    legend!(f[2, 2], fg2)
    f
end

reftest("vlines hlines cat linewidth") do
    spec = data((; x = 1:4)) * mapping(:x, linewidth = :x => nonnumeric)
    f = Figure()
    fg1 = draw!(f[1, 1], spec * visual(VLines))
    legend!(f[1, 2], fg1)
    fg2 = draw!(f[2, 1], spec * visual(HLines), scales(LineWidth = (; palette = [1, 2, 5, 8])))
    legend!(f[2, 2], fg2)
    f
end

reftest("second scale barplot hlines") do
    data((; x1 = 1:4, x2 = 5:8, y = ["A", "B", "C", "D"], z1 = ["X", "X", "Y", "Y"], z2 = ["Q", "Q", "U", "U"])) *
        (
        mapping(:x1, :y, color = :z1) * visual(BarPlot) +
            mapping(:y, color = :z2 => scale(:second)) * visual(HLines)
    ) |>
        draw(scales(second = (; palette = [:red, :green])))
end

reftest("heatmap") do
    data((; x = [1, 2, 1, 2], y = ["a", "a", "b", "b"], z = ["A", "B", "C", "D"])) *
        mapping(:x, :y, :z) *
        visual(Heatmap) |> draw(scales(Color = (; palette = :Set1_5)))
end

reftest("heatmap missing cell") do
    data((; x = [1, 2, 1], y = ["a", "a", "b"], z = ["A", "B", "C"])) *
        mapping(:x, :y, :z) *
        visual(Heatmap) |> draw(scales(Color = (; palette = :Set1_5)))
end

reftest("heatmap con color") do
    data((; x = 1:4, y = ["a", "b", "c", "d"], z = [1, 2, 3, 6])) *
        mapping(:x, :y, :z) *
        visual(Heatmap) |>
        draw(scales(Color = (; colormap = :Blues, colorrange = (0, 10), nan_color = (:black, 0.1))))
end

reftest("rangebars") do
    data((; x = 1:4, ylow = 1:4, yhigh = 2:5)) * mapping(:x, :ylow, :yhigh) *
        visual(Rangebars) |> draw
end

reftest("rangebars direction x") do
    data((; x = 1:4, ylow = 1:4, yhigh = 2:5)) * mapping(:x, :ylow, :yhigh) *
        visual(Rangebars; direction = :x) |> draw
end

reftest("rangebars cat color") do
    data((; x = 1:4, ylow = 1:4, yhigh = 2:5, z = 1:4)) * mapping(:x, :ylow, :yhigh, color = :z => nonnumeric) *
        visual(Rangebars) |> draw
end

reftest("rangebars cat color direction x") do
    data((; x = 1:4, ylow = 1:4, yhigh = 2:5, z = 1:4)) * mapping(:x, :ylow, :yhigh, color = :z => nonnumeric) *
        visual(Rangebars; direction = :x) |> draw
end

reftest("errorbars") do
    data((; x = ["A", "B", "C", "D"], y = 5:8, err = 2:5)) * mapping(:x, :y, :err) *
        visual(Errorbars) |> draw
end

reftest("errorbars direction x") do
    data((; x = ["A", "B", "C", "D"], y = 5:8, err = 2:5)) * mapping(:x, :y, :err) *
        visual(Errorbars; direction = :x) |> draw
end

reftest("errorbars cat color direction x") do
    data((; x = ["A", "B", "C", "D"], y = 5:8, err = 2:5, z = 1:4)) * mapping(:x, :y, :err, color = :z => nonnumeric) *
        visual(Errorbars; direction = :x) |> draw
end

reftest("errorbars cat color") do
    data((; x = ["A", "B", "C", "D"], y = 5:8, err = 2:5, z = 1:4)) * mapping(:x, :y, :err, color = :z => nonnumeric) *
        visual(Errorbars) |> draw
end

reftest("errorbars low high") do
    data((; x = ["A", "B", "C", "D"], y = 5:8, errlow = [0.1, 0.2, 0.3, 0.4], errhigh = [0.4, 0.2, 0.3, 0.1])) * mapping(:x, :y, :errlow, :errhigh) *
        visual(Errorbars) |> draw
end

reftest("histogram cat color") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, layout = :z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram dodge") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, dodge = :z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram dodge direction x") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, dodge = :z, color = :z) * histogram() * visual(direction = :x)
    draw(specs)
end

reftest("histogram stack") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["b", "a"], inner = 500))
    specs = data(df) * mapping(:x, stack = :z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram stairs cat color") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, layout = :z, color = :z) * histogram(Stairs) * visual(alpha = 0.8, linewidth = 4)
    draw(specs)
end

reftest("histogram scatter cat color") do
    df = (x = [sin.(1:500); sin.(1:500) .* 2], z = repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, layout = :z, color = :z) * histogram(Scatter) * visual(alpha = 0.8, marker = :cross, markersize = 20)
    draw(specs)
end

reftest("histogram 2d") do
    df = (x = sin.(1:300), y = cos.(1:300))
    specs = data(df) * mapping(:x, :y) * histogram()
    draw(specs)
end

reftest("linear cat color") do
    x = 1:100
    y = range(0, 10, length = 100) .+ sin.(1:100) .+ repeat([0, 5], inner = 50)
    z = repeat(["A", "B"], inner = 50)
    specs = data((; x, y, z)) * mapping(:x, :y, color = :z) * (visual(Scatter) + linear())
    draw(specs)
end

reftest("density layout") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, layout = :z) * AlgebraOfGraphics.density() |>
        draw
end

reftest("density layout visual direction y") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, row = :z) * AlgebraOfGraphics.density() * visual(direction = :y) |>
        draw
end

reftest("density layout datalimits extrema") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, layout = :z) * AlgebraOfGraphics.density(datalimits = extrema) |>
        draw
end

reftest("density layout datalimits manual") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, layout = :z) * AlgebraOfGraphics.density(datalimits = (-3, 5)) |>
        draw
end

reftest("density layout cat color") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, layout = :z, color = :z) * AlgebraOfGraphics.density() |>
        draw
end

reftest("density 2d layout") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, :x, layout = :z) * AlgebraOfGraphics.density() |>
        draw
end

reftest("smooth") do
    x = 1:50
    y = sin.(range(0, 2pi, length = 50)) .+ sin.(1:50)
    data((; x, y)) * mapping(:x, :y) * (visual(Scatter) + smooth()) |> draw
end

reftest("smooth cat color") do
    x = 1:50
    y = sin.(range(0, 2pi, length = 50)) .+ sin.(1:50)
    z = repeat(["A", "B"], inner = 25)
    data((; x, y, z)) * mapping(:x, :y, color = :z) * (visual(Scatter) + smooth()) |> draw
end

reftest("frequency") do
    cats = [fill("A", 10); fill("B", 20); fill("C", 15)]
    mapping(cats) * frequency() |> draw
end

reftest("frequency stack") do
    cats = repeat([fill("A", 10); fill("B", 20); fill("C", 15)], 2)
    group = repeat(["A", "B"], inner = 45)
    data((; cats, group)) * mapping(:cats, color = :group, stack = :group) * frequency() |> draw
end

reftest("frequency stack reorder") do
    cats = repeat([fill("A", 10); fill("B", 20); fill("C", 15)], 2)
    group = repeat(["A", "B"], inner = 45)
    data((; cats, group)) * mapping(:cats, color = :group, stack = :group) * frequency() |>
        draw(scales(Stack = (; palette = [2, 1])))
end

reftest("frequency dodge") do
    cats = repeat([fill("A", 10); fill("B", 20); fill("C", 15)], 2)
    group = repeat(["A", "B"], inner = 45)
    data((; cats, group)) * mapping(:cats, color = :group, dodge = :group) * frequency() |> draw
end

reftest("frequency 2d") do
    cats1 = repeat([fill("A", 10); fill("B", 20); fill("C", 15)], 2)
    cats2 = repeat([fill("C", 6); fill("D", 14); fill("E", 10)], 3)
    data((; cats1, cats2)) * mapping(:cats1, :cats2) * frequency() |> draw
end

reftest("expectation") do
    x = repeat(["A", "B", "C", "D", "E"], inner = 10)
    y = sin.(range(0, pi, length = 50))
    data((; x, y)) * mapping(:x, :y) * expectation() |> draw
end

reftest("expectation 2d") do
    x = repeat(repeat(["A", "B", "C", "D", "E"], inner = 10), 5)
    y = repeat(repeat(["F", "G", "H", "I", "J"], inner = 10), inner = 5)
    z = repeat(sin.(range(0, pi, length = 50)), 5) .* repeat(1:5, inner = 50)
    data((; x, y, z)) * mapping(:x, :y, :z) * expectation() |> draw
end

reftest("scales label overrides") do
    data((; x = 1:4, y = 1:4, z = 1:4)) * mapping(:x, :y, color = :z => nonnumeric) *
        visual(Scatter) |> draw(
        scales(
            X = (; label = "XXX"),
            Y = (; label = rich("YYY", color = :red)),
            Color = (; label = L"\sum{x + y}"),
        )
    )
end

reftest("category addition middle") do
    data((; sex = repeat(["m", "f"], 10), weight = 1:20)) *
        mapping(:sex, :weight) *
        visual(Scatter) |> draw(
        scales(
            X = (;
                categories = ["m", "d" => rich("diverse", color = :fuchsia), "f"],
            )
        )
    )
end

reftest("category addition sides") do
    data((; group = repeat(["B", "C"], 10), weight = 1:20)) *
        mapping(:group, :weight) *
        visual(Scatter) |> draw(
        scales(
            X = (;
                categories = ["A", "B", "C", "D"],
            )
        )
    )
end

reftest("x palette override") do
    data((; category = ["A", "B", "C", missing], y = [4, 5, 6, 2])) *
        mapping(:category, :y) *
        visual(BarPlot) |>
        draw(scales(X = (; palette = [1, 2, 3, 5])))
end

reftest("issue 434") do
    df = (; x = 1:5, y = [1, 4, 3, 5, 2], group = [true, true, false, false, false])
    plt = AlgebraOfGraphics.data(df) * mapping(:x, :y; color = :group) * visual(Scatter; marker = :star5, markersize = 15)
    draw(plt)
end

reftest("disable legend") do
    data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z => nonnumeric) * visual(Scatter) |>
        draw(scales(Color = (; legend = false)))
end

reftest("text cat color") do
    x = 1:5
    y = [1, 5, 2, 4, 3]
    label = ["a", "b", "a", "b", "a"]
    df = (; x, y, label)
    plt = data(df) * mapping(:x, :y, text = :label => verbatim, color = :label) * visual(Makie.Text)
    fg = draw(plt)
end

reftest("boxplot") do
    df = (x = repeat(["a", "b", "c"], inner = 20), y = 1:60)
    plt = data(df) *
        mapping(:x, :y) * visual(BoxPlot)
    draw(plt)
end

reftest("boxplot horizontal") do
    df = (x = repeat(["a", "b", "c"], inner = 20), y = 1:60)
    plt = data(df) *
        mapping(:x, :y) * visual(BoxPlot, orientation = :horizontal)
    draw(plt)
end

reftest("boxplot cat color") do
    df = (x = repeat(["a", "b", "c"], inner = 20), y = 1:60)
    plt = data(df) *
        mapping(:x, :y, color = :x) * visual(BoxPlot)
    draw(plt)
end

reftest("boxplot dodge") do
    df = (x = repeat(["a", "b", "c"], inner = 20), x2 = repeat(["x", "y"], 30), y = 1:60)
    plt = data(df) *
        mapping(:x, :y, color = :x2, dodge = :x2) * visual(BoxPlot)
    draw(plt)
end

reftest("contour") do
    x = repeat(range(0, 10, length = 100), 100)
    y = repeat(range(0, 15, length = 100), inner = 100)
    z = @. cos(x) * sin(y)
    data((; x, y, z)) * mapping(:x, :y, :z) * visual(Contour) |> draw
end

reftest("contour cat color") do
    x = repeat(range(0, 10, length = 100), 100)
    y = repeat(range(0, 15, length = 100), inner = 100)
    z = @. cos(x) * sin(y)
    group = repeat(["A", "B"], inner = length(z) ÷ 2)
    data((; x, y, z, group)) * mapping(:x, :y, :z, color = :group) * visual(Contour) |> draw
end

reftest("band") do
    x = 1:10
    lower = sin.(range(0, 2pi, length = 10))
    upper = cos.(range(0, 2pi, length = 10)) .+ 3
    f = Figure()
    spec = data((; x, lower, upper)) * mapping(:x, :lower, :upper) * visual(Band)
    draw!(f[1, 1], spec)
    draw!(f[1, 2], spec * visual(direction = :y))
    f
end

reftest("band cat color") do
    x = 1:10
    lower = sin.(range(0, 2pi, length = 10))
    upper = cos.(range(0, 2pi, length = 10)) .+ 3
    group = repeat(["A", "B"], inner = 5)
    data((; x, lower, upper, group)) * mapping(:x, :lower, :upper, color = :group) *
        visual(Band) |> draw
end

reftest("legend merging") do
    N = 20

    x = [1:N; 1:N]
    y = [sin.(range(0, 2pi, length = N)); cos.(range(0, 2pi, length = N)) .+ 2]
    grp = [fill("a", N); fill("b", N)]

    df = (; x, y, grp)

    layers = visual(Lines) * mapping(linestyle = :grp) + visual(Scatter, markersize = 18) * mapping(marker = :grp)
    plt = data(df) * layers * mapping(:x, :y, color = :grp)

    draw(plt, legend = (; patchsize = (50, 30)))
end

reftest("legend merging breakup") do
    N = 20

    x = [1:N; 1:N]
    y = [sin.(range(0, 2pi, length = N)); cos.(range(0, 2pi, length = N)) .+ 2]
    grp = [fill("a", N); fill("b", N)]

    df = (; x, y, grp)

    layers = visual(Lines) + visual(Scatter, markersize = 18) * mapping(marker = :grp)
    plt = data(df) * layers * mapping(:x, :y, color = :grp)

    draw(plt, legend = (; order = [:Marker, :Color]))
end

reftest("legend merging manual") do
    N = 20

    x = [1:N; 1:N]
    y = [sin.(range(0, 2pi, length = N)); cos.(range(0, 2pi, length = N)) .+ 2]
    grp = [fill("a", N); fill("b", N)]

    df = (; x, y, grp)

    layers = visual(Lines) + visual(Scatter, markersize = 18) * mapping(marker = :grp)
    plt = data(df) * layers * mapping(:x, :y, color = :grp)

    draw(plt, legend = (; order = [(:Marker, :Color)]))
end

reftest("legend merging manual title override") do
    N = 20

    x = [1:N; 1:N]
    y = [sin.(range(0, 2pi, length = N)); cos.(range(0, 2pi, length = N)) .+ 2]
    grp = [fill("a", N); fill("b", N)]

    df = (; x, y, grp)

    layers = visual(Lines) + visual(Scatter, markersize = 18) * mapping(marker = :grp)
    plt = data(df) * layers * mapping(:x, :y, color = :grp)

    draw(plt, legend = (; order = [(:Marker, :Color) => "merged"]))
end

reftest("contours analysis") do
    volcano = DelimitedFiles.readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

    x = repeat(range(3, 17, length = size(volcano, 1)), size(volcano, 2))
    y = repeat(range(52, 79, length = size(volcano, 2)), inner = size(volcano, 1))
    z = vec(volcano)

    data((; x, y, z)) *
        mapping(:x => "The X", :y, :z, row = :x => (x -> x > 10)) *
        contours(; levels = 10) |> draw(scales(Color = (; colormap = :plasma)))
end

function filled_contours_spec(; contours_kw = (;))
    volcano = DelimitedFiles.readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

    x = repeat(range(3, 17, length = size(volcano, 1)), size(volcano, 2))
    y = repeat(range(52, 79, length = size(volcano, 2)), inner = size(volcano, 1))
    z = vec(volcano)

    return data((; x, y, z)) *
        mapping(:x => "The X", :y, :z, row = :x => >(10)) *
        filled_contours(; bands = 10, contours_kw...)
end

reftest("filled contours analysis") do
    draw(filled_contours_spec(), scales(Color = (; colorbar = false)))
end

reftest("filled contours analysis colorbar") do
    draw(filled_contours_spec(), scales(Color = (; colorbar = true)))
end

reftest("filled contours analysis colorbar levels") do
    draw(filled_contours_spec(; contours_kw = (; bands = nothing, levels = [100, 120, 160, 170, 180, 190])))
end

reftest("filled contours analysis colorbar levels relative false") do
    draw(
        filled_contours_spec(; contours_kw = (; bands = nothing, levels = [100, 120, 160, 170, 180, 190])),
        scales(Color = (; palette = from_continuous(:viridis, relative = false)))
    )
end

reftest("filled contours analysis colorbar levels infinity") do
    draw(filled_contours_spec(; contours_kw = (; bands = nothing, levels = [-Inf, 100, 120, 160, 170, 180, 190, Inf])))
end

reftest("filled contours analysis colorbar levels infinity clipped") do
    draw(
        filled_contours_spec(; contours_kw = (; bands = nothing, levels = [-Inf, 100, 120, 160, 170, 180, 190, Inf])),
        scales(Color = (; palette = clipped(from_continuous(:viridis), low = :red, high = :cyan)))
    )
end

reftest("longpoly con color") do
    N = 5
    _x = [1, 2, 2, 1, 1.25, 1.75, 1.75, 1.25]
    _y = [1, 1, 2, 2, 1.25, 1.25, 1.75, 1.75]

    x = collect(Iterators.flatten([_x .+ k for k in 1:N]))
    y = collect(Iterators.flatten([_y .+ k for k in 1:N]))
    id = repeat(1:N, inner = 8)
    subid = repeat(repeat(1:2, inner = 4), N)
    color = repeat(1:N, inner = 8)
    data((; x, y, id, subid, color)) * mapping(
        :x, :y, :id => verbatim, :subid => verbatim,
        color = :color
    ) *
        visual(AlgebraOfGraphics.LongPoly) |> draw
end

reftest("legend via direct data") do
    data((; x = 1:10)) * mapping(:x, color = direct("A scatter")) |> draw
end

reftest("ablines") do
    data((; intercept = 1:3, slope = [-0.2, 0.1, 0.7])) * mapping(:intercept, :slope) *
        visual(ABLines) |> draw
end

reftest("ablines cat color linestyle") do
    data((; intercept = 1:3, slope = [-0.2, 0.1, 0.7], group = ["A", "B", "C"])) *
        mapping(:intercept, :slope, color = :group, linestyle = :group) *
        visual(ABLines) |> draw
end

reftest("qqplot") do
    data((; x = sin.(1:100), y = sin.((1:100) .+ 0.2))) * mapping(:x, :y) * visual(QQPlot, qqline = :identity) |> draw
end

reftest("arrows cat color") do
    x = repeat(1:10, inner = 10)
    y = repeat(1:10, outer = 10)
    u = cos.(x)
    v = sin.(y)
    c = round.(Bool, sin.(1:100) .* 0.5 .+ 0.5)
    d = round.(Bool, cos.(1:100) .* 0.5 .+ 0.5)
    df = (; x, y, u, v, c, d)
    colors = [colorant"#E24A33", colorant"#348ABD"]
    plt = data(df) *
        mapping(:x, :y, :u, :v) *
        mapping(color = :d => nonnumeric) *
        visual(Arrows2D, lengthscale = 0.4)
    fg = draw(plt, scales(Color = (; palette = colors)))
end

reftest("continuous missings") do
    df = (; x = [1, 2, 3, 4, 5, 6], y = [1, 2, missing, 3, 1, 2], z = [1.0, 2.0, 3.0, 4.0, 5.0, missing])
    dm = data(df) * mapping(:x, :y)
    f = Figure()
    draw!(f[1, 1], dm * mapping(color = :z))
    draw!(f[1, 2], dm * visual(Lines))
    df2 = (; x = [1, 2, 3, 1, 2, 3], y = [1, 1, 1, 2, 2, 2], z = [1, 2, 3, 4, 5, missing])
    draw!(f[2, 1], data(df2) * mapping(:x, :y, :z) * visual(Heatmap))
    f
end

reftest("categorical missings") do
    df = (; x = [1, 2, 3, 4, 5, 6], y = ["A", "B", missing, "C", "A", "B"], z = ["A", "B", "C", "D", "E", missing])
    dm = data(df) * mapping(:x, :y)
    f = Figure()
    draw!(f[1, 1], dm * mapping(color = :z))
    draw!(f[1, 2], dm * visual(Lines))
    df2 = (; x = [1, 2, 3, 1, 2, 3], y = [1, 1, 1, 2, 2, 2], z = ["A", "B", "C", "D", "E", missing])
    fg = draw!(f[2, 1], data(df2) * mapping(:x, :y, :z) * visual(Heatmap))
    legend!(f[2, 2], fg, tellwidth = false)
    f
end

reftest("makie density") do
    x = sin.(1:100) .+ repeat([1, 2], inner = 50)
    group = repeat(["A", "B"], inner = 50)
    spec1 = data((; x, group)) * mapping(:x) * visual(Density)
    spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(Density, strokewidth = 1, strokecolor = :black)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("makie density direction y") do
    x = sin.(1:100) .+ repeat([1, 2], inner = 50)
    group = repeat(["A", "B"], inner = 50)
    spec1 = data((; x, group)) * mapping(:x) * visual(Density, direction = :y)
    spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(Density, direction = :y, strokewidth = 1, strokecolor = :black)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("ecdfplot") do
    x = (1:100) .+ sin.(1:100)
    group = repeat(["A", "B"], inner = 50)
    spec1 = data((; x)) * mapping(:x) * visual(ECDFPlot)
    # attributes for ecdfplot currently don't work in Makie, add back to test when they do
    spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(ECDFPlot)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("hist") do
    x = cos.(range(0, pi / 2, length = 100))
    group = repeat(["A", "B"], inner = 50)
    spec1 = data((; x)) * mapping(:x) * visual(Hist)
    spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(Hist, strokecolor = :black, strokewidth = 1)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("hist direction x") do
    x = cos.(range(0, pi / 2, length = 100))
    group = repeat(["A", "B"], inner = 50)
    spec1 = data((; x)) * mapping(:x) * visual(Hist, direction = :x)
    spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(Hist, direction = :x, strokecolor = :black, strokewidth = 1)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[1, 2], spec2)
    legend!(f[2, 2], fg, orientation = :horizontal)
    f
end

reftest("crossbar") do
    x = 1:5
    y = 6:10
    ylow = 5:9
    yhigh = 6.5:10.5
    group = ["A", "A", "A", "B", "B"]
    df = (; x, y, ylow, yhigh, group)
    spec1 = data(df) * mapping(:x, :y, :ylow, :yhigh) * visual(CrossBar)
    spec2 = data(df) * mapping(:x, :y, :ylow, :yhigh, color = :group) * visual(CrossBar, strokecolor = :black, strokewidth = 1)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("crossbar dodge") do
    x = [1, 2, 3, 1, 2, 3]
    y = 1:6
    ylow = 0:5
    yhigh = 2:7
    dodge = [1, 1, 1, 2, 2, 2]
    df = (; x, y, ylow, yhigh, dodge)
    spec = data(df) * mapping(:x, :y, :ylow, :yhigh, dodge = :dodge => nonnumeric) * visual(CrossBar)
    draw(spec)
end

reftest("crossbar orientation horizontal") do
    x = 1:5
    y = 6:10
    ylow = 5:9
    yhigh = 6.5:10.5
    group = ["A", "A", "A", "B", "B"]
    df = (; x, y, ylow, yhigh, group)
    spec1 = data(df) * mapping(:x, :y, :ylow, :yhigh) * visual(CrossBar, orientation = :horizontal)
    spec2 = data(df) * mapping(:x, :y, :ylow, :yhigh, color = :group) * visual(CrossBar, orientation = :horizontal, strokecolor = :black, strokewidth = 1)
    f = Figure()
    draw!(f[1, 1], spec1)
    fg = draw!(f[2, 1], spec2)
    legend!(f[2, 2], fg)
    f
end

reftest("renamer latexstring rich text") do
    df = (; x = ["a", "b"], y = 1:2)
    rnm = renamer("a" => L"\sum{x + y}", "b" => Makie.rich("Red text", color = :red))
    spec = data(df) * mapping(:x => rnm, :y, color = :x => rnm) * visual(Scatter)
    draw(spec)
end

function presorted_plot(; with_missing::Bool)
    countries = ["Denmark", "Ecuador", "Bolivia", "China", "France", "Algeria"]
    if with_missing
        countries = [c == "Denmark" ? missing : c for c in countries]
    end
    group = ["2", "3", "1", "1", "3", "2"]
    some_value = sort(exp.(sin.(1:6)))

    df = (; countries, group, some_value)

    m1 = mapping(:countries, :some_value, color = :group)
    m2 = mapping(:countries => presorted, :some_value, color = :group)
    m3 = mapping(:countries => presorted, :some_value, color = :group => presorted)

    base = data(df) * visual(BarPlot, direction = :x)

    f = Figure()
    fg1 = draw!(f[1, 1], base * m1)
    fg2 = draw!(f[2, 1], base * m2)
    fg3 = draw!(f[3, 1], base * m3)
    legend!(f[1, 2], fg1)
    legend!(f[2, 2], fg2)
    legend!(f[3, 2], fg3)
    return f
end

reftest("presorted") do
    presorted_plot(; with_missing = false)
end

reftest("presorted with missing") do
    presorted_plot(; with_missing = true)
end

reftest("presorted additional data") do
    df1 = (; name = ["Bob", "Charlie"], value = [27, 13])
    df2 = (; name = ["Alice", "Bob"], value = [15, 30])

    spec = data(df1) * visual(BarPlot)
    spec2 = data(df2) * visual(Scatter)

    f = Figure()
    draw!(f[1, 1], (spec + spec2) * mapping(:name, :value))
    draw!(f[1, 2], (spec + spec2) * mapping(:name => presorted, :value))

    f
end

reftest("presorted wide") do
    df = (; x1 = ["E", "D"], x2 = ["C", "B"], x3 = ["A", "E"], y = [1, 2])
    spec = data(df) * mapping([:x1, :x2, :x3] .=> presorted, :y, color = dims(1)) *
        visual(Scatter, markersize = 20)
    draw(spec)
end

reftest("categorical color from continuous") do
    f = Figure()
    for (i, n) in enumerate([3, 5, 7])
        df = (; x = 1:n, y = 1:n, z = 1:n)
        spec = data(df) * mapping(:x, :y, color = :z => nonnumeric) * visual(Scatter, markersize = 15)
        fg = draw!(f[i, 1], spec, scales(Color = (; palette = from_continuous(:plasma))))
        legend!(f[i, 2], fg, nbanks = 2)
    end
    f
end

reftest("title subtitle footnotes") do
    spec = pregrouped(
        fill(1:5, 6),
        fill(11:15, 6),
        [reshape(sin.(1:25), 5, 5) .+ i for i in 1:6],
        layout = 1:6 => nonnumeric
    ) * visual(Heatmap)

    draw(
        spec;
        figure = (;
            title = "Numbers in square configuration",
            subtitle = "Arbitrary data exhibits sinusoidal properties",
            footnotes = [
                rich(superscript("1"), "First footnote"),
                rich(superscript("2"), "Second ", rich("footnote", color = :red)),
            ],
        ),
        axis = (; width = 100, height = 100)
    )
end

reftest("title subtitle footnotes single unconstrained facet") do
    spec = data((; x = 1:10, y = 11:20)) * mapping(:x, :y) * visual(Scatter)
    draw(
        spec;
        figure = (;
            title = "Some title",
            subtitle = "Some subtitle",
            footnotes = [
                rich(superscript("1"), "First footnote"),
                rich(superscript("2"), "Second ", rich("footnote", color = :red)),
            ],
        ),
    )
end

reftest("title") do
    spec = pregrouped(
        fill(1:5, 6),
        fill(11:15, 6),
        [reshape(sin.(1:25), 5, 5) .+ i for i in 1:6],
        layout = 1:6 => nonnumeric
    ) * visual(Heatmap)

    draw(
        spec;
        figure = (;
            title = "Numbers in square configuration",
        ),
        axis = (; width = 100, height = 100)
    )
end

reftest("title subtitle footnotes settings") do
    spec = pregrouped(
        fill(1:5, 6),
        fill(11:15, 6),
        [reshape(sin.(1:25), 5, 5) .+ i for i in 1:6],
        layout = 1:6 => nonnumeric
    ) * visual(Heatmap)

    draw(
        spec;
        figure = (;
            title = "Numbers in square configuration",
            titlefont = :italic,
            titlesize = 20,
            titlecolor = :orange,
            subtitle = "Arbitrary data exhibits sinusoidal properties",
            subtitlefont = :bold_italic,
            subtitlesize = 10,
            subtitlecolor = :brown,
            titlealign = :right,
            footnotes = [
                rich(superscript("1"), "First footnote"),
                rich(superscript("2"), "Second ", rich("footnote", color = :red)),
            ],
            footnotefont = :bold,
            footnotecolor = :blue,
            footnotesize = 20,
            footnotealign = :right,
        ),
        axis = (; width = 100, height = 100)
    )

end

reftest("title subtitle footnotes fontsize inherit") do
    spec = pregrouped(
        fill(1:5, 6),
        fill(11:15, 6),
        [reshape(sin.(1:25), 5, 5) .+ i for i in 1:6],
        layout = 1:6 => nonnumeric
    ) * visual(Heatmap)

    draw(
        spec;
        figure = (;
            fontsize = 20,
            title = "Numbers in square configuration",
            subtitle = "Arbitrary data exhibits sinusoidal properties",
            footnotes = [
                rich(superscript("1"), "First footnote"),
                rich(superscript("2"), "Second ", rich("footnote", color = :red)),
            ],
        ),
        axis = (; width = 100, height = 100)
    )
end

reftest("dodge barplot with errorbars") do
    f = Figure()
    df = (
        x = [1, 1, 2, 2],
        y = [1, 2, 5, 6],
        err = [0.5, 0.4, 0.7, 0.6],
        group = ["A", "B", "A", "C"],
    )

    function spec(; kwargs...)
        xdir = get(kwargs, :direction, :y) == :x
        dodge_map = xdir ? mapping(dodge_y = :group) : mapping(dodge_x = :group)
        return data(df) * (
            mapping(:x, :y, dodge = :group, color = :group) * visual(BarPlot; kwargs...) +
                mapping(xdir ? :y : :x, xdir ? :x : :y, :err) * dodge_map * visual(Errorbars; direction = xdir ? :x : :y)
        )
    end

    draw!(f[1, 1], spec())
    draw!(f[1, 2], spec(; width = 0.7, dodge_gap = 0.2))
    draw!(f[2, 1], spec(; direction = :x))
    draw!(f[2, 2], spec(; direction = :x, width = 0.7, gap = 0.3, dodge_gap = 0.2))
    f
end

reftest("dodge barplot with errorbars 5") do
    f = Figure(size = (800, 800))
    df = (
        x = repeat(1:2, inner = 5),
        y = 1:10,
        err = repeat([0.5, 0.4, 0.7, 0.6, 0.4], 2),
        group = repeat(["A", "B", "C", "D", "E"], 2),
    )

    function spec(; kwargs...)
        xdir = get(kwargs, :direction, :y) == :x
        dodge_map = xdir ? mapping(dodge_y = :group) : mapping(dodge_x = :group)
        return data(df) * (
            mapping(:x, :y, dodge = :group, color = :group) * visual(BarPlot; kwargs...) +
                mapping(xdir ? :y : :x, xdir ? :x : :y, :err) * dodge_map * visual(Errorbars; direction = xdir ? :x : :y)
        )
    end

    draw!(f[1, 1], spec())
    draw!(f[1, 2], spec(; width = 0.7, dodge_gap = 0.1))
    draw!(f[2, 1], spec(; direction = :x))
    draw!(f[2, 2], spec(; direction = :x, width = 0.7, gap = 0.3, dodge_gap = 0.1))
    f
end

reftest("dodge scatter with rangebars") do
    df = (
        x = repeat(1:10, inner = 2),
        y = cos.(range(0, 2pi, length = 20)),
        ylow = cos.(range(0, 2pi, length = 20)) .- 0.2,
        yhigh = cos.(range(0, 2pi, length = 20)) .+ 0.3,
        dodge = repeat(["A", "B"], 10),
    )

    f = Figure()
    spec1 = data(df) * (mapping(:x, :y, dodge_x = :dodge, color = :dodge) * visual(Scatter) + mapping(:x, :ylow, :yhigh, dodge_x = :dodge, color = :dodge) * visual(Rangebars))
    spec2 = data(df) * (mapping(:y, :x, dodge_y = :dodge, color = :dodge) * visual(Scatter) + mapping(:x, :ylow, :yhigh, dodge_y = :dodge, color = :dodge) * visual(Rangebars, direction = :x))
    draw!(f[1, 1], spec1, scales(DodgeX = (; width = 0.5)))
    draw!(f[1, 2], spec2, scales(DodgeY = (; width = 0.5)))
    draw!(f[2, 1], spec1, scales(DodgeX = (; width = 1.0)))
    draw!(f[2, 2], spec2, scales(DodgeY = (; width = 1.0)))
    f
end

reftest("manual legend labels in visual") do
    df_subjects = (; x = repeat(1:10, 10), y = cos.(1:100), id = repeat(1:10, inner = 10))
    df_func = (; x = range(1, 10, length = 20), y = cos.(range(1, 10, length = 20)))

    spec1 = data(df_subjects) * mapping(:x, :y, group = :id => nonnumeric) * visual(Lines, linestyle = :dash, color = (:black, 0.2), label = "Subject data")
    spec2 = data(df_func) * mapping(:x, :y) * (visual(Lines, color = :tomato) + visual(Scatter, markersize = 12, color = :tomato, strokewidth = 2)) * visual(label = L"\cos(x)")

    draw(spec1 + spec2)
end

reftest("manual legend order") do
    df = (; x = repeat(1:10, 3), y = cos.(1:30), group = repeat(["A", "B", "C"], inner = 10))
    spec1 = data(df) * mapping(:x, :y, color = :group) * visual(Lines)

    spec2 = data((; x = 1:10, y = cos.(1:10) .+ 2)) * mapping(:x, :y) * visual(Scatter, color = :purple, label = "Scatter")

    f = Figure()
    fg = draw!(f[1, 1], spec1 + spec2)
    legend!(f[1, 2], fg)
    legend!(f[1, 3], fg, order = [:Label, :Color])
    @test_throws ErrorException legend!(f[1, 4], fg, order = [:Color])
    @test_throws ErrorException legend!(f[1, 4], fg, order = [:Label])
    f
end

reftest("scatterlines legend") do
    spec1 = data((; x = 1:10, y = cos.(1:10))) * mapping(:x, :y) * visual(ScatterLines, color = :red, label = "markercolor auto")
    spec2 = data((; x = 1:10, y = cos.(1:10) .+ 2)) * mapping(:x, :y) * visual(ScatterLines, color = :blue, markercolor = :cyan, label = "markercolor cyan")
    draw(spec1 + spec2)
end

reftest("legend element overrides") do
    spec = mapping(1:10, 1:10, color = repeat(["A", "B"], inner = 5)) *
        visual(Scatter, legend = (; markersize = 30))
    draw(spec)
end

reftest("stairs") do
    spec = mapping(
        1:10,
        [1, 4, 3, 7, 5, 3, 2, 4, 3, 7],
        color = repeat(["A", "B"], inner = 5),
        linestyle = repeat(["A", "B"], inner = 5),
    ) *
        visual(Stairs)
    draw(spec)
end

reftest("split x scales across facet layout") do
    dat = data(
        (;
            cat1 = ["Apple", "Orange", "Pear"],
            cat2 = ["Blue", "Green", "Red"],
            cat3 = ["Heavy", "Light", "Medium"],
            cont = [4.5, 7.6, 9.3],
            y1 = [3.4, 5.2, 6],
            y2 = [0.3, 0.2, 0.3],
            y3 = [123, 82, 71],
            y4 = [-10, 10, 0.4],
        )
    )

    cat_mappings = mapping(:cat1 => scale(:X1), :y1, layout = direct("A")) +
        mapping(:cat2 => "Cat 2" => scale(:X2), :y2, layout = direct("B")) +
        mapping(:cat3 => scale(:X3), :y3, layout = direct("C"))

    cont_mapping = mapping(:cont => scale(:X4), :y4, layout = direct("D"))

    spec = dat * (cat_mappings * visual(Scatter) + cont_mapping * visual(Lines))

    draw(spec, scales(X3 = (; label = "Third Categorical")))
end

reftest("split x and y scales row col layout") do
    dat = data(
        (;
            cat1 = ["Apple", "Orange", "Pear"],
            cont2 = [1.4, 5.1, 2.5],
            cat3 = ["Heavy", "Light", "Medium"],
            cont4 = [2.5, -0.2, 1.2],
        )
    )

    mappings = zerolayer()
    for x in [:cat1, :cont2]
        for y in [:cat3, :cont4]
            mappings += mapping(x => scale(x), y => scale(y), col = direct("$x"), row = direct("$y"))
        end
    end

    spec = dat * mappings * visual(Scatter)

    draw(spec)
end

reftest("hide row col and layout labels") do
    f = Figure(size = (600, 600))
    d = data(
        (;
            x = 1:16,
            y = 17:32,
            group1 = repeat(["A", "B"], inner = 8),
            group2 = repeat(["C", "D"], 8),
        )
    )
    spec1 = d * mapping(:x, :y, row = :group1, col = :group2) * visual(Scatter)
    spec2 = d * mapping(:x, :y, layout = (:group1, :group2) => tuple) * visual(Scatter)

    draw!(f[1, 1], spec1, scales(Row = (; show_labels = false), Col = (; show_labels = false)))
    draw!(f[1, 2], spec1, scales(Row = (; show_labels = true), Col = (; show_labels = true)))
    draw!(f[2, 1], spec2, scales(Layout = (; show_labels = false)))
    draw!(f[2, 2], spec2, scales(Layout = (; show_labels = true)))
    f
end

reftest("hide row col and layout labels legendkw") do
    f = Figure(size = (600, 600))
    d = data(
        (;
            x = 1:16,
            y = 17:32,
            group1 = repeat(["A", "B"], inner = 8),
            group2 = repeat(["C", "D"], 8),
        )
    )
    spec1 = d * mapping(:x, :y, row = :group1, col = :group2) * visual(Scatter)
    spec2 = d * mapping(:x, :y, layout = (:group1, :group2) => tuple) * visual(Scatter)

    draw!(f[1, 1], spec1, scales(Row = (; legend = false), Col = (; legend = false)))
    draw!(f[1, 2], spec1, scales(Row = (; legend = true), Col = (; legend = true)))
    draw!(f[2, 1], spec2, scales(Layout = (; legend = false)))
    draw!(f[2, 2], spec2, scales(Layout = (; legend = true)))
    f
end

let
    df = (;
        x = 0:24,
        y = 0:24,
        color = repeat(string.('A':'E'), inner = 5),
    )

    spec = data(df) * mapping(:x, :y, layout = :color, color = :color)

    scl = scales(Layout = (; categories = cats -> reverse(uppercase.(cats))))

    reftest("pagination layout unpaginated") do
        draw(spec, scl)
    end

    paginated = AlgebraOfGraphics.paginate(spec, scl; layout = 3)
    for i in 1:length(paginated)
        reftest("pagination layout page $i") do
            draw(paginated, i)
        end
    end

    paginated_2 = AlgebraOfGraphics.paginate(
        spec,
        scales(Layout = (; categories = cats -> reverse(cats) .=> ["Eee", "Ddd", "Ccc", "Bbb", "Aaa"]));
        layout = 3
    )

    for i in 1:length(paginated_2)
        reftest("pagination category labels layout page $i") do
            draw(paginated_2, i)
        end
    end
end

let
    df = (;
        x = 0:24,
        y = 0:24,
        group1 = repeat(string.('a':'e'), inner = 5),
        group2 = repeat(string.('f':'j'), 5),
    )

    spec = data(df) * mapping(:x, :y, row = :group2, col = :group1, color = :group1)

    scl = scales(;
        Col = (; palette = ["a" => 1, 3, 5, 2, 4], categories = reverse),
        Row = (; palette = ["g" => 1, 3, 5, 2, 4], categories = cats -> cats .=> uppercase.(cats)),
    )

    reftest("pagination row col unpaginated") do
        draw(spec, scl)
    end

    paginated = AlgebraOfGraphics.paginate(spec, scl; row = 3, col = 2)
    for i in 1:length(paginated)
        reftest("pagination row col page $i") do
            draw(paginated, i)
        end
    end
end

let
    df = (;
        wres = 1:10,
        age = 11:20,
        gender = repeat(["m", "f"], 5),
    )

    layer1 = mapping(:age => scale(:Xage), :wres, layout = direct("A")) * visual(Scatter)
    layer2 = mapping(:gender => scale(:Xgender), :wres, layout = direct("B")) * visual(Violin)

    spec = data(df) * (layer1 + layer2)

    reftest("pagination split x scales unpaginated") do
        draw(spec)
    end

    paginated = AlgebraOfGraphics.paginate(spec; layout = 1)
    for i in 1:length(paginated)
        reftest("pagination split x scales page $i") do
            draw(paginated, i)
        end
    end
end

let
    df = (
        x = repeat(1:10, 36),
        y = cumsum(sin.(range(0, 10pi, length = 360))),
        group = repeat(string.("Group ", 1:36), inner = 10),
        color = 1:360,
    )
    spec = data(df) * mapping(:x, :y, color = :color, layout = :group) * visual(Lines)
    scl = scales(Color = (; colormap = :plasma, label = "The color"))

    reftest("pagination colorbar unpaginated") do
        draw(spec, scl)
    end

    pag = paginate(spec, scl, layout = 9)
    for page in [1, 4]
        reftest("pagination colorbar page $page") do
            draw(pag, page)
        end
    end
end

if VERSION >= v"1.9"
    df_u = (
        time = (1:24) .* U.u"hr",
        size = range(0, 20, length = 24) .* U.u"cm",
        weight = range(0, 70, length = 24) .* U.u"g",
    )
    df_d = (
        time = (1:24) .* D.us"hr",
        size = range(0, 20, length = 24) .* D.us"cm",
        weight = range(0, 70, length = 24) .* D.us"g",
    )

    reftest("units basic", true) do
        spec = mapping(:time, :size, color = :weight, markersize = :weight)
        f = Figure()
        fg_u = draw!(f[1, 1], spec * data(df_u))
        colorbar!(f[1, 2], fg_u)
        legend!(f[1, 3], fg_u)
        fg_d = draw!(f[2, 1], spec * data(df_d))
        colorbar!(f[2, 2], fg_d)
        legend!(f[2, 3], fg_d)
        f
    end

    reftest("units scale override", true) do
        spec = mapping(:time, :size, color = :weight, markersize = :weight)
        f = Figure()
        fg_u = draw!(
            f[1, 1],
            spec * data(df_u),
            scales(
                X = (; unit = U.u"wk"),
                Y = (; unit = U.u"m"),
                Color = (; unit = U.u"kg"),
                MarkerSize = (; unit = U.u"mg")
            )
        )
        colorbar!(f[1, 2], fg_u)
        legend!(f[1, 3], fg_u)
        fg_d = draw!(
            f[2, 1],
            spec * data(df_d),
            scales(
                X = (; unit = D.us"wk"),
                Y = (; unit = D.us"m"),
                Color = (; unit = D.us"kg"),
                MarkerSize = (; unit = D.us"mg")
            )
        )
        colorbar!(f[2, 2], fg_d)
        legend!(f[2, 3], fg_d)
        f
    end

    reftest("units alignment errorbars") do
        f = Figure()
        base_u = data((; id = 1:3, value = [1, 2, 3] .* U.u"m", err = [10, 50, 100] .* U.u"cm"))
        spec_u = base_u * mapping(:id, :value, :err) * visual(Errorbars)
        draw!(f[1, 1], spec_u)
        spec_u2 = base_u * mapping(:value, :id, :err) * visual(Errorbars, direction = :x)
        draw!(f[1, 2], spec_u2, scales(X = (; unit = U.u"cm")))

        base_d = data((; id = 1:3, value = [1, 2, 3] .* D.us"m", err = [10, 50, 100] .* D.us"cm"))
        spec_d = base_d * mapping(:id, :value, :err) * visual(Errorbars)
        draw!(f[2, 1], spec_d)
        spec_d2 = base_d * mapping(:value, :id, :err) * visual(Errorbars, direction = :x)
        draw!(f[2, 2], spec_d2, scales(X = (; unit = D.us"cm")))

        f
    end

    reftest("units wide labels") do
        _df = (; group = repeat(["A", "B"], inner = 50), apples = (1:100) .* U.u"s", bananas = (101:200) .* 1000 .* U.u"ms")
        spec_wide = data(_df) *
            mapping(:group, [:apples, :bananas], layout = dims(1)) *
            visual(Violin)

        draw(spec_wide)
    end
end

reftest("hidden axis labels col row") do
    f = Figure()
    colspec = data((; x = 1:2, y = 1:2, group = string.('A':'B'))) *
        mapping(:x, :y, col = :group)
    draw!(f[1, 1], colspec, facet = (; linkyaxes = false))
    rowspec = data((; x = 1:2, y = 1:2, group = string.('A':'B'))) *
        mapping(:x, :y, row = :group)
    draw!(f[1, 2], rowspec, facet = (; linkxaxes = false))
    f
end

reftest("singular color and markersize limits", true) do
    f = Figure(size = (500, 600))
    fg = draw!(f[1, 1], pregrouped([1:3], [1:2], [ones(3, 2)]) * visual(Heatmap))
    colorbar!(f[1, 2], fg)
    fg2 = draw!(f[2, 1], pregrouped([1:3], [1:2], [zeros(3, 2)]) * visual(Heatmap))
    colorbar!(f[2, 2], fg2)
    fg3 = draw!(f[3, 1], pregrouped([1:3], [1:2], [-2 .* ones(3, 2)]) * visual(Heatmap))
    colorbar!(f[3, 2], fg3)
    fg4 = draw!(f[1, 3], mapping(1:5, 1:5, markersize = ones(5)) * visual(Scatter))
    legend!(f[1, 4], fg4)
    fg5 = draw!(f[2, 3], mapping(1:5, 1:5, markersize = zeros(5)) * visual(Scatter))
    legend!(f[2, 4], fg5)
    fg6 = draw!(f[3, 3], mapping(1:5, 1:5, markersize = -2 .* ones(5)) * visual(Scatter))
    legend!(f[3, 4], fg6)
    f
end

reftest("hspan and vspan") do
    f = Figure()
    spec = mapping([0, 1, 2, 4, 8], [0.25, 1.5, 3, 6, 12], color = 'A':'E')
    fg1 = draw!(f[1, 1], spec * visual(HSpan))
    legend!(f[1, 2], fg1)
    fg2 = draw!(f[2, 1], spec * visual(VSpan))
    legend!(f[2, 2], fg2)
    f
end

# reftest("rainclouds") do
# TODO: randomness in scatters makes diff-testing impossible
@test_nowarn begin
    groups = repeat(1:3, inner = 300)
    values = sin.(1:900) .* groups
    spec = mapping(
        groups => "Group",
        values => "Value",
        color = groups => nonnumeric
    ) * visual(RainClouds)

    f = Figure()
    fg1 = draw!(f[1, 1], spec)
    legend!(f[1, 2], fg1)
    fg2 = draw!(f[2, 1], spec * visual(orientation = :horizontal))
    legend!(f[2, 2], fg2)
    f
end

reftest("annotation") do
    f = Figure(size = (600, 450))
    text = string.(range('A', length = 5)) => verbatim
    spec1 = mapping(1:5, 1:5) *
        (
        visual(Annotation) * mapping(; text) +
            visual(Scatter)
    )
    draw!(f[1, 1], spec1)
    spec2 = mapping(1:5, 1:5, color = 1:5) *
        (
        visual(Annotation) * mapping(; text) +
            visual(Scatter)
    )
    draw!(f[1, 2], spec2)
    spec3 = mapping(1:5, 1:5, color = 1:5 => nonnumeric) *
        (
        visual(Annotation) * mapping(; text) +
            visual(Scatter)
    )
    fg = draw!(f[2, 1][1, 1], spec3)
    legend!(f[2, 1][1, 2], fg)
    spec4 = mapping(
        [30, 15, 0],
        [100, 50, 30],
        1:3,
        1:3;
        text = ["A", "B", "C"] => verbatim,
    ) * visual(Annotation) +
        mapping(1:5, 1:5) * visual(Scatter) +
        mapping(50, -50, 3, 3, text = "point" => verbatim) *
        visual(Annotation, style = Ann.Styles.LineArrow(), path = Ann.Paths.Arc(height = -0.3)) +
        mapping(
        [4, 4.5],
        [3, 4],
        4:5,
        4:5;
        text = ["D", "E"] => verbatim,
    ) * visual(Annotation; labelspace = :data)
    draw!(f[2, 2], spec4)
    f
end

reftest("textlabel") do
    f = Figure()
    s1 = mapping(1:5, fill(0, 5), text = string.(range('A', length = 5)) => verbatim, background_color = ["X", "X", "X", "Y", "Y"]) *
        visual(TextLabel)
    fg1 = draw!(f[1, 1], s1)
    legend!(f[1, 2], fg1)
    s2 = mapping(1:5, fill(0, 5), text = string.(range('A', length = 5)) => verbatim, text_color = ["X", "X", "X", "Y", "Y"]) *
        visual(TextLabel)
    fg2 = draw!(f[2, 1], s2)
    legend!(f[2, 2], fg2)
    f
end

reftest("scales ticks tickformats") do
    specs = data(
        (;
            x = 1:10,
            ylin = range(-50, 50, length = 10),
            yexp = exp.(-(1:10)),
        )
    ) *
        (
        mapping(
            :x,
            :ylin => "y" => scale(:a),
            layout = direct("a")
        ) + mapping(
            :x => x -> x + 3,
            :yexp => "y" => scale(:b),
            layout = direct("b")
        )
    ) * visual(Scatter)

    draw(
        specs,
        scales(
            a = (; scale = Makie.pseudolog10, ticks = [-50, -30, -20, -10, 0, 10, 20, 30, 50]),
            b = (; scale = log10, tickformat = "{:.4f}mg"),
            X = (; scale = log2),
        )
    )
end

function specfigure()
    df = Observable{Any}(
        (;
            x = 1:100, y = 101:200, color = 1:100, marker = repeat('A':'B', 50), layout = repeat('A':'E', 20),
        )
    )
    colormap = Observable(:viridis)

    specobs = lift(df, colormap) do df, colormap
        layer = data(df) * mapping(:x, :y, color = :color, marker = :marker, layout = :layout) *
            visual(Scatter)
        AlgebraOfGraphics.draw_to_spec(layer, scales(Color = (; colormap)))
    end

    f = Figure()
    plot(f[1, 1], specobs)

    return f, df, colormap
end

reftest("draw_to_spec") do
    f, df, colormap = specfigure()
    f
end

reftest("draw_to_spec update") do
    f, df, colormap = specfigure()
    df[] = (; x = 5:104, y = 111:210, color = 11:110, marker = repeat('C':'D', 50), layout = repeat('F':'I', 25))
    colormap[] = :plasma
    f
end

reftest("empty facets with non-layout layer") do
    f = Figure()
    layer1 = mapping(1:3, 1:3, layout = 1:3) * visual(Scatter, markersize = 20) +
        mapping(1.5) * visual(HLines, linewidth = 4)
    layer2 = mapping(1:2, 1:2, row = 1:2, col = 1:2) * visual(Scatter, markersize = 20) +
        mapping(1.5) * visual(HLines, linewidth = 4)
    draw!(f[1, 1], layer1)
    draw!(f[1, 2], layer2)
    f
end

reftest("all-missing groups") do
    df1 = (;
        a = [1, 2, 3],
        b = Union{Float64, Missing}[missing, missing, missing],
    )
    df2 = (;
        a = [1, 2, 3, 4],
        b = [missing, missing, 3, 4],
        c = ["A", "A", "B", "B"],
    )
    # this one will fall back to categorical
    spec1 = data(df1) * mapping(:a, :b) * visual(Scatter)
    # but this one used to error and now doesn't
    spec2 = data(df2) * mapping(:a, :b, layout = :c) * visual(Scatter)

    f = Figure()
    draw!(f[1, 1], spec1)
    draw!(f[1, 2], spec2)
    f
end

reftest("aggregate mean over x values") do
    # Three groups with different numbers of points (4, 5, 6) and mean line going up and down
    df = (;
        x = [
            1, 1, 1, 1,  # 4 points at x=1
            2, 2, 2, 2, 2,  # 5 points at x=2
            3, 3, 3, 3, 3, 3  # 6 points at x=3
        ],
        y = [
            2.0, 2.2, 1.8, 2.0,  # mean = 2.0
            4.8, 5.0, 5.2, 4.9, 5.1,  # mean = 5.0
            2.7, 3.0, 3.3, 2.8, 3.2, 3.0  # mean = 3.0
        ]
    )
    layer_raw = data(df) * mapping(:x, :y) * visual(Scatter, color = :gray)
    layer_mean = data(df) * mapping(:x, :y) * aggregate(:, mean) * visual(Lines, color = :red, linewidth = 3)
    draw(layer_raw + layer_mean)
end

reftest("aggregate mean with layout faceting") do
    # Two groups (A and B) with different linear relationships
    df = (;
        x = [
            1, 1, 1, 2, 2, 2, 3, 3, 3,  # Group A x values
            1, 1, 1, 2, 2, 2, 3, 3, 3   # Group B x values
        ],
        y = [
            1.8, 2.0, 2.2, 3.8, 4.0, 4.2, 5.7, 6.0, 6.3,  # Group A: y ≈ 2x (means: 2.0, 4.0, 6.0)
            2.7, 3.0, 3.3, 5.7, 6.0, 6.3, 8.7, 9.0, 9.3   # Group B: y ≈ 3x (means: 3.0, 6.0, 9.0)
        ],
        group = [
            "A", "A", "A", "A", "A", "A", "A", "A", "A",
            "B", "B", "B", "B", "B", "B", "B", "B", "B"
        ]
    )
    layer_raw = data(df) * mapping(:x, :y, layout = :group) * visual(Scatter, color = :gray)
    layer_mean = data(df) * mapping(:x, :y, layout = :group) * aggregate(:, mean) * visual(Lines, color = :red, linewidth = 3)
    draw(layer_raw + layer_mean)
end

reftest("aggregate mean of x over y values") do
    # Aggregate x values for each y group (horizontal aggregation) with zig-zag pattern
    df = (;
        y = [
            1, 1, 1, 1,  # 4 points at y=1
            2, 2, 2, 2, 2,  # 5 points at y=2
            3, 3, 3, 3, 3, 3  # 6 points at y=3
        ],
        x = [
            1.8, 2.0, 2.2, 2.0,  # mean = 2.0
            4.8, 5.0, 5.2, 4.9, 5.1,  # mean = 5.0
            2.7, 3.0, 3.3, 2.8, 3.2, 3.0  # mean = 3.0
        ]
    )
    layer_raw = data(df) * mapping(:x, :y) * visual(Scatter, color = :gray)
    layer_mean = data(df) * mapping(:x, :y) * aggregate(mean, :) * visual(Lines, color = :red, linewidth = 3)
    draw(layer_raw + layer_mean)
end

reftest("aggregate mean with color aggregation") do
    # Groups with different sizes (zig-zag pattern), color shows group size via length aggregation
    df = (;
        x = [
            1, 1, 1, 1,  # 4 points at x=1
            2, 2, 2, 2, 2,  # 5 points at x=2
            3, 3, 3, 3, 3, 3  # 6 points at x=3
        ],
        y = [
            1.8, 2.0, 2.2, 2.0,  # mean = 2.0
            4.8, 5.0, 5.2, 4.9, 5.1,  # mean = 5.0
            2.7, 3.0, 3.3, 2.8, 3.2, 3.0  # mean = 3.0
        ],
        color = [
            0.8, 1.0, 1.2, 1.0,  # mean = 1.0
            1.8, 2.0, 2.2, 1.9, 2.1,  # mean = 2.0
            2.7, 3.0, 3.3, 2.8, 3.2, 3.0  # mean = 3.0
        ]
    )
    layer_raw = data(df) * mapping(:x, :y) * visual(Scatter, color = :gray)
    layer_agg = data(df) * mapping(:x, :y, color = :color) * 
        aggregate(:, mean, color = length) * 
        visual(Scatter, markersize = 20, marker = :diamond, colormap = :viridis)
    draw(layer_raw + layer_agg)
end

reftest("aggregate mean with missing values") do
    # One group has a missing value - mean should return missing for that group
    df = (;
        x = [
            1, 1, 1, 1,  # 4 points at x=1
            2, 2, 2, 2, 2,  # 5 points at x=2, one will be missing
            3, 3, 3, 3, 3, 3  # 6 points at x=3
        ],
        y = [
            1.8, 2.0, 2.2, 2.0,  # mean = 2.0
            4.8, missing, 5.2, 4.9, 5.1,  # mean = missing (because one value is missing)
            2.7, 3.0, 3.3, 2.8, 3.2, 3.0  # mean = 3.0
        ]
    )
    layer_raw = data(df) * mapping(:x, :y) * visual(Scatter, color = :gray)
    layer_mean = data(df) * mapping(:x, :y) * aggregate(:, mean) * visual(Scatter, color = :blue, markersize = 20)
    draw(layer_raw + layer_mean)
end

reftest("aggregate sum heatmap 2d") do
    # 2x3 heatmap with one combination missing (x=2, y=2) to show gap
    df = (;
        x = [
            1, 1, 1,  # (1,1): sum = 6.0
            1, 1,  # (1,2): sum = 5.0
            1, 1, 1,  # (1,3): sum = 9.0
            2, 2,  # (2,1): sum = 7.0
            # (2,2): missing - no data points
            2, 2, 2, 2  # (2,3): sum = 12.0
        ],
        y = [
            1, 1, 1,
            2, 2,
            3, 3, 3,
            1, 1,
            3, 3, 3, 3
        ],
        z = [
            2.0, 2.0, 2.0,  # sum = 6.0
            2.5, 2.5,  # sum = 5.0
            3.0, 3.0, 3.0,  # sum = 9.0
            3.0, 4.0,  # sum = 7.0
            3.0, 3.0, 3.0, 3.0  # sum = 12.0
        ]
    )
    data(df) * mapping(:x, :y, :z) * aggregate(:, :, sum) * visual(Heatmap) |> draw
end

reftest("aggregate extrema rangebars") do
    # Extrema split into min and max for range bars with zig-zag pattern
    df = (;
        x = [
            1, 1, 1, 1,  # 4 points at x=1
            2, 2, 2, 2, 2,  # 5 points at x=2
            3, 3, 3, 3, 3, 3  # 6 points at x=3
        ],
        y = [
            1.5, 2.0, 2.5, 2.2,  # min = 1.5, max = 2.5
            4.3, 5.0, 5.7, 4.8, 5.2,  # min = 4.3, max = 5.7
            2.0, 3.0, 4.0, 2.5, 3.5, 3.2  # min = 2.0, max = 4.0
        ]
    )
    layer_raw = data(df) * mapping(:x, :y) * visual(Scatter, color = :gray)
    layer_range = data(df) * mapping(:x, :y) * 
        aggregate(:, extrema => [first => 2, last => 3]) * 
        visual(Rangebars, color = :red, linewidth = 3)
    draw(layer_raw + layer_range)
end

reftest("aggregate sum heatmap custom scale and label") do
    df = (;
        x = [
            1, 1, 1,  # (1,1): sum = 6.0
            1, 1,  # (1,2): sum = 5.0
            1, 1, 1,  # (1,3): sum = 9.0
            2, 2,  # (2,1): sum = 7.0
            # (2,2): missing - no data points
            2, 2, 2, 2  # (2,3): sum = 12.0
        ],
        y = [
            1, 1, 1,
            2, 2,
            3, 3, 3,
            1, 1,
            3, 3, 3, 3
        ],
        z = [
            2.0, 2.0, 2.0,  # sum = 6.0
            2.5, 2.5,  # sum = 5.0
            3.0, 3.0, 3.0,  # sum = 9.0
            3.0, 4.0,  # sum = 7.0
            3.0, 3.0, 3.0, 3.0  # sum = 12.0
        ]
    )
    layer = data(df) * mapping(:x, :y, :z) * 
        aggregate(:, :, sum => rich("total ", rich("of z", font = :bold)) => scale(:color2)) * 
        visual(Heatmap)
    draw(layer, scales(color2 = (; colormap = :Blues)))
end
