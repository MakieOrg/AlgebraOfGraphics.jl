@testset "scales" begin
    l = data([(x = 1, subject = "c"), (x = 2, subject = "a")]) * mapping(:x, :subject)
    pl = ProcessedLayer(l)
    palettes = compute_palettes((;))
    scales = map(fitscale, categoricalscales(pl, palettes))
    @test keys(scales) == Indices([2])
    scale = scales[2]
    @test scale isa CategoricalScale
    @test scale.data == ["a", "c"]
    @test scale.label == "subject"
    @test scale.palette === automatic
    @test scale.plot == 1:2

    l = data([(x = 1, subject = "c", grp="f"), (x = 2, subject = "a", grp="g")]) *
        mapping(:x, :subject, color=:grp)
    pl = ProcessedLayer(l)
    palettes = compute_palettes((; color=["g" => "red", "blue", "green"]))
    scales = map(fitscale, categoricalscales(pl, palettes))
    @test keys(scales) == Indices([:color, 2])
    scale = scales[:color]
    @test scale isa CategoricalScale
    @test scale.data == ["f", "g"]
    @test scale.label == "grp"
    @test scale.palette == ["g" => "red", "blue", "green"]
    @test scale.plot == ["blue", "red"]
    scale = scales[2]
    @test scale isa CategoricalScale
    @test scale.data == ["a", "c"]
    @test scale.label == "subject"
    @test scale.palette === automatic
    @test scale.plot == 1:2
end