@testset "density1D" begin
    df = (x = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 500

    layer = data(df) * mapping(:x, color = :c) * AlgebraOfGraphics.density(; npoints, datalimits = extrema)
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)

    processedlayer = processedlayers.layers[1]
    rgx, d = processedlayer.positional

    @test processedlayer.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(processedlayer.named)
    @test processedlayer.attributes == NamedArguments((; direction = :x, alpha = 0.15))
    @test processedlayer.plottype == Band

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
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)

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

    pl_line = processedlayers.layers[2]
    x̂, ŷ = pl_line.positional
    pl_band = processedlayers.layers[1]
    lower, upper = pl_band.positional[2], pl_band.positional[3]

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1
    @test lower[1] ≈ lower1
    @test upper[1] ≈ upper1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2
    @test lower[2] ≈ lower2
    @test upper[2] ≈ upper2

    @test pl_line.primary == NamedArguments((color = ["a", "b"],))

    @test pl_line.plottype == Lines
    @test pl_band.plottype == Band

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    @test labels == map(AlgebraOfGraphics.to_label, pl_line.labels)

    # Test `interval` and `level` custom values
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints, dropcollinear = 150, false
    interval, level = :prediction, 0.9
    layer = data(df) * mapping(:x, :y, color = :c) * linear(; npoints, dropcollinear, interval, level)
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)

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

    pl_band = processedlayers.layers[1]
    pl_line = processedlayers.layers[2]
    x̂, ŷ = pl_line.positional
    lower, upper = pl_band.positional[2], pl_band.positional[3]

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
    df = (x = rand(1000), y = rand(1000), z = rand(1:5, 1000), c = rand(["a", "b"], 1000))
    npoints, dropcollinear = 150, false
    layer = data(df) * mapping(:x, :y, color = :c, weights = :z) * linear(; npoints, dropcollinear)
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)

    x1 = df.x[df.c .== "a"]
    y1 = df.y[df.c .== "a"]
    z1 = fweights(df.z[df.c .== "a"])
    lm1 = GLM.lm([fill(one(eltype(x1)), length(x1)) x1], y1; dropcollinear, weights = z1)
    x̂1 = range(extrema(x1)...; length = npoints)
    ŷ1 = vec(GLM.predict(lm1, [ones(length(x̂1)) x̂1]; interval = nothing))

    x2 = df.x[df.c .== "b"]
    y2 = df.y[df.c .== "b"]
    z2 = fweights(df.z[df.c .== "b"])
    lm2 = GLM.lm([fill(one(eltype(x2)), length(x2)) x2], y2; dropcollinear, weights = z2)
    x̂2 = range(extrema(x2)...; length = npoints)
    ŷ2 = vec(GLM.predict(lm2, [ones(length(x̂2)) x̂2]; interval = nothing))

    pl_band = processedlayers.layers[1]
    pl_line = processedlayers.layers[2]
    x̂, ŷ = pl_line.positional

    @test x̂[1] ≈ x̂1
    @test ŷ[1] ≈ ŷ1

    @test x̂[2] ≈ x̂2
    @test ŷ[2] ≈ ŷ2

    @test pl_line.primary == NamedArguments((color = ["a", "b"],))
    @test isempty(pl_line.named)
    @test isempty(pl_line.attributes)

    @test pl_line.plottype == Lines

    labels = MixedArguments()
    insert!(labels, 1, "x")
    insert!(labels, 2, "y")
    insert!(labels, :color, "c")
    insert!(labels, :weights, "z")
    @test labels == map(AlgebraOfGraphics.to_label, pl_line.labels)
end

@testset "smooth" begin
    df = (x = rand(1000), y = rand(1000), c = rand(["a", "b"], 1000))
    npoints = 150
    layer = data(df) * mapping(:x, :y, color = :c) * smooth(; npoints)
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)

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

    processedlayer = processedlayers.layers[2]
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
    processedlayers = AlgebraOfGraphics.ProcessedLayers(layer)
    processedlayer = processedlayers.layers[2]

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

