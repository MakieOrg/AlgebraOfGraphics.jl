using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, metadata, primary, analysis, mixedtuple
using OrderedCollections

using RDatasets: dataset

@testset "traces" begin
    mpg = dataset("ggplot2", "mpg")
    spec = table(mpg) * data(:Cyl, :Hwy) * primary(color = :Year)
    s = metadata(color = :red, font = 10) + data(markersize = :Year)
    res = collect(s * spec)
    @test res[1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2].metadata == mixedtuple()
    @test res[1].data == mixedtuple(:Cyl, :Hwy)
    @test res[2].data == mixedtuple(:Cyl, :Hwy, markersize = :Year)
    @test res[1].table == mpg
    @test res[2].table == mpg
    @test length(res) == 2

    
    OrderedDict(res[1])
    # v1, v2 = (rand(10), rand(10))
    # p = Traces(counter(:color), (v1, v2))
    # a, s = first(p)
    # @test a == (; color = 1)
    # @test s == Select(v1)
    # a, s = last(collect(p))
    # @test a == (; color = 2)
    # @test s == Select(v2)

end
