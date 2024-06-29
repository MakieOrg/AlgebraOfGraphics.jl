@testset "scales" begin
    l = data([(x = 1, subject = "c"), (x = 2, subject = "a")]) * mapping(:x, :subject)
    pl = ProcessedLayer(l)
    aesmapping = AlgebraOfGraphics.aesthetic_mapping(pl)
    scales = map(fitscale, categoricalscales(pl, Dictionary{Type{<:AlgebraOfGraphics.Aesthetic},Any}(), aesmapping))
    @test keys(scales) == Indices([2])
    scale = scales[2]
    @test scale isa CategoricalScale
    @test scale.data == ["a", "c"]
    @test scale.label == "subject"
    @test scale.plot == 1:2

    l = data([(x = 1, subject = "c", grp="f"), (x = 2, subject = "a", grp="g")]) *
        mapping(:x, :subject, color=:grp)
    pl = ProcessedLayer(l)
    aesmapping = AlgebraOfGraphics.aesthetic_mapping(pl)
    scaleprops = AlgebraOfGraphics.compute_scale_properties(
        [pl], AlgebraOfGraphics._kwdict(
            (; Color = AlgebraOfGraphics._kwdict(
                (; palette = ["red", "blue", "green"], categories = ["g", "f"])
            ))
        )
    )

    scales = map(fitscale, categoricalscales(pl, scaleprops, aesmapping))
    @test keys(scales) == Indices([:color, 2])
    scale = scales[:color]
    @test scale isa CategoricalScale
    @test scale.data == ["f", "g"]
    @test datavalues(scale) == ["g", "f"]
    @test scale.label == "grp"
    @test scale.plot == ["red", "blue"]
    scale = scales[2]
    @test scale isa CategoricalScale
    @test scale.data == ["a", "c"]
    @test scale.label == "subject"
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

@testset "Aesthetics switch via visual attribute" begin
    spec = data((; x = ["A", "B", "C"], y = 1:3)) * mapping(:x, :y) * visual(BarPlot)
    ag1 = compute_axes_grid(spec)
    @test ag1[].axis.attributes[:xlabel] == "x"
    @test ag1[].axis.attributes[:xticks] == (1:3, ["A", "B", "C"])
    @test ag1[].axis.attributes[:yticks] == Makie.automatic
    @test ag1[].axis.attributes[:ylabel] == "y"

    @test only(keys(ag1[].categoricalscales)) == AlgebraOfGraphics.AesX
    @test only(keys(ag1[].continuousscales)) == AlgebraOfGraphics.AesY

    spec2 = spec * visual(direction = :x)
    ag2 = compute_axes_grid(spec2)
    @test ag2[].axis.attributes[:xlabel] == "y"
    @test ag2[].axis.attributes[:xticks] == Makie.automatic
    @test ag2[].axis.attributes[:yticks] == (1:3, ["A", "B", "C"])
    @test ag2[].axis.attributes[:ylabel] == "x"

    @test only(keys(ag2[].categoricalscales)) == AlgebraOfGraphics.AesY
    @test only(keys(ag2[].continuousscales)) == AlgebraOfGraphics.AesX

    spec3 = spec * visual(direction = :unknown)
    @test_throws_message "no entry for attribute :direction with value :unknown" compute_axes_grid(spec3)
end

@testset "Combined and split scales" begin
    spec1 = data((; x = 1:3, y = 1:3, c = ["A", "B", "C"])) * mapping(:x, :y, strokecolor = :c) * visual(Scatter)
    spec2 = data((; x = 4:5, y = 4:5, c = ["D", "D"])) * mapping(:x, :y, color = :c) * visual(Lines)
    ag1 = compute_axes_grid(spec1 + spec2)
    @test only(keys(ag1[].categoricalscales)) == AlgebraOfGraphics.AesColor
    @test only(keys(ag1[].categoricalscales[AlgebraOfGraphics.AesColor])) === nothing
    @test datavalues(ag1[].categoricalscales[AlgebraOfGraphics.AesColor][nothing]) == ["A", "B", "C", "D"]

    f = Figure()
    axisentries = AlgebraOfGraphics.AxisEntries.(ag1, Ref(f))
    leg_els, el_labels, group_labels = AlgebraOfGraphics.compute_legend(axisentries, order = nothing)
    @test length(leg_els) == 1
    @test length(leg_els[]) == 4
    
    ag2 = compute_axes_grid(spec1 + spec2 * mapping(color = :c => scale(:color2)))
    @test only(keys(ag2[].categoricalscales)) == AlgebraOfGraphics.AesColor
    dict = ag2[].categoricalscales[AlgebraOfGraphics.AesColor]
    @test Set(keys(dict)) == Set([nothing, :color2])
    @test datavalues(dict[nothing]) == ["A", "B", "C"]
    @test datavalues(dict[:color2]) == ["D"]

    f = Figure()
    axisentries2 = AlgebraOfGraphics.AxisEntries.(ag2, Ref(f))
    leg_els, el_labels, group_labels = AlgebraOfGraphics.compute_legend(axisentries2, order = nothing)
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 1
end

@testset "Invalid scale settings" begin
    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z) * visual(Lines)
    @test_throws_message "Got scale :cccolor in scale properties but this key" draw(spec, scales = (; cccolor = (; colormap = :Blues)))

    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z) * visual(Lines)
    @test_throws_message "Got scale properties for :Marker but no scale of this kind is mapped" draw(spec, scales = (; Marker = (; palette = ['x', 'y', 'z'])))

    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z => nonnumeric) * visual(Scatter)
    @test_throws_message "Unknown scale attribute :unknown for categorical scale" draw(spec, scales = (; Color = (; unknown = false)))
end

@testset "Removed palette keyword" begin
    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z) * visual(Lines)
    @test_throws_message "The `palette` keyword for `draw` and `draw!` has been removed" draw(spec; palette = (; color = [:red, :green, :blue]))
    f = Figure()
    @test_throws_message "The `palette` keyword for `draw` and `draw!` has been removed" draw!(f[1, 1], spec; palette = (; color = [:red, :green, :blue]))
end
