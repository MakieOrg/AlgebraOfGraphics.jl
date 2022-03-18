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

@testset "extrema" begin
    v = [1, missing, 2, NaN]
    @test extrema_finite(v) == (1, 2)
    v = rand(100)
    @test extrema_finite(v) == extrema(v)

    vs = [[1, missing, 2, NaN], [-3, 1, Inf], [0.4, -12]]
    @test nested_extrema_finite(vs) == (-12, 2)
    vs = [rand(100) for _ in 1:100]
    @test nested_extrema_finite(vs) == extrema(Iterators.flatten(vs))
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

@testset "datetimes" begin
    for d in [Date(2011, 9, 1), Date(2032, 5, 7), DateTime(2033, 9, 1, 3, 14, 16)]
        @test Millisecond(datetime2float(d)) + DateTime(2020, 1, 1) == d
    end
    floats, labels = AlgebraOfGraphics.ticks((Date(2021, 5, 1), Date(2021, 9, 1)))
    @test labels == ["2021-05-01", "2021-06-01", "2021-07-01", "2021-08-01", "2021-09-01"]
    @test floats == datetime2float.(Date.(labels))

    floats, labels = AlgebraOfGraphics.ticks((DateTime(2022, 1, 2, 1, 1, 5), DateTime(2022, 1, 2, 16, 4, 28)))
    full_labels = ["2022-01-02T02:00:00", "2022-01-02T05:00:00", "2022-01-02T08:00:00", "2022-01-02T11:00:00", "2022-01-02T14:00:00"]
    @test labels == ["02:00:00", "05:00:00", "08:00:00", "11:00:00", "14:00:00"]
    @test floats == datetime2float.(DateTime.(full_labels))
    
    floats, labels = AlgebraOfGraphics.ticks((DateTime(2022, 1, 2, 1, 1, 5), DateTime(2022, 1, 2, 1, 1, 5)))
    full_labels = ["2022-01-02T01:01:05"]
    @test labels == ["01:01:05"]
    @test floats == datetime2float.(DateTime.(full_labels))

    floats, labels = AlgebraOfGraphics.ticks((Time(1, 1, 5), Time(16, 4, 28)))
    @test labels == ["02:00:00", "05:00:00", "08:00:00", "11:00:00", "14:00:00"]
    @test floats == datetime2float.(Time.(labels))

    floats, labels = AlgebraOfGraphics.ticks((DateTime(2022, 1, 2, 1, 1, 5), DateTime(2022, 1, 3, 16, 4, 28)))
    @test labels == ["2022-01-02T02:00:00", "2022-01-02T10:00:00", "2022-01-02T18:00:00", "2022-01-03T02:00:00", "2022-01-03T10:00:00"]
    @test floats == datetime2float.(DateTime.(labels))

    floats, labels = datetimeticks(month, [Date(2022, 1, 1), Date(2022, 3, 1), Date(2022, 5, 1)])
    @test labels == ["1", "3",  "5"]
    @test floats == datetime2float.([Date(2022, 1, 1), Date(2022, 3, 1), Date(2022, 5, 1)])

    floats, labels = datetimeticks([Date(2022, 1, 1), Date(2022, 3, 1), Date(2022, 5, 1)], ["January", "March", "May"])
    @test labels == ["January", "March", "May"]
    @test floats == datetime2float.([Date(2022, 1, 1), Date(2022, 3, 1), Date(2022, 5, 1)])
end