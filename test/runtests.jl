using AlgebraOfGraphics, Test
using AlgebraOfGraphics: table, data, metadata, primary, mixedtuple, traces, group, rankdicts

using RDatasets: dataset

@testset "lazy spec" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = metadata(color = :red, font = 10) + data(markersize = :Year)
    res = mpg |> table |> s |> spec |> group |> collect
    @test res[1].metadata == mixedtuple(color = :red, font = 10)
    @test res[2].metadata == mixedtuple()
    idx1 = mpg.Year .== 1999
    idx2 = mpg.Year .== 2008
    @test res[1].data[1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[1].data[2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test res[2].data[1].args == tuple(mpg[idx1, :Cyl], mpg[idx1, :Hwy])
    @test res[2].data[2].args == tuple(mpg[idx2, :Cyl], mpg[idx2, :Hwy])
    @test res[1].data[1].kwargs == NamedTuple()
    @test res[2].data[1].kwargs == (; markersize = mpg[idx1, :Year])
    @test res[2].data[2].kwargs == (; markersize = mpg[idx2, :Year])
    @test length(res) == 2
end

@testset "rankdicts" begin
    mpg = dataset("ggplot2", "mpg")
    spec = data(:Cyl, :Hwy) |> primary(color = :Year)
    s = metadata(color = :red, font = 10) + data(markersize = :Year)
    res = mpg |> table |> s |> spec |> group
    @test rankdicts(res)[:color][2008] == 2
    @test rankdicts(res)[:color][1999] == 1
end
