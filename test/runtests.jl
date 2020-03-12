using AlgebraOfGraphics, Test
using AlgebraOfGraphics: Data, Select, Group, Analysis, Trace, traces, ⊗, ⊕
using RDatasets: dataset

@testset "select" begin
    mpg = dataset("ggplot2", "mpg")
    spec = Data(mpg) ⊗ Select(:Cyl, :Hwy) ⊗ Group(color = :Year)
    s = log ⊕ exp
    ts = traces(s, spec)
    @test eltype(ts) <: Vector{<:Trace}
    @test length(ts) == 2

    ts1 = traces(Data(mpg), Select(:Cyl, :Hwy), Group(color=:Year))
    ts2 = traces(Data(mpg) ⊗ Select(:Cyl, :Hwy) ⊗ Group(color=:Year))
    @test ts1[1].attributes == ts2[1].attributes
    @test ts1[1].select.args == ts2[1].select.args
    @test ts1[1].select.kwargs == ts2[1].select.kwargs
end
