using AlgebraOfGraphics, Test
using AlgebraOfGraphics: data, metadata, primary, mixedtuple, traces

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) * primary(color = :Year)
    s = metadata(color = :red, font = 10) + data(markersize = :Year)
    res = mpg |> s * spec |> collect
    @test res[1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2].metadata == mixedtuple(color = :red, font = 10)
    @test res[3].metadata == mixedtuple()
    @test res[4].metadata == mixedtuple()
    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008
    @test res[1].data.args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[2].data.args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test res[3].data.args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[4].data.args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test res[1].data.kwargs == NamedTuple()
    @test res[3].data.kwargs == (; markersize = mpg[idx1, :Year])
    @test res[4].data.kwargs == (; markersize = mpg[idx2, :Year])
    @test length(res) == 4
end

# v1, v2 = (rand(10), rand(10))
# p = Traces(counter(:color), (v1, v2))
# a, s = first(p)
# @test a == (; color = 1)
# @test s == Select(v1)
# a, s = last(collect(p))
# @test a == (; color = 2)
# @test s == Select(v2)