@testset "generic dodge rerouting" begin
    df = (
        x = [1, 1, 2, 2],
        y = [1.0, 2.0, 3.0, 4.0],
        group = ["A", "B", "A", "B"],
    )

    # `dodge_x` on a vertical BarPlot (dodge aesthetic = AesDodgeX) is rerouted to `:dodge`
    layer = data(df) * mapping(:x, :y, dodge_x = :group) * visual(AlgebraOfGraphics.BarPlot)
    p = AlgebraOfGraphics.ProcessedLayer(layer)
    @test haskey(p.primary, :dodge)
    @test !haskey(p.primary, :dodge_x)

    # `dodge_y` on a horizontal BarPlot (dodge aesthetic = AesDodgeY) is rerouted to `:dodge`
    layer = data(df) * mapping(:y, :x, dodge_y = :group) * visual(AlgebraOfGraphics.BarPlot, direction = :x)
    p = AlgebraOfGraphics.ProcessedLayer(layer)
    @test haskey(p.primary, :dodge)
    @test !haskey(p.primary, :dodge_y)

    # `dodge_x` on a Scatter (no `:dodge` aesthetic) stays as `:dodge_x`
    layer = data(df) * mapping(:x, :y, dodge_x = :group) * visual(Scatter)
    p = AlgebraOfGraphics.ProcessedLayer(layer)
    @test haskey(p.primary, :dodge_x)
    @test !haskey(p.primary, :dodge)

    # `dodge_y` on a vertical BarPlot (dodge aesthetic = AesDodgeX) is NOT rerouted (axis mismatch)
    layer = data(df) * mapping(:x, :y, dodge_y = :group) * visual(AlgebraOfGraphics.BarPlot)
    p = AlgebraOfGraphics.ProcessedLayer(layer)
    @test haskey(p.primary, :dodge_y)
    @test !haskey(p.primary, :dodge)

    # `dodge_x` on a vertical BoxPlot is rerouted to `:dodge`
    df_box = (x = [1, 1, 1, 2, 2, 2], y = [1.0, 2, 3, 4, 5, 6], group = ["A", "B", "A", "B", "A", "B"])
    layer = data(df_box) * mapping(:x, :y, dodge_x = :group) * visual(AlgebraOfGraphics.BoxPlot)
    p = AlgebraOfGraphics.ProcessedLayer(layer)
    @test haskey(p.primary, :dodge)
    @test !haskey(p.primary, :dodge_x)

    # Both `:dodge` and `:dodge_x` on the same BarPlot is an error
    layer = data(df) * mapping(:x, :y, dodge = :group, dodge_x = :group) * visual(AlgebraOfGraphics.BarPlot)
    @test_throws "both `dodge_x` and `dodge`" AlgebraOfGraphics.ProcessedLayer(layer)
end

@testset "missing and NaN handling" begin
    @testset "density 1D" begin
        df = (; x = Union{Missing, Float64}[1.0, 2.0, missing, 3.0, NaN, 4.0, 5.0])
        layer = data(df) * mapping(:x) * AlgebraOfGraphics.density(; npoints = 50, datalimits = extrema)
        pls = AlgebraOfGraphics.ProcessedLayers(layer).layers
        line_pl = pls[2]
        rgx, d = line_pl.positional

        clean = [1.0, 2.0, 3.0, 4.0, 5.0]
        rgx_ref = range(extrema(clean)..., length = 50)
        d_ref = pdf(kde(clean), rgx_ref)
        @test only(rgx) ≈ rgx_ref
        @test only(d) ≈ d_ref
    end

    @testset "density 2D" begin
        df = (;
            x = Union{Missing, Float64}[1.0, 2.0, missing, 3.0, 4.0, 5.0],
            y = Union{Missing, Float64}[1.0, NaN, 3.0, 4.0, 5.0, 6.0],
        )
        layer = data(df) * mapping(:x, :y) * AlgebraOfGraphics.density(; npoints = 20, datalimits = extrema, bandwidth = (0.5, 0.5))
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        rgx, rgy, d = pl.positional

        x_clean = [1.0, 3.0, 4.0, 5.0]
        y_clean = [1.0, 4.0, 5.0, 6.0]
        rgx_ref = range(extrema(x_clean)..., length = 20)
        rgy_ref = range(extrema(y_clean)..., length = 20)
        d_ref = pdf(kde((x_clean, y_clean); bandwidth = (0.5, 0.5)), rgx_ref, rgy_ref)
        @test only(rgx) ≈ rgx_ref
        @test only(rgy) ≈ rgy_ref
        @test only(d) ≈ d_ref
    end

    @testset "histogram" begin
        df = (; x = Union{Missing, Float64}[1.5, 2.5, missing, 3.5, NaN, 4.5])
        layer = data(df) * mapping(:x) * histogram(; bins = 1:5)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test collect(only(pl.positional[2])) == [1, 1, 1, 1]
    end

    @testset "linear" begin
        df = (;
            x = Union{Missing, Float64}[1.0, 2.0, 3.0, missing, 4.0, 5.0],
            y = Union{Missing, Float64}[2.0, NaN, 6.0, 8.0, 10.0, 11.0],
        )
        layer = data(df) * mapping(:x, :y) * linear()
        pls = AlgebraOfGraphics.ProcessedLayers(layer).layers
        line_pl = pls[2]
        x̂, ŷ = line_pl.positional

        x_clean = [1.0, 3.0, 4.0, 5.0]
        y_clean = [2.0, 6.0, 10.0, 11.0]
        β = [ones(length(x_clean)) x_clean] \ y_clean
        @test first(only(x̂)) ≈ 1.0
        @test last(only(x̂)) ≈ 5.0
        @test first(only(ŷ)) ≈ β[1] + β[2] * 1.0
        @test last(only(ŷ)) ≈ β[1] + β[2] * 5.0
    end

    @testset "smooth" begin
        df = (;
            x = Float64[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            y = Union{Missing, Float64}[1, NaN, 4, 5, missing, 7, 8, 9, 11, 12],
        )
        layer = data(df) * mapping(:x, :y) * smooth(; interval = nothing)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        x̂, ŷ = pl.positional

        x_clean = [1.0, 3.0, 4.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        y_clean = [1.0, 4.0, 5.0, 7.0, 8.0, 9.0, 11.0, 12.0]
        ŷ_ref = Loess.predict(
            Loess.loess(x_clean, y_clean; span = 0.75, degree = 2),
            collect(range(extrema(x_clean)..., length = 200)),
        )
        @test only(ŷ) ≈ ŷ_ref
    end

    @testset "frequency" begin
        df = (; x = Union{Missing, String}["a", "b", missing, "a", "c", missing])
        layer = data(df) * mapping(:x) * frequency()
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test isequal(collect(only(pl.positional[1])), ["a", "b", "c", missing])
        @test collect(only(pl.positional[2])) == [2, 1, 1, 2]

        df_b = (; b = Union{Missing, Bool}[true, false, missing, true, false, missing])
        pl_b = AlgebraOfGraphics.ProcessedLayer(data(df_b) * mapping(:b) * frequency())
        @test isequal(collect(only(pl_b.positional[1])), [false, true, missing])
        @test collect(only(pl_b.positional[2])) == [2, 2, 2]
    end

    @testset "expectation" begin
        df = (;
            g = Union{Missing, String}["a", "a", "b", missing, "a", "b"],
            y = Union{Missing, Float64}[1.0, 2.0, NaN, 5.0, 3.0, 10.0],
        )
        layer = data(df) * mapping(:g, :y) * expectation()
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test isequal(collect(only(pl.positional[1])), ["a", "b", missing])
        @test collect(only(pl.positional[2])) ≈ [2.0, 10.0, 5.0]
    end

    @testset "missing/NaN weight drops the row" begin
        df = (; x = [1.0, 2.0, 3.0], w = Union{Missing, Float64}[1.0, NaN, 3.0])
        layer = data(df) * mapping(:x, weights = :w) * histogram(; bins = 0:1:5)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test collect(only(pl.positional[2])) == [0.0, 1.0, 0.0, 3.0, 0.0]

        df_miss = (;
            x = [1.0, 2.0, 3.0],
            w = Union{Missing, Float64}[1.0, missing, 3.0],
        )
        layer = data(df_miss) * mapping(:x, weights = :w) * histogram(; bins = 0:1:5)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test collect(only(pl.positional[2])) == [0.0, 1.0, 0.0, 3.0, 0.0]
    end

    @testset "Inf in inputs errors" begin
        df_x = (; x = [1.0, 2.0, Inf, 4.0])
        @test_throws "Inf`/`-Inf` value(s) in positional column 1" AlgebraOfGraphics.ProcessedLayer(
            AlgebraOfGraphics.ProcessedLayers(data(df_x) * mapping(:x) * AlgebraOfGraphics.density(; npoints = 10, datalimits = extrema)).layers[2]
        )
        @test_throws "Inf`/`-Inf` value(s) in positional column 1" AlgebraOfGraphics.ProcessedLayer(data(df_x) * mapping(:x) * histogram(; bins = 1:5))
        @test_throws "Inf`/`-Inf` value(s) in positional column 1" AlgebraOfGraphics.ProcessedLayer(data(df_x) * mapping(:x) * frequency())

        df_xy = (; x = [1.0, 2.0, 3.0, 4.0], y = [1.0, Inf, 3.0, 4.0])
        @test_throws "Inf`/`-Inf` value(s) in positional column 2" AlgebraOfGraphics.ProcessedLayers(data(df_xy) * mapping(:x, :y) * linear())
        @test_throws "Inf`/`-Inf` value(s) in positional column 2" AlgebraOfGraphics.ProcessedLayer(data(df_xy) * mapping(:x, :y) * smooth(; interval = nothing))

        df_gy = (; g = ["a", "a", "b", "b"], y = [1.0, 2.0, Inf, 4.0])
        @test_throws "Inf`/`-Inf` value(s) in positional column 2" AlgebraOfGraphics.ProcessedLayer(data(df_gy) * mapping(:g, :y) * expectation())

        df_w = (; x = [1.0, 2.0, 3.0], w = [1.0, Inf, 3.0])
        @test_throws "Inf`/`-Inf` value(s) in named column `weights`" AlgebraOfGraphics.ProcessedLayer(data(df_w) * mapping(:x, weights = :w) * histogram(; bins = 0:1:5))
    end
end

@testset "analyses with units" begin
    # Test both Unitful and DynamicQuantities to ensure both extensions handle the strip/reapply pattern.
    # The Mean aggregator's init = (0, 0.0) is not dimensionally compatible with unit-bearing values,
    # GLM/Loess/KernelDensity all require unitless inputs, and Makie's Contour/Contourf strip units
    # from positional args, so each analysis must strip units before its numeric work and reapply afterwards.
    @testset "linear" begin
        for (xunit, yunit) in [(U.u"m", U.u"kg"), (D.us"m", D.us"kg")]
            df = (; x = collect(1.0:10.0) .* xunit, y = collect(1.0:10.0) .* yunit)
            layer = data(df) * mapping(:x, :y) * linear()
            pls = AlgebraOfGraphics.ProcessedLayers(layer)
            x̂, ŷ = pls.layers[2].positional
            @test eltype(only(x̂)) == eltype(df.x)
            @test eltype(only(ŷ)) == eltype(df.y)
            @test first(only(x̂)) ≈ 1.0 * xunit
            @test last(only(x̂)) ≈ 10.0 * xunit
            # On y = x with consistent units, ŷ should track y
            @test first(only(ŷ)) ≈ 1.0 * yunit rtol = 1.0e-10
            @test last(only(ŷ)) ≈ 10.0 * yunit rtol = 1.0e-10
            # Band layer also carries y units
            lower = pls.layers[1].positional[2]
            upper = pls.layers[1].positional[3]
            @test eltype(only(lower)) == eltype(df.y)
            @test eltype(only(upper)) == eltype(df.y)
        end
    end

    @testset "smooth" begin
        for (xunit, yunit) in [(U.u"m", U.u"kg"), (D.us"m", D.us"kg")]
            df = (; x = collect(1.0:20.0) .* xunit, y = collect(1.0:20.0) .* yunit)
            layer = data(df) * mapping(:x, :y) * smooth(; interval = nothing)
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            x̂, ŷ = pl.positional
            @test eltype(only(x̂)) == eltype(df.x)
            @test eltype(only(ŷ)) == eltype(df.y)
            @test first(only(x̂)) ≈ 1.0 * xunit
            @test last(only(x̂)) ≈ 20.0 * xunit
        end
    end

    @testset "density 1D" begin
        for xunit in [U.u"m", D.us"m"]
            df = (; x = collect(1.0:10.0) .* xunit)
            layer = data(df) * mapping(:x) * AlgebraOfGraphics.density(; npoints = 50, datalimits = extrema)
            pls = AlgebraOfGraphics.ProcessedLayers(layer)
            line_pl = pls.layers[2]
            rgx, d = line_pl.positional
            @test eltype(only(rgx)) == eltype(df.x)
            @test first(only(rgx)) ≈ 1.0 * xunit
            @test last(only(rgx)) ≈ 10.0 * xunit
            # pdf values are unitless
            @test eltype(only(d)) <: Real
        end
    end

    @testset "density 2D" begin
        for (xunit, yunit) in [(U.u"m", U.u"kg"), (D.us"m", D.us"kg")]
            df = (; x = collect(1.0:10.0) .* xunit, y = collect(1.0:10.0) .* yunit)
            layer = data(df) * mapping(:x, :y) * AlgebraOfGraphics.density(; npoints = 10, bandwidth = (0.5, 0.5))
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            rgx, rgy, d = pl.positional
            @test eltype(only(rgx)) == eltype(df.x)
            @test eltype(only(rgy)) == eltype(df.y)
            @test eltype(only(d)) <: Real
        end
    end

    @testset "histogram" begin
        for xunit in [U.u"m", D.us"m"]
            df = (; x = collect(1.0:10.0) .* xunit)
            layer = data(df) * mapping(:x) * histogram(; bins = 5)
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            midpts, counts = pl.positional
            @test eltype(only(midpts)) == eltype(df.x)
            @test collect(only(counts)) == [1.0, 2.0, 2.0, 2.0, 2.0, 1.0]
            # width must be dimensionally compatible with the x axis so the BarPlot's AesDeltaX scale aligns
            width = only(pl.named[:width])
            @test eltype(width) == eltype(df.x)
            @test all(==(2.0 * xunit), width)
        end
    end

    @testset "histogram 2D" begin
        # 2D histogram returns Heatmap with midpoints on both x and y; both must keep their units.
        for (xunit, yunit) in [(U.u"m", U.u"kg"), (D.us"m", D.us"kg")]
            df = (; x = collect(1.0:10.0) .* xunit, y = collect(1.0:10.0) .* yunit)
            layer = data(df) * mapping(:x, :y) * histogram(; bins = (5, 5))
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            midx, midy, counts = pl.positional
            @test eltype(only(midx)) == eltype(df.x)
            @test eltype(only(midy)) == eltype(df.y)
            @test eltype(only(counts)) <: Real
        end
    end

    @testset "expectation 1D" begin
        for yunit in [U.u"kg", D.us"kg"]
            df = (; g = ["a", "a", "b", "b"], y = [1.0, 2.0, 3.0, 4.0] .* yunit)
            layer = data(df) * mapping(:g, :y) * expectation()
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            x, m = pl.positional
            @test only(x) == ["a", "b"]
            @test only(m) == [1.5 * yunit, 3.5 * yunit]
        end
    end

    @testset "expectation 2D" begin
        # 2D expectation outputs a matrix of group means; from_unitless_numerical must accept matrix x̂ to reapply units.
        for yunit in [U.u"kg", D.us"kg"]
            df = (;
                g1 = ["a", "a", "b", "b", "a", "b"],
                g2 = ["x", "y", "x", "y", "x", "y"],
                z = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0] .* yunit,
            )
            layer = data(df) * mapping(:g1, :g2, :z) * expectation()
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            m = only(pl.positional[3])
            @test m == [3.0 2.0; 3.0 5.0] .* yunit
        end
    end

    @testset "frequency" begin
        for xunit in [U.u"m", D.us"m"]
            df = (; x = [1.0, 1.0, 2.0, 2.0, 2.0, 3.0] .* xunit)
            layer = data(df) * mapping(:x) * frequency()
            pl = AlgebraOfGraphics.ProcessedLayer(layer)
            x, n = pl.positional
            @test only(x) == [1.0, 2.0, 3.0] .* xunit
            @test collect(only(n)) == [2, 3, 1]
        end
    end

    @testset "draw smoke" begin
        # Compute the entries grid for every unit-bearing analysis to surface scale/colorbar
        # incompatibilities that only manifest after entries -> Makie conversion.
        for (xunit, yunit) in [(U.u"m", U.u"kg"), (D.us"m", D.us"kg")]
            specs = [
                data((; x = collect(1.0:10.0) .* xunit, y = collect(1.0:10.0) .* yunit)) * mapping(:x, :y) * linear(),
                data((; x = collect(1.0:20.0) .* xunit, y = collect(1.0:20.0) .* yunit)) * mapping(:x, :y) * smooth(),
                data((; x = collect(1.0:10.0) .* xunit)) * mapping(:x) * AlgebraOfGraphics.density(; npoints = 10),
                data((; x = collect(1.0:10.0) .* xunit)) * mapping(:x) * histogram(; bins = 5),
                data((; g = ["a", "a", "b", "b"], y = [1.0, 2.0, 3.0, 4.0] .* yunit)) * mapping(:g, :y) * expectation(),
                data((; x = [1.0, 1.0, 2.0, 3.0] .* xunit)) * mapping(:x) * frequency(),
            ]
            for spec in specs
                @test AlgebraOfGraphics.compute_axes_grid(spec) isa AbstractMatrix
            end
        end
    end

    @testset "histogram weights" begin
        # Statistical weights have no physical units, but the analysis must still feed them through
        # the to_unitless_numerical / StatsBase.fweights pipeline even when x is unitful — sanity-check the
        # combined output to catch regressions in either branch.
        df = (; x = collect(1.0:6.0) .* U.u"m", w = [1.0, 2.0, 1.0, 2.0, 1.0, 2.0])
        layer = data(df) * mapping(:x, weights = :w) * histogram(; bins = 0:2.0:6.0)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        # left-closed bins [0,2): x=1 (w=1); [2,4): x=2,3 (w=2+1=3); [4,6): x=4,5 (w=2+1=3)
        @test collect(only(pl.positional[2])) == [1.0, 3.0, 3.0]
    end

    @testset "contours preserves x/y units" begin
        # The :levels attribute must be unit-stripped because it's forwarded raw to Makie.Contour
        # which already receives unit-stripped positional data via the scale system.
        x_vals = collect(1.0:5.0)
        y_vals = collect(1.0:5.0)
        z_vals = [xi + yi for xi in x_vals, yi in y_vals]
        x = repeat(x_vals, inner = 5) .* U.u"m"
        y = repeat(y_vals, outer = 5) .* U.u"kg"
        layer = data((; x, y, z = vec(z_vals) .* U.u"K")) * mapping(:x, :y, :z) * AlgebraOfGraphics.contours(; levels = 3)
        @test AlgebraOfGraphics.compute_axes_grid(layer) isa AbstractMatrix
    end

    @testset "filled_contours preserves x/y units" begin
        # Bin ranges are now parametric so legend display keeps units; xs/ys reapply units from the slice.
        x_vals = collect(1.0:5.0)
        y_vals = collect(1.0:5.0)
        z_vals = [xi + yi for xi in x_vals, yi in y_vals]
        x = repeat(x_vals, inner = 5) .* U.u"m"
        y = repeat(y_vals, outer = 5) .* U.u"kg"
        layer = data((; x, y, z = vec(z_vals) .* U.u"K")) * mapping(:x, :y, :z) * AlgebraOfGraphics.filled_contours(; bands = 3)
        @test AlgebraOfGraphics.compute_axes_grid(layer) isa AbstractMatrix
    end
end

@testset "analyses with temporal x" begin
    # `to_unitless_numerical`/`from_unitless_numerical` already existed for TimeTypes; the
    # rename and the new strip-and-reapply contract should keep their behavior intact, but we
    # didn't have direct coverage of either `linear` or `smooth` over a temporal x axis.
    @testset "linear (DateTime)" begin
        ts = DateTime(2024, 1, 1):Day(1):DateTime(2024, 1, 20)
        df = (; x = collect(ts), y = collect(1.0:20.0))
        layer = data(df) * mapping(:x, :y) * linear(; interval = nothing)
        pls = AlgebraOfGraphics.ProcessedLayers(layer)
        line_pl = pls.layers[2]
        x̂, ŷ = line_pl.positional
        @test eltype(only(x̂)) <: DateTime
        @test first(only(x̂)) == DateTime(2024, 1, 1)
        @test last(only(x̂)) == DateTime(2024, 1, 20)
        # DateTime → float roundtrip leaves a tiny epsilon, so don't pin too tightly.
        @test first(only(ŷ)) ≈ 1.0 rtol = 1.0e-6
        @test last(only(ŷ)) ≈ 20.0 rtol = 1.0e-6
    end

    @testset "smooth (Time)" begin
        ts = Time(0, 0, 0):Minute(30):Time(9, 30, 0)
        df = (; x = collect(ts), y = collect(1.0:20.0))
        layer = data(df) * mapping(:x, :y) * smooth(; interval = nothing)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        x̂, ŷ = pl.positional
        @test eltype(only(x̂)) <: Time
        @test first(only(x̂)) == Time(0, 0, 0)
        @test last(only(x̂)) == Time(9, 30, 0)
    end

    @testset "smooth (DateTime) precision" begin
        # `datetime2float(DateTime(2024,...))` is ~1.26e11, large enough that an un-centered Loess
        # fit loses precision and predicts wildly between sample points. Recentering x in
        # `SmoothAnalysis` keeps predictions monotonic for a monotone input.
        ts = DateTime(2024, 1, 1, 9, 0, 0):Second(30):DateTime(2024, 1, 1, 9, 9, 30)
        df = (; x = collect(ts), y = sqrt.(1.0:20.0))
        layer = data(df) * mapping(:x, :y) * smooth(; interval = nothing)
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        ŷ = only(pl.positional[2])
        @test all(>=(1.0), ŷ)
        @test all(<=(sqrt(20.0)), ŷ)
        @test issorted(ŷ)
    end
end

@testset "datalimits broadcast vs per-dim" begin
    # A single `(lo, hi)` is broadcast to every dim by `applydatalimits`. The unit-stripping pass
    # must preserve that shape rather than destructuring each scalar as `(lo, hi)`.
    @testset "density 1D" begin
        df = (; x = collect(0.0:0.5:10.0))
        layer = data(df) * mapping(:x) * AlgebraOfGraphics.density(npoints = 10, datalimits = (0, 8))
        pls = AlgebraOfGraphics.ProcessedLayers(layer)
        rgx = only(pls.layers[2].positional[1])
        @test first(rgx) == 0
        @test last(rgx) == 8
    end

    @testset "density 1D with Unitful" begin
        df = (; x = collect(0.0:0.5:10.0) .* U.u"m")
        layer = data(df) * mapping(:x) * AlgebraOfGraphics.density(npoints = 10, datalimits = (0 * U.u"m", 8 * U.u"m"))
        pls = AlgebraOfGraphics.ProcessedLayers(layer)
        rgx = only(pls.layers[2].positional[1])
        @test first(rgx) == 0 * U.u"m"
        @test last(rgx) == 8 * U.u"m"
    end

    @testset "histogram 1D" begin
        df = (; x = collect(1.0:6.0))
        layer = data(df) * mapping(:x) * histogram(bins = 4, datalimits = (0, 8))
        pl = AlgebraOfGraphics.ProcessedLayer(layer)
        @test only(pl.positional[1]) == [1.0, 3.0, 5.0, 7.0, 9.0]
        @test collect(only(pl.positional[2])) == [1.0, 2.0, 2.0, 1.0, 0.0]
    end
end

@testset "analyses in transformed scale space" begin
    transforms(; kwargs...) = AlgebraOfGraphics.axis_transforms_from_scales(scales(; kwargs...))
    logX = transforms(X = (; scale = log10))
    logY = transforms(Y = (; scale = log10))
    logXY = transforms(X = (; scale = log10), Y = (; scale = log10))

    fit_output(layer, tf) = AlgebraOfGraphics.ProcessedLayers(layer, tf).layers[end]

    @testset "linear recovers exponential in log-y space" begin
        df = (; x = [1.0, 2.0, 3.0, 4.0], y = [10.0, 100.0, 1000.0, 10000.0])
        layer = data(df) * mapping(:x, :y) * linear(interval = nothing)
        ll = fit_output(layer, logY)
        x̂, ŷ = only(ll.positional[1]), only(ll.positional[2])
        @test ŷ ≈ 10 .^ x̂

        ŷ_plain = only(fit_output(layer, transforms()).positional[2])
        @test !(ŷ_plain ≈ 10 .^ x̂)
    end

    @testset "linear recovers power law in log-log space" begin
        x = [1.0, 2.0, 4.0, 8.0]
        df = (; x, y = 3 .* x .^ 2)
        layer = data(df) * mapping(:x, :y) * linear(interval = nothing)
        ll = fit_output(layer, logXY)
        x̂, ŷ = only(ll.positional[1]), only(ll.positional[2])
        @test ŷ ≈ 3 .* x̂ .^ 2
    end

    @testset "smooth fits in log-y space" begin
        x = repeat(1.0:6.0, inner = 2)
        layer = data((; x, y = 10.0 .^ (0.5 .* x))) * mapping(:x, :y) * smooth(interval = nothing)
        ŷ_log = only(fit_output(layer, logY).positional[2])
        ŷ_plain = only(fit_output(layer, transforms()).positional[2])
        @test all(>(0), ŷ_log)
        @test issorted(ŷ_log)
        @test !(ŷ_log ≈ ŷ_plain)
    end

    @testset "histogram bins in log-x space" begin
        df = (; v = [1.0, 10.0, 100.0, 1000.0])
        layer = data(df) * mapping(:v) * histogram(bins = 3)
        pl_log = fit_output(layer, logX)
        @test only(pl_log.positional[1]) == [5.5, 55.0, 550.0, 5500.0]
        @test collect(only(pl_log.positional[2])) == [1.0, 1.0, 1.0, 1.0]

        pl_plain = fit_output(layer, transforms())
        @test only(pl_plain.positional[1]) == [250.0, 750.0, 1250.0]
        @test collect(only(pl_plain.positional[2])) == [3.0, 0.0, 1.0]
    end

    @testset "histogram direction = :x bins in log-y space" begin
        df = (; v = [1.0, 10.0, 100.0, 1000.0])
        layer = data(df) * mapping(:v) * histogram(bins = 3, direction = :x)
        pl_log = fit_output(layer, logY)
        @test get(pl_log.attributes, :direction, nothing) == :x
        @test pl_log.scale_assumed_aes == AlgebraOfGraphics.position_aesthetics(pl_log.plottype, pl_log.attributes, 2)
        @test only(pl_log.positional[1]) == [5.5, 55.0, 550.0, 5500.0]
        @test collect(only(pl_log.positional[2])) == [1.0, 1.0, 1.0, 1.0]

        @test compute_axes_grid(layer, scales(Y = (; scale = log10))) isa AbstractMatrix
        @test_throws "only be set for the 1-dimensional case" AlgebraOfGraphics.ProcessedLayers(
            data((; x = [1.0, 2.0, 3.0], y = [1.0, 2.0, 3.0])) * mapping(:x, :y) * histogram(bins = 2, direction = :x)
        )
    end

    @testset "expectation is the geometric mean in log-y space" begin
        df = (; g = ["a", "a", "b", "b"], y = [1.0, 100.0, 10.0, 1000.0])
        layer = data(df) * mapping(:g, :y) * expectation()
        @test only(fit_output(layer, logY).positional[2]) == [10.0, 100.0]
    end

    @testset "units compose with the scale transform" begin
        x = repeat(1.0:6.0, inner = 2)
        df = (; t = x .* U.u"hr", c = 10.0 .^ (0.2 .+ 0.3 .* x) .* U.u"mg/L")
        layer = data(df) * mapping(:t, :c) * linear(interval = nothing)
        pl = fit_output(layer, logY)
        x̂, ŷ = only(pl.positional[1]), only(pl.positional[2])
        @test eltype(x̂) == eltype(df.t)
        @test eltype(ŷ) == eltype(df.c)
        @test ŷ ≈ 10.0 .^ (0.2 .+ 0.3 .* U.ustrip.(x̂)) .* U.u"mg/L"
    end

    @testset "scale without a known inverse errors" begin
        df = (; x = [1.0, 2.0], y = [10.0, 100.0])
        layer = data(df) * mapping(:x, :y) * linear(interval = nothing)
        @test_throws "has no inverse registered with `Makie.inverse_transform`" AlgebraOfGraphics.ProcessedLayers(layer, transforms(Y = (; scale = x -> x^3)))
    end

    @testset "data outside the scale domain errors with context" begin
        lin(yvals) = data((; x = [1.0, 2.0, 3.0], y = yvals)) * mapping(:x, :y) * linear(interval = nothing)
        @test_throws "The scale function `log10` set for aesthetic `Y` is not finite at the data value `0.0`. `LinearAnalysis` fits in transformed scale space" AlgebraOfGraphics.ProcessedLayers(lin([10.0, 0.0, 100.0]), logY)
        @test_throws "not finite at the data value `-5.0`" AlgebraOfGraphics.ProcessedLayers(lin([10.0, -5.0, 100.0]), logY)
        @test_throws "`SmoothAnalysis` fits in transformed scale space" AlgebraOfGraphics.ProcessedLayers(data((; x = [1.0, 2.0, 3.0], y = [10.0, 0.0, 100.0])) * mapping(:x, :y) * smooth(interval = nothing), logY)

        xy(df) = data(df) * mapping(:x, :y) * linear(interval = nothing)
        @test_throws "aesthetic `X`" AlgebraOfGraphics.ProcessedLayers(xy((; x = [1.0, 0.0, 3.0], y = [10.0, 20.0, 30.0])), logXY)
        @test_throws "aesthetic `Y`" AlgebraOfGraphics.ProcessedLayers(xy((; x = [1.0, 2.0, 3.0], y = [10.0, 0.0, 30.0])), logXY)
    end

    @testset "guard catches a downstream aesthetic flip onto a scaled axis" begin
        df = (; v = [1.0, 10.0, 100.0, 1000.0, 10.0, 100.0, 50.0, 5.0])
        spec = data(df) * mapping(:v) * histogram(bins = 3) * visual(direction = :x)
        @test_throws "altered the aesthetic mapping" compute_axes_grid(spec, scales(Y = (; scale = log10)))
    end

    @testset "aesthetic-preserving downstream changes do not fire the guard" begin
        df = (; x = [1.0, 2.0, 3.0, 4.0], y = [10.0, 100.0, 1000.0, 10000.0])
        base = data(df) * mapping(:x, :y)
        @test compute_axes_grid(base * smooth(interval = nothing) * visual(Scatter), scales(Y = (; scale = log10))) isa AbstractMatrix
        @test compute_axes_grid(base * linear(interval = nothing) * visual(color = :red), scales(Y = (; scale = log10))) isa AbstractMatrix
    end
end
