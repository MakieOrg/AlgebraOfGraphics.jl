@testset "density1D" begin
    df = (x = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 500

    layer = data(df) * mapping(:x, color = :c) * AlgebraOfGraphics.density(; npoints)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    rgx1 = range(extrema(df.x)..., length = npoints)
    d1 = pdf(kde(x1), rgx1)

    x2 = df.x[df.c .== "b"]
    rgx2 = range(extrema(df.x)..., length = npoints)
    d2 = pdf(kde(x2), rgx2)

    rgx, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test d[2] ≈ d2

    layer = data(df) * mapping(:x, color = :c) * AlgebraOfGraphics.density(; npoints, datalimits = extrema)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    rgx1 = range(extrema(x1)..., length = npoints)
    d1 = pdf(kde(x1), rgx1)

    x2 = df.x[df.c .== "b"]
    rgx2 = range(extrema(x2)..., length = npoints)
    d2 = pdf(kde(x2), rgx2)

    rgx, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test d[2] ≈ d2

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments((; direction = :x))
    @test processedlayer.plottype == AlgebraOfGraphics.LinesFill

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, :color, "c")
    insert!(labels, 2, "pdf")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "density2d" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 500
    bandwidth = (0.01, 0.01)

    layer = data(df) * mapping(:x, :y, color = :c) * AlgebraOfGraphics.density(; npoints, bandwidth)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    rgx1 = range(extrema(df.x)..., length = npoints)
    rgy1 = range(extrema(df.y)..., length = npoints)
    d1 = pdf(kde((x1, y1); bandwidth), rgx1, rgy1)

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    rgx2 = range(extrema(df.x)..., length = npoints)
    rgy2 = range(extrema(df.y)..., length = npoints)
    d2 = pdf(kde((x2, y2); bandwidth), rgx2, rgy2)

    rgx, rgy, d = processedlayer.positional

    @test rgx[1] ≈ rgx1
    @test rgy[1] ≈ rgy1
    @test d[1] ≈ d1

    @test rgx[2] ≈ rgx2
    @test rgy[2] ≈ rgy2
    @test d[2] ≈ d2

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    insert!(labels, 3, "pdf")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "expectation1d" begin
    df = (x = rand(["a", "b"], 1000), y = rand(1000), c = rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, layout = :c) * expectation()
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

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments((direction = :y,))
    @test processedlayer.plottype == BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :layout, "c")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "expectation2d" begin
    df = (x = rand(["a", "b"], 1000), y = rand(["a", "b"], 1000), z = rand(1000), c = rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, :z, layout = :c) * expectation()
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

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, 3, "z")
    insert!(labels, :layout, "c")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "frequency1d" begin
    df = (x = rand(["a", "b"], 1000), c = rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, layout = :c) * frequency()
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

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments((; direction = :y))
    @test processedlayer.plottype == BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, :layout, "c")
    insert!(labels, 2, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "frequency2d" begin
    df = (x = rand(["a", "b"], 1000), y = rand(["a", "b"], 1000), c = rand(["a", "b"], 1000))

    layer = data(df) * mapping(:x, :y, layout = :c) * frequency()
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

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments()
    @test processedlayer.plottype == Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :layout, "c")
    insert!(labels, 3, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "midpoints" begin
    edges = [1, 2, 10, 12]
    @test midpoints(edges) ≈ [1.5, 6, 11]

    edges_rg = 1:2:5
    edges_v = [1, 3, 5]
    @test midpoints(edges_v) ≈ midpoints(edges_rg) ≈ [2, 4]
end

@testset "histogram1D" begin
    df = (x = rand(1000), c = rand(["a", "b"], 1000))
    bins = 0:0.01:1

    layer = data(df) * mapping(:x, color = :c) * histogram(; bins)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    w1 = fit(Histogram, x1, bins).weights

    x2 = df.x[df.c .== "b"]
    w2 = fit(Histogram, x2, bins).weights

    rgx, w = processedlayer.positional
    width = processedlayer.named[:width]

    @test rgx[1] ≈ (bins[1:(end - 1)] .+ bins[2:end]) ./ 2
    @test w[1] == w1
    @test width[1] ≈ diff(bins)

    @test rgx[2] ≈ (bins[1:(end - 1)] .+ bins[2:end]) ./ 2
    @test w[2] == w2
    @test width[2] ≈ diff(bins)

    bins, closed = 12, :left
    layer = data(df) * mapping(:x, color = :c) * histogram(; bins, closed, datalimits = extrema)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    bins1 = histrange(extrema(x1)..., bins, closed)
    w1 = fit(Histogram, x1, bins1).weights

    x2 = df.x[df.c .== "b"]
    bins2 = histrange(extrema(x2)..., bins, closed)
    w2 = fit(Histogram, x2, bins2).weights

    rgx, w = processedlayer.positional
    width = processedlayer.named[:width]

    @test rgx[1] ≈ (bins1[1:(end - 1)] .+ bins1[2:end]) ./ 2
    @test w[1] ≈ w1
    @test width[1] ≈ diff(bins1)

    @test rgx[2] ≈ (bins2[1:(end - 1)] .+ bins2[2:end]) ./ 2
    @test w[2] ≈ w2
    @test width[2] ≈ diff(bins2)

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test processedlayer.attributes == NamedArguments((direction = :y, gap = 0, dodge_gap = 0))
    @test keys(processedlayer.named) == Indices([:width])
    @test processedlayer.plottype == AlgebraOfGraphics.BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, :color, "c")
    insert!(labels, 2, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)

    bins = 12.3
    layer = data(df) * mapping(:x, color = :c) * histogram(; bins)
    @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)
