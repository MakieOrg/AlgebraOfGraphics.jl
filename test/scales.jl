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

@testset "palettes" begin
    p = Any[:circle, :utriangle, :cross, :rect, :diamond, :dtriangle, :pentagon, :xcross, Pair{Any, Any}(:spike, :cross), Pair{Any, Any}(:seizure, :diamond)]
    uv = ["seizure", :seizure, "something?!", :something, "spike"]
    @test apply_palette(p, uv) == [:circle, :diamond, :utriangle, :cross, :rect]

    p = [:a => :circle, :b => :utriangle]
    uv = [:a, :b, :c]
    @test_throws ArgumentError apply_palette(p, uv)

    p = [:dtriangle, :b => :utriangle, :a => :circle, :cross]
    uv = [:a, :b, :c, :d, :e]
    @test apply_palette(p, uv) == [:circle, :utriangle, :dtriangle, :cross, :dtriangle]

    p = [:dtriangle, :b => :utriangle, :a => :circle]
    uv = [:a, :b, :c, :d, :e]
    @test apply_palette(p, uv) == [:circle, :utriangle, :dtriangle, :dtriangle, :dtriangle]

    p = cgrad(:Accent_3)
    uv = [:a, :b, :c, :d, :e]
    @test apply_palette(p, uv) == [p[1], p[2], p[3], p[1], p[2]]
end
