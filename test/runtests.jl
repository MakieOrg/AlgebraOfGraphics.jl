using AlgebraOfGraphics, Test
using AlgebraOfGraphics: data, metadata, primary, mixedtuple

using RDatasets: dataset

@testset "traces" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) * primary(color = :Year)
    s = metadata(color = :red, font = 10) + data(markersize = :Year)
    res = mpg |> s * spec
    @test res[1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2].metadata == mixedtuple()
    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008
    @test res[1].data[1].args == Tuple(eachcol(mpg[idx1, [:Cyl, :Hwy]]))
    @test res[1].data[2].args == Tuple(eachcol(mpg[idx2, [:Cyl, :Hwy]]))
    @test res[2].data[1].args == Tuple(eachcol(mpg[idx1, [:Cyl, :Hwy]]))
    @test res[2].data[2].args == Tuple(eachcol(mpg[idx2, [:Cyl, :Hwy]]))
    @test res[1].data[1].kwargs == NamedTuple()
    @test res[2].data[1].kwargs == (; markersize = mpg[idx1, :Year])
    @test res[2].data[2].kwargs == (; markersize = mpg[idx2, :Year])
    @test length(res) == 2

    # v1, v2 = (rand(10), rand(10))
    # p = Traces(counter(:color), (v1, v2))
    # a, s = first(p)
    # @test a == (; color = 1)
    # @test s == Select(v1)
    # a, s = last(collect(p))
    # @test a == (; color = 2)
    # @test s == Select(v2)

end