end

@testset "weightedhistogram1d" begin
    df = (x = rand(1000), z = rand(1000), c = rand(["a", "b"], 1000))
    bins = collect(0:0.01:1) # test vector of bins

    layer = data(df) * mapping(:x, color = :c, weights = :z) * histogram(; bins)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    z1 = df.z[df.c .== "a"]
    w1 = fit(Histogram, x1, weights(z1), bins).weights

    x2 = df.x[df.c .== "b"]
    z2 = df.z[df.c .== "b"]
    w2 = fit(Histogram, x2, weights(z2), bins).weights

    rgx, w = processedlayer.positional
    width = processedlayer.named[:width]

    @test rgx[1] ≈ (bins[1:(end - 1)] .+ bins[2:end]) ./ 2
    @test w[1] ≈ w1
    @test width[1] ≈ diff(bins)

    @test rgx[2] ≈ (bins[1:(end - 1)] .+ bins[2:end]) ./ 2
    @test w[2] ≈ w2
    @test width[2] ≈ diff(bins)

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test keys(processedlayer.named) == Indices([:width])
    @test processedlayer.attributes == NamedArguments((direction = :y, gap = 0, dodge_gap = 0))
    @test processedlayer.plottype == AlgebraOfGraphics.BarPlot

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, :color, "c")
    insert!(labels, :weights, "z")
    insert!(labels, 2, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "histogram2d" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    binsx, binsy = 0:0.01:1, 0:0.02:1
    bins = (binsx, binsy)

    layer = data(df) * mapping(:x, :y, layout = :c) * histogram(; bins)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    w1 = fit(Histogram, (x1, y1), bins).weights

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    w2 = fit(Histogram, (x2, y2), bins).weights

    rgx, rgy, w = processedlayer.positional

    @test rgx[1] ≈ (binsx[1:(end - 1)] .+ binsx[2:end]) ./ 2
    @test rgy[1] ≈ (binsy[1:(end - 1)] .+ binsy[2:end]) ./ 2
    @test w[1] == w1

    @test rgx[2] ≈ (binsx[1:(end - 1)] .+ binsx[2:end]) ./ 2
    @test rgy[2] ≈ (binsy[1:(end - 1)] .+ binsy[2:end]) ./ 2
    @test w[2] == w2

    bins, closed = 12, :left
    layer = data(df) * mapping(:x, :y, layout = :c) * histogram(; bins, closed, datalimits = extrema)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    binsx1 = histrange(extrema(x1)..., bins, closed)
    binsy1 = histrange(extrema(y1)..., bins, closed)
    w1 = fit(Histogram, (x1, y1), (binsx1, binsy1)).weights

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    binsx2 = histrange(extrema(x2)..., bins, closed)
    binsy2 = histrange(extrema(y2)..., bins, closed)
    w2 = fit(Histogram, (x2, y2), (binsx2, binsy2)).weights

    rgx, rgy, w = processedlayer.positional

    @test rgx[1] ≈ (binsx1[1:(end - 1)] .+ binsx1[2:end]) ./ 2
    @test rgy[1] ≈ (binsy1[1:(end - 1)] .+ binsy1[2:end]) ./ 2
    @test w[1] == w1

    @test rgx[2] ≈ (binsx2[1:(end - 1)] .+ binsx2[2:end]) ./ 2
    @test rgy[2] ≈ (binsy2[1:(end - 1)] .+ binsy2[2:end]) ./ 2
    @test w[2] == w2

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test isempty(processedlayer.attributes)
    @test processedlayer.plottype == AlgebraOfGraphics.Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :layout, "c")
    insert!(labels, 3, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)

    bins = rand(2, 2)
    layer = data(df) * mapping(:x, color = :c) * histogram(; bins)
    @test_throws ArgumentError AlgebraOfGraphics.ProcessedLayer(layer)
