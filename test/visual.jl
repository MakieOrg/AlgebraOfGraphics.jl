@testset "visual attributes" begin
    attrs = NamedArguments([:color, :marker], ["red", :circle])
    pl = ProcessedLayer(attributes = attrs)
    v = visual(Any, color = "blue", linewidth = 2)
    pl′ = v.transformation(pl)
    @test pl′.plottype === Plot{plot}
    @test collect(keys(pl′.attributes)) == [:color, :marker, :linewidth]
    @test pl′.attributes[:color] == "blue"
    @test pl′.attributes[:marker] == :circle
    @test pl′.attributes[:linewidth] == 2
end

@testset "visual plottype" begin
    @test visual(Any).transformation.plottype === Plot{plot}
    @test visual(Plot{plot}).transformation.plottype === Plot{plot}

    v1, v2 = visual(), visual(BarPlot)
    pl1, pl2 = ProcessedLayer(), ProcessedLayer(plottype = Scatter)

    @test v1.transformation.plottype === Plot{plot}
    @test v2.transformation.plottype === BarPlot
    @test pl1.plottype === Plot{plot}
    @test pl2.plottype === Scatter

    @test v1.transformation(pl1).plottype === Plot{plot}
    @test v1.transformation(pl2).plottype === Scatter
    @test v2.transformation(pl1).plottype === BarPlot
    @test v2.transformation(pl2).plottype === BarPlot
end

@testset "subvisual target errors" begin
    # Test error when symbol target doesn't match in ProcessedLayers
    layer1 = ProcessedLayer(plottype = Lines, label = :line)
    layer2 = ProcessedLayer(plottype = Band, label = :area)
    layers = ProcessedLayers([layer1, layer2])
    
    sv = subvisual(:wrong_label, color = "red")
    @test_throws "subvisual target :wrong_label did not match any layer in ProcessedLayers. Available labels are :line and :area, available plottypes are Lines and Band" sv.transformation(layers)
    
    # Test error when type target doesn't match in ProcessedLayers
    sv_type = subvisual(Scatter, color = "blue")
    @test_throws "subvisual target Scatter did not match any layer" sv_type.transformation(layers)
    
    # Test successful match with symbol
    sv_match = subvisual(:line, color = "green")
    result = sv_match.transformation(layers)
    @test result.layers[1].attributes[:color] == "green"
    @test !haskey(result.layers[2].attributes, :color)
    
    # Test successful match with type
    sv_type_match = subvisual(Lines, linewidth = 3)
    result2 = sv_type_match.transformation(layers)
    @test result2.layers[1].attributes[:linewidth] == 3
    @test !haskey(result2.layers[2].attributes, :linewidth)
end
