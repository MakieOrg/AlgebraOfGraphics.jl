@testset "visual attributes" begin
    attrs = NamedArguments([:color, :marker], ["red", :circle])
    pl = ProcessedLayer(attributes=attrs)
    v = visual(Any, color="blue", linewidth=2)
    pl′ = v.transformation(pl)
    @test pl′.plottype === Plot{plot}
    collect(keys(pl′.attributes)) == [:color, :marker, :linewidth]
    pl′.attributes[:color] == "blue"
    pl′.attributes[:marker] == :circle
    pl′.attributes[:linewidth] == 2
end

@testset "visual plottype" begin
    @test visual(Any).transformation.plottype === Plot{plot}
    @test visual(Plot{plot}).transformation.plottype === Plot{plot}

    v1, v2 = visual(), visual(BarPlot)
    pl1, pl2 = ProcessedLayer(), ProcessedLayer(plottype=Scatter)

    @test v1.transformation.plottype === Plot{plot}
    @test v2.transformation.plottype === BarPlot
    @test pl1.plottype === Plot{plot}
    @test pl2.plottype === Scatter

    @test v1.transformation(pl1).plottype === Plot{plot}
    @test v1.transformation(pl2).plottype === Scatter
    @test v2.transformation(pl1).plottype === BarPlot
    @test v2.transformation(pl2).plottype === BarPlot
end