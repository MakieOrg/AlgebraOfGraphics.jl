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
end