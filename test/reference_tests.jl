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
        (mapping(:x1, :y, color = :z1) * visual(Scatter, markersize = 20, colormap = :plasma) +
        mapping(:x2, :y, color = :z2) * visual(Scatter, markersize = 20)) |>
        draw(scales(Color = (; colormap = :viridis, colorrange = (2, 7), lowclip = :red, highclip = :cyan)))
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

reftest("violin cat color") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = ["U", "V", "W", "X"])) * mapping(:x, :y; color = :z) * visual(Violin) |> draw
end

reftest("violin cat color horizontal") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = ["U", "V", "W", "X"])) * mapping(:x, :y; color = :z) * visual(Violin, orientation = :horizontal) |> draw
end

reftest("violin cat color side") do
    data((; x = 1:4, y = ["A", "B", "C", "D"], z = ["U", "V", "W", "X"], q = ["A", "A", "B", "B"])) * mapping(:x, :y; color = :z, side = :q) * visual(Violin) |> draw
end

reftest("hlines cat color") do
    data((; y = 1:4, q = ["A", "A", "B", "B"])) * mapping(:y, color = :q) * visual(HLines) |> draw
end

reftest("vlines cat color") do
    data((; x = 1:4, q = ["A", "A", "B", "B"])) * mapping(:x, color = :q) * visual(VLines) |> draw
end

reftest("second scale barplot hlines") do
    data((; x1 = 1:4, x2 = 5:8, y = ["A", "B", "C", "D"], z1 = ["X", "X", "Y", "Y"], z2 = ["Q", "Q", "U", "U"])) *
        (mapping(:x1, :y, color = :z1) * visual(BarPlot) +
        mapping(:y, color = :z2 => scale(:second)) * visual(HLines)) |>
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
    data((; x = 1:4, y = 1:4, err = 2:5)) * mapping(:x, :y, :err) *
        visual(Errorbars) |> draw
end

reftest("errorbars direction x") do
    data((; x = 1:4, y = 1:4, err = 2:5)) * mapping(:x, :y, :err) *
        visual(Errorbars; direction = :x) |> draw
end

reftest("errorbars cat color direction x") do
    data((; x = 1:4, y = 1:4, err = 2:5, z = 1:4)) * mapping(:x, :y, :err, color = :z => nonnumeric) *
        visual(Errorbars; direction = :x) |> draw
end

reftest("errorbars cat color") do
    data((; x = 1:4, y = 1:4, err = 2:5, z = 1:4)) * mapping(:x, :y, :err, color = :z => nonnumeric) *
        visual(Errorbars) |> draw
end

reftest("errorbars low high") do
    data((; x = 1:4, y = 1:4, errlow = [0.1, 0.2, 0.3, 0.4], errhigh = [0.4, 0.2, 0.3, 0.1])) * mapping(:x, :y, :errlow, :errhigh) *
        visual(Errorbars) |> draw
end

reftest("histogram cat color") do
    df = (x=[sin.(1:500); sin.(1:500) .* 2], z=repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, layout=:z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram dodge") do
    df = (x=[sin.(1:500); sin.(1:500) .* 2], z=repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, dodge=:z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram dodge direction x") do
    df = (x=[sin.(1:500); sin.(1:500) .* 2], z=repeat(["a", "b"], inner = 500))
    specs = data(df) * mapping(:x, dodge=:z, color = :z) * histogram() * visual(direction = :x)
    draw(specs)
end

reftest("histogram stack") do
    df = (x=[sin.(1:500); sin.(1:500) .* 2], z=repeat(["b", "a"], inner = 500))
    specs = data(df) * mapping(:x, stack=:z, color = :z) * histogram()
    draw(specs)
end

reftest("histogram 2d") do
    df = (x=sin.(1:300), y=cos.(1:300))
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
        mapping(:x, layout=:z) * AlgebraOfGraphics.density() |>
        draw
end

reftest("density layout cat color") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, layout=:z, color = :z) * AlgebraOfGraphics.density() |>
        draw
end

reftest("density 2d layout") do
    x = sin.(1:40) .+ repeat([0, 2], inner = 20)
    z = repeat(["A", "B"], inner = 20)
    data((; x, z)) *
        mapping(:x, :x, layout=:z) * AlgebraOfGraphics.density() |>
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
            ))