end

@testset "weightedhistogram2d" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b"], 1000))
    binsx, binsy = 0:0.01:1, 0:0.02:1
    bins = (binsx, binsy)

    layer = data(df) * mapping(:x, :y, layout = :c, weights = :z) * histogram(; bins)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    z1 = df.z[df.c .== "a"]
    w1 = fit(Histogram, (x1, y1), weights(z1), bins).weights

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    z2 = df.z[df.c .== "b"]
    w2 = fit(Histogram, (x2, y2), weights(z2), bins).weights

    rgx, rgy, w = processedlayer.positional

    @test rgx[1] ≈ (binsx[1:(end - 1)] .+ binsx[2:end]) ./ 2
    @test rgy[1] ≈ (binsy[1:(end - 1)] .+ binsy[2:end]) ./ 2
    @test w[1] == w1

    @test rgx[2] ≈ (binsx[1:(end - 1)] .+ binsx[2:end]) ./ 2
    @test rgy[2] ≈ (binsy[1:(end - 1)] .+ binsy[2:end]) ./ 2
    @test w[2] == w2

    @test processedlayer.primary == NamedArguments((layout = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test isempty(processedlayer.attributes)
    @test processedlayer.plottype == AlgebraOfGraphics.Heatmap

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :layout, "c")
    insert!(labels, :weights, "z")
    insert!(labels, 3, "count")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "intercept" begin
    x = rand(10)
    mat = AlgebraOfGraphics.add_intercept_column(x)
    @test mat == [ones(10) x]
    @test eltype(mat) == Float64

    x = rand(1:3, 10)
    mat = AlgebraOfGraphics.add_intercept_column(x)
    @test mat == [ones(10) x]
    @test eltype(mat) == Float64
end

@testset "linear" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints, dropcollinear = 150, false
    layer = data(df) * mapping(:x, :y, color = :c) * linear(; npoints, dropcollinear)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    lm1 = GLM.lm([fill(one(eltype(x1)), length(x1)) x1], y1; dropcollinear)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1, lower1, upper1 = map(vec, GLM.predict(lm1, [ones(length(x̂1)) x̂1]; interval = :confidence))

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    lm2 = GLM.lm([fill(one(eltype(x2)), length(x2)) x2], y2; dropcollinear)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2, lower2, upper2 = map(vec, GLM.predict(lm2, [ones(length(x̂2)) x̂2]; interval = :confidence))

    x̂, ŷ = processedlayer.positional
    lower, upper = processedlayer.named[:lower], processedlayer.named[:upper]

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1
    @test lower[1] ≈ lower1
    @test upper[1] ≈ upper1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2
    @test lower[2] ≈ lower2
    @test upper[2] ≈ upper2

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test processedlayer.attributes == NamedArguments((; direction = :x))

    @test processedlayer.plottype == LinesFill

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)

    # Test `interval` and `level` custom values
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints, dropcollinear = 150, false
    interval, level = :prediction, 0.9
    layer = data(df) * mapping(:x, :y, color = :c) * linear(; npoints, dropcollinear, interval, level)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    lm1 = GLM.lm([fill(one(eltype(x1)), length(x1)) x1], y1; dropcollinear)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1, lower1, upper1 = map(vec, GLM.predict(lm1, [ones(length(x̂1)) x̂1]; interval, level))

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    lm2 = GLM.lm([fill(one(eltype(x2)), length(x2)) x2], y2; dropcollinear)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2, lower2, upper2 = map(vec, GLM.predict(lm2, [ones(length(x̂2)) x̂2]; interval, level))

    x̂, ŷ = processedlayer.positional
    lower, upper = processedlayer.named[:lower], processedlayer.named[:upper]

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1
    @test lower[1] ≈ lower1
    @test upper[1] ≈ upper1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2
    @test lower[2] ≈ lower2
    @test upper[2] ≈ upper2
