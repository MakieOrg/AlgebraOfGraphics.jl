@testset "density1D" begin
    df = (x=rand(1000), c=rand(["a", "b"], 1000))
    npoints = 500

    layer = data(df) * mapping(:x, color=:c) * AlgebraOfGraphics.density(; npoints)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    rgx1 = range(extrema(df.x)..., length=npoints)
    d1 = pdf(kde(x1), rgx1)

    x2 = df.x[df.c .== "b"]
    rgx2 = range(extrema(df.x)..., length=npoints)
    d2 = pdf(kde(x2), rgx2)

    rgx, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test d[2] ≈ d2

    layer = data(df) * mapping(:x, color=:c) * AlgebraOfGraphics.density(; npoints, datalimits=extrema)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    rgx1 = range(extrema(x1)..., length=npoints)
    d1 = pdf(kde(x1), rgx1)

    x2 = df.x[df.c .== "b"]
    rgx2 = range(extrema(x2)..., length=npoints)
    d2 = pdf(kde(x2), rgx2)

    rgx, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test d[2] ≈ d2

    @test processedlayer.primary == NamedArguments((color=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == AlgebraOfGraphics.LinesFill

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "pdf")
    insert!(labels, :color, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "density2d" begin
    df = (x=rand(1000), y=rand(1000), c=rand(["a", "b"], 1000))
    npoints = 500
    bandwidth = (0.01, 0.01)

    layer = data(df) * mapping(:x, :y, color=:c) * AlgebraOfGraphics.density(; npoints, bandwidth)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    rgx1 = range(extrema(df.x)..., length=npoints)
    rgy1 = range(extrema(df.y)..., length=npoints)
    d1 = pdf(kde((x1, y1); bandwidth), rgx1, rgy1)

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    rgx2 = range(extrema(df.x)..., length=npoints)
    rgy2 = range(extrema(df.y)..., length=npoints)
    d2 = pdf(kde((x2, y2); bandwidth), rgx2, rgy2)

    rgx, rgy, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test rgy[1] ≈ rgy1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test rgy[2] ≈ rgy2
    @test d[2] ≈ d2

    @test processedlayer.primary == NamedArguments((color=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, 3, "pdf")
    insert!(labels, :color, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "expectation1d" begin
    df = (x=rand(["a", "b"], 1000), y=rand(1000), c=rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, layout=:c) * expectation()
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    ma1 = mean(df.y[(df.x .== "a") .& (df.c .== "a")])
    mb1 = mean(df.y[(df.x .== "b") .& (df.c .== "a")])

    ma2 = mean(df.y[(df.x .== "a") .& (df.c .== "b")])
    mb2 = mean(df.y[(df.x .== "b") .& (df.c .== "b")])

    x, m = processedlayer.positional
    x1, m1 = x[1], m[1]
    x2, m2 = x[2], m[2]

    @test x1 == ["a", "b"]
    @test m1 ≈ [ma1, mb1]

    @test x2 == ["a", "b"]
    @test m2 ≈ [ma2, mb2]

    @test processedlayer.primary == NamedArguments((layout=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :layout, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "expectation2d" begin
    df = (x=rand(["a", "b"], 1000), y=rand(["a", "b"], 1000), z=rand(1000), c=rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, :z, layout=:c) * expectation()
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    maa1 = mean(df.z[(df.x .== "a") .& (df.y .== "a") .& (df.c .== "a")])
    mab1 = mean(df.z[(df.x .== "a") .& (df.y .== "b") .& (df.c .== "a")])
    mba1 = mean(df.z[(df.x .== "b") .& (df.y .== "a") .& (df.c .== "a")])
    mbb1 = mean(df.z[(df.x .== "b") .& (df.y .== "b") .& (df.c .== "a")])

    maa2 = mean(df.z[(df.x .== "a") .& (df.y .== "a") .& (df.c .== "b")])
    mab2 = mean(df.z[(df.x .== "a") .& (df.y .== "b") .& (df.c .== "b")])
    mba2 = mean(df.z[(df.x .== "b") .& (df.y .== "a") .& (df.c .== "b")])
    mbb2 = mean(df.z[(df.x .== "b") .& (df.y .== "b") .& (df.c .== "b")])

    x, y, m = processedlayer.positional
    x1, y1, m1 = x[1], y[1], m[1]
    x2, y2, m2 = x[2], y[2], m[2]

    @test x1 == ["a", "b"]
    @test y1 == ["a", "b"]
    @test m1 ≈ [maa1 mab1; mba1 mbb1]

    @test x2 == ["a", "b"]
    @test y2 == ["a", "b"]
    @test m2 ≈ [maa2 mab2; mba2 mbb2]

    @test processedlayer.primary == NamedArguments((layout=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, 3, "z")
    insert!(labels, :layout, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "frequency1d" begin
    df = (x=rand(["a", "b"], 1000), c=rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, layout=:c) * frequency()
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    na1 = sum((df.x .== "a") .& (df.c .== "a"))
    nb1 = sum((df.x .== "b") .& (df.c .== "a"))

    na2 = sum((df.x .== "a") .& (df.c .== "b"))
    nb2 = sum((df.x .== "b") .& (df.c .== "b"))

    x, n = processedlayer.positional
    x1, n1 = x[1], n[1]
    x2, n2 = x[2], n[2]

    @test x1 == ["a", "b"]
    @test n1 ≈ [na1, nb1]

    @test x2 == ["a", "b"]
    @test n2 ≈ [na2, nb2]

    @test processedlayer.primary == NamedArguments((layout=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "count")
    insert!(labels, :layout, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "frequency2d" begin
    df = (x=rand(["a", "b"], 1000), y=rand(["a", "b"], 1000), c=rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, layout=:c) * frequency()
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    naa1 = sum((df.x .== "a") .& (df.y .== "a") .& (df.c .== "a"))
    nab1 = sum((df.x .== "a") .& (df.y .== "b") .& (df.c .== "a"))
    nba1 = sum((df.x .== "b") .& (df.y .== "a") .& (df.c .== "a"))
    nbb1 = sum((df.x .== "b") .& (df.y .== "b") .& (df.c .== "a"))

    naa2 = sum((df.x .== "a") .& (df.y .== "a") .& (df.c .== "b"))
    nab2 = sum((df.x .== "a") .& (df.y .== "b") .& (df.c .== "b"))
    nba2 = sum((df.x .== "b") .& (df.y .== "a") .& (df.c .== "b"))
    nbb2 = sum((df.x .== "b") .& (df.y .== "b") .& (df.c .== "b"))

    x, y, n = processedlayer.positional
    x1, y1, n1 = x[1], y[1], n[1]
    x2, y2, n2 = x[2], y[2], n[2]

    @test x1 == ["a", "b"]
    @test y1 == ["a", "b"]
    @test n1 ≈ [naa1 nab1; nba1 nbb1]

    @test x2 == ["a", "b"]
    @test y2 == ["a", "b"]
    @test n2 ≈ [naa2 nab2; nba2 nbb2]

    @test processedlayer.primary == NamedArguments((layout=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, 3, "count")
    insert!(labels, :layout, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end

@testset "histogram1D" begin
    df = (x=rand(1000), c=rand(["a", "b"], 1000))
    bins = 0:0.01:1

    layer = data(df) * mapping(:x, color=:c) * AlgebraOfGraphics.histogram(; bins)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    w1 = fit(Histogram, x1, bins).weights

    x2 = df.x[df.c .== "b"]
    w2 = fit(Histogram, x2, bins).weights

    rgx, w = processedlayer.positional

    @test rgx[1] ≈ (bins[1:end-1] .+ bins[2:end]) ./ 2
    @test w[1] == w1

    @test rgx[2] ≈ (bins[1:end-1] .+ bins[2:end]) ./ 2
    @test w[2] == w2

    bins, closed = 12, :left
    layer = data(df) * mapping(:x, color=:c) * AlgebraOfGraphics.histogram(; bins, closed, datalimits=extrema)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    bins1 = histrange(extrema(x1)..., bins, closed)
    w1 = fit(Histogram, x1, bins1).weights

    x2 = df.x[df.c .== "b"]
    bins2 = histrange(extrema(x2)..., bins, closed)
    w2 = fit(Histogram, x2, bins2).weights

    rgx, w = processedlayer.positional

    @test rgx[1] ≈ (bins1[1:end-1] .+ bins1[2:end]) ./ 2
    @test w[1] ≈ w1

    @test rgx[2] ≈ (bins2[1:end-1] .+ bins2[2:end]) ./ 2
    @test w[2] ≈ w2

    @test processedlayer.primary == NamedArguments((color=["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments((dodge_gap=0, x_gap=0))
    @test processedlayer.plottype == AlgebraOfGraphics.BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "count")
    insert!(labels, :color, "c")
    for key in keys(labels)
        @test labels[key] == AlgebraOfGraphics.to_label(processedlayer.labels[key])
    end
end
