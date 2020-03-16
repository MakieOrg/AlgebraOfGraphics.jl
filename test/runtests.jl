using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Data,
                         Select,
                         Group,
                         Analysis,
                         Counter,
                         AbstractElement

using RDatasets: dataset

@testset "traces" begin
    mpg = dataset("ggplot2", "mpg")
    spec = Data(mpg) * Select(:Cyl, :Hwy) * Group(color = :Year)
    s = Select((color = :red, font = 10)) + Select(marker = :Year)
    s * spec
    @test ms[1] == (Metadata(log),)
    @test ms[2] == (Metadata(exp),)
    @test ts isa Vector{<:Traces}
    @test length(ts) == 2

    v1, v2 = (rand(10), rand(10))
    p = Traces(counter(:color), (v1, v2))
    a, s = first(p)
    @test a == (; color = 1)
    @test s == Select(v1)
    a, s = last(collect(p))
    @test a == (; color = 2)
    @test s == Select(v2)

end