end

@testset "weightedlinear" begin
    df = (x = rand(1000), y = rand(1000), z = rand(1000), c = rand(["a", "b"], 1000))
    npoints, dropcollinear = 150, false
    layer = data(df) * mapping(:x, :y, color = :c, weights = :z) * linear(; npoints, dropcollinear)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    z1 = df.z[df.c .== "a"]
    lm1 = GLM.lm([fill(one(eltype(x1)), length(x1)) x1], y1; dropcollinear, wts = z1)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1 = vec(GLM.predict(lm1, [ones(length(x̂1)) x̂1]; interval = nothing))

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    z2 = df.z[df.c .== "b"]
    lm2 = GLM.lm([fill(one(eltype(x2)), length(x2)) x2], y2; dropcollinear, wts = z2)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2 = vec(GLM.predict(lm2, [ones(length(x̂2)) x̂2]; interval = nothing))

    x̂, ŷ = processedlayer.positional

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test isempty(processedlayer.attributes)

    @test processedlayer.plottype == Lines

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    insert!(labels, :weights, "z")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)
end

@testset "smooth" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 150
    layer = data(df) * mapping(:x, :y, color = :c) * smooth(; npoints)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    loess1 = Loess.loess(x1, y1)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1 = Loess.predict(loess1, x̂1)

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    loess2 = Loess.loess(x2, y2)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2 = Loess.predict(loess2, x̂2)

    x̂, ŷ = processedlayer.positional

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test isempty(processedlayer.attributes)

    @test processedlayer.plottype == Lines

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    @test labels == map(AlgebraOfGraphics.to_label, processedlayer.labels)

    # Also test integer input
    df = (x = rand(1:3, 1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 150
    layer = data(df) * mapping(:x, :y, color = :c) * smooth(; npoints)
    processedlayer = AlgebraOfGraphics.ProcessedLayer(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    loess1 = Loess.loess(x1, y1)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1 = Loess.predict(loess1, x̂1)

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    loess2 = Loess.loess(x2, y2)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2 = Loess.predict(loess2, x̂2)

    x̂, ŷ = processedlayer.positional

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2
end

@testset "aggregate fails with higher-dimensional result" begin
    df = (x = [1, 1, 2, 2], y = [1, 2, 3, 4])

    matrix_func = v -> reshape(v, 1, :)

    layer = data(df) * mapping(:x, :y) * aggregate(2 => matrix_func)

    @test_throws "Aggregation of positional argument 2 returned 2-dimensional arrays with size (1, 2). Only scalars or 1-dimensional vectors are supported." AlgebraOfGraphics.ProcessedLayer(layer)
end