end

reftest("category addition middle") do
    data((; sex = repeat(["m", "f"], 10), weight = 1:20)) *
        mapping(:sex, :weight) *
        visual(Scatter) |> draw(scales(X = (;
            categories = ["m", "d" => rich("diverse", color = :fuchsia), "f"],
        )))
end

reftest("x palette override") do
    data((; category = ["A", "B", "C", missing], y = [4, 5, 6, 2])) *
        mapping(:category, :y) *
        visual(BarPlot) |>
        draw(scales(X = (; palette = [1, 2, 3, 5])))
end

reftest("issue 434") do
    df = (; x = 1:5, y = [1, 4, 3, 5, 2], group = [true, true, false, false, false])
    plt = AlgebraOfGraphics.data(df) * mapping(:x, :y; color=:group) * visual(Scatter; marker=:star5, markersize=15)
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
    plt = data(df) * mapping(:x, :y, text=:label => verbatim, color = :label) * visual(Makie.Text)
    fg = draw(plt)
end

reftest("boxplot") do
    df = (x=repeat(["a", "b", "c"], inner = 20), y=1:60)
    plt = data(df) *
        mapping(:x, :y) * visual(BoxPlot)
    draw(plt)
end

reftest("boxplot horizontal") do
    df = (x=repeat(["a", "b", "c"], inner = 20), y=1:60)
    plt = data(df) *
        mapping(:x, :y) * visual(BoxPlot, orientation = :horizontal)
    draw(plt)
end

reftest("boxplot cat color") do
    df = (x=repeat(["a", "b", "c"], inner = 20), y=1:60)
    plt = data(df) *
        mapping(:x, :y, color = :x) * visual(BoxPlot)
    draw(plt)
end

reftest("boxplot dodge") do
    df = (x=repeat(["a", "b", "c"], inner = 20), x2 = repeat(["x", "y"], 30), y=1:60)
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
    data((; x, lower, upper)) * mapping(:x, :lower, :upper) * visual(Band) |> draw
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

reftest("filled contours analysis") do
    volcano = DelimitedFiles.readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

    x = repeat(range(3, 17, length = size(volcano, 1)), size(volcano, 2))
    y = repeat(range(52, 79, length = size(volcano, 2)), inner = size(volcano, 1))
    z = vec(volcano)

    data((; x, y, z)) *
        mapping(:x => "The X", :y, :z, row = :x => >(10)) *
        filled_contours(; bands = 10) |> draw
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
    data((; x, y, id, subid, color)) * mapping(:x, :y, :id => verbatim, :subid => verbatim,
        color = :color) *
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

reftest("arrows cat color and marker") do
    x=repeat(1:10, inner=10)
    y=repeat(1:10, outer=10)
    u=cos.(x)
    v=sin.(y)
    c=round.(Bool, sin.(1:100) .* 0.5 .+ 0.5)
    d=round.(Bool, cos.(1:100) .* 0.5 .+ 0.5)
    df = (; x, y, u, v, c, d)
    colors = [colorant"#E24A33", colorant"#348ABD"]
    heads = ['◮', '◭']
    plt = data(df) *
        mapping(:x, :y, :u, :v) *
        mapping(arrowhead = :c => nonnumeric) *
        mapping(color = :d => nonnumeric) *
        visual(Arrows, arrowsize=14, lengthscale=0.4, linewidth = 1)
    fg = draw(plt, scales(Marker = (; palette = heads), Color = (; palette = colors)))
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
    # spec2 = data((; x, group)) * mapping(:x, color = :group) * visual(ECDFPlot)
    f = Figure()
    draw!(f[1, 1], spec1)
    # fg = draw!(f[2, 1], spec2)
    # legend!(f[2, 2], fg)
    f
end

reftest("hist") do
    x = cos.(range(0, pi/2, length = 100))
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
    x = cos.(range(0, pi/2, length = 100))
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
