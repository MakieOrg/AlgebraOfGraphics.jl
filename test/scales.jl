@testset "scales" begin
    l = data([(x = 1, subject = "c"), (x = 2, subject = "a")]) * mapping(:x, :subject)
    pl = ProcessedLayer(l)
    aesmapping = AlgebraOfGraphics.aesthetic_mapping(pl)
    scales = map(fitscale, categoricalscales(pl, Dictionary{Type{<:AlgebraOfGraphics.Aesthetic}, Any}(), aesmapping))
    @test keys(scales) == Indices([2])
    scale = scales[2]
    @test scale isa CategoricalScale
    @test scale.data == ["a", "c"]
    @test scale.label == "subject"
    @test scale.plot == 1:2

    l = data([(x = 1, subject = "c", grp = "f"), (x = 2, subject = "a", grp = "g")]) *
        mapping(:x, :subject, color = :grp)
    pl = ProcessedLayer(l)
    aesmapping = AlgebraOfGraphics.aesthetic_mapping(pl)
    scaleprops = AlgebraOfGraphics.compute_scale_properties(
        [pl], AlgebraOfGraphics.scales(Color = (; palette = ["red", "blue", "green"], categories = ["g", "f"]))
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

    uv = 1:9
    @test apply_palette(wrapped(), uv) == [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3)]
    @test apply_palette(wrapped(by_col = true), uv) == [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3), (3, 3)]
    @test apply_palette(wrapped(cols = 4), uv) == [(1, 1), (1, 2), (1, 3), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4), (3, 1)]
    @test apply_palette(wrapped(cols = 4, by_col = true), uv) == [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3), (3, 3)]
    @test apply_palette(wrapped(rows = 4), uv) == [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3)]
    @test apply_palette(wrapped(rows = 4, by_col = true), uv) == [(1, 1), (2, 1), (3, 1), (4, 1), (1, 2), (2, 2), (3, 2), (4, 2), (1, 3)]
    @test_throws_message "`cols` and `rows` can't both be fixed" apply_palette(wrapped(rows = 4, cols = 5), uv)
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
    @test labels == ["1", "3", "5"]
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
    @test_throws_message "Got scale :cccolor in scale properties but this key" draw(spec, scales(cccolor = (; colormap = :Blues)))

    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z) * visual(Lines)
    @test_throws_message "Got scale properties for :Marker but no scale of this kind is mapped" draw(spec, scales(Marker = (; palette = ['x', 'y', 'z'])))

    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z => nonnumeric) * visual(Scatter)
    @test_throws_message "Unknown scale attribute :unknown for categorical scale" draw(spec, scales(Color = (; unknown = false)))
end

@testset "Removed palette keyword" begin
    spec = data((; x = 1:10, y = 1:10, z = 1:10)) *
        mapping(:x, :y, color = :z) * visual(Lines)
    @test_throws_message "The `palette` keyword for `draw` and `draw!` has been removed" draw(spec; palette = (; color = [:red, :green, :blue]))
    f = Figure()
    @test_throws_message "The `palette` keyword for `draw` and `draw!` has been removed" draw!(f[1, 1], spec; palette = (; color = [:red, :green, :blue]))
end

@testset "Natural sorting" begin
    l = mapping(["Id 100", "Id 1", "Id 10", "Id 21", "Id 2"])

    pl = ProcessedLayer(l)
    aesmapping = AlgebraOfGraphics.aesthetic_mapping(pl)
    scales = map(fitscale, categoricalscales(pl, Dictionary{Type{<:AlgebraOfGraphics.Aesthetic}, Any}(), aesmapping))
    @test keys(scales) == Indices([1])
    scale = scales[1]
    @test scale isa CategoricalScale
    @test scale.data == ["Id 1", "Id 2", "Id 10", "Id 21", "Id 100"]

    @test sort(["1", "10", "2"]) == ["1", "10", "2"]
    @test sort(["1", "10", "2"], lt = AlgebraOfGraphics.natural_lt) == ["1", "2", "10"]

    @test sort([("1", 1), ("10", 2), ("2", 3)]) == [("1", 1), ("10", 2), ("2", 3)]
    @test sort([("1", 1), ("10", 2), ("2", 3)], lt = AlgebraOfGraphics.natural_lt) == [("1", 1), ("2", 3), ("10", 2)]
end

if VERSION >= v"1.9"
    @testset "Units" begin
        spec = data((; x1 = (1:10) .* D.us"m", x2 = (1:10) .* D.us"kg", y = 1:10)) * (mapping(:x1, :y) + mapping(:x2, :y)) * visual(Scatter)
        @test_throws_message "Merging the extrema of two subscales of the continuous scale X failed" draw(spec)
        spec = data((; x1 = (1:10) .* U.u"m", x2 = (1:10) .* U.u"kg", y = 1:10)) * (mapping(:x1, :y) + mapping(:x2, :y)) * visual(Scatter)
        @test_throws_message "Merging the extrema of two subscales of the continuous scale X failed"  draw(spec)

        for (xunit, yunit, xoverride, yoverride) in [(D.us"m", D.us"kg", D.us"cm", D.us"g"), (U.u"m", U.u"kg", U.u"cm", U.u"g")]
            spec = data((; x = (1:10) .* xunit, y = (11:20) .* yunit)) * mapping(:x, :y) * visual(Scatter)
            fg = draw(spec)
            xscale = fg.grid[].continuousscales[AlgebraOfGraphics.AesX][nothing]
            @test AlgebraOfGraphics.getunit(xscale) == xunit
            yscale = fg.grid[].continuousscales[AlgebraOfGraphics.AesY][nothing]
            @test AlgebraOfGraphics.getunit(yscale) == yunit

            fg2 = draw(spec, scales(X = (; unit = xoverride), Y = (; unit = yoverride)))
            xscale = fg2.grid[].continuousscales[AlgebraOfGraphics.AesX][nothing]
            @test AlgebraOfGraphics.getunit(xscale) == xoverride
            yscale = fg2.grid[].continuousscales[AlgebraOfGraphics.AesY][nothing]
            @test AlgebraOfGraphics.getunit(yscale) == yoverride
        end

        @test AlgebraOfGraphics.dimensionally_compatible(nothing, nothing)
        @test !AlgebraOfGraphics.dimensionally_compatible(U.u"kg", nothing)
        @test !AlgebraOfGraphics.dimensionally_compatible(nothing, U.u"kg")
        @test !AlgebraOfGraphics.dimensionally_compatible(D.us"kg", nothing)
        @test !AlgebraOfGraphics.dimensionally_compatible(nothing, D.us"kg")
        @test !AlgebraOfGraphics.dimensionally_compatible(D.u"kg", nothing)
        @test !AlgebraOfGraphics.dimensionally_compatible(nothing, D.u"kg")

        @test !AlgebraOfGraphics.dimensionally_compatible(U.u"kg", U.u"m")
        @test AlgebraOfGraphics.dimensionally_compatible(U.u"kg", U.u"g")

        @test !AlgebraOfGraphics.dimensionally_compatible(D.u"kg", D.u"m")
        @test !AlgebraOfGraphics.dimensionally_compatible(D.us"kg", D.us"m")
        @test !AlgebraOfGraphics.dimensionally_compatible(D.u"kg", D.us"m")
        @test !AlgebraOfGraphics.dimensionally_compatible(D.us"kg", D.u"m")
        @test AlgebraOfGraphics.dimensionally_compatible(D.u"kg", D.us"g")
        @test AlgebraOfGraphics.dimensionally_compatible(D.us"kg", D.u"g")

        @test_throws_message "incompatible dimensions for AesX and AesDeltaX scales" draw(data((; id = 1:3, value = [1, 2, 3] .* U.u"m", err = [0.5, 0.6, 0.7] .* U.u"kg")) * mapping(:value, :id, :err) * visual(Errorbars, direction = :x))
        @test_throws_message "incompatible dimensions for AesY and AesDeltaY scales" draw(data((; id = 1:3, value = [1, 2, 3] .* U.u"m", err = [0.5, 0.6, 0.7] .* U.u"kg")) * mapping(:id, :value, :err) * visual(Errorbars))
    end

    @testset "Incompatible extrema in continuous scales" begin
        @test_throws_message "Merging the extrema of two subscales of the continuous scale Y failed" (mapping([1]) + mapping([1 * U.u"kg"])) * visual(Scatter) |> draw
    end
end

if VERSION >= v"1.7"
    @testset "Aesthetics errors" begin
        @test_throws "No aesthetic mapping defined yet for plot type `Errorbars` with 1 positional argument" mapping(1:10) * visual(Errorbars) |> draw
        @test_throws "contains mapped attribute `alpha` which is not part of the aesthetic mapping for `Scatter`" mapping(1:10, alpha = 1:10) * visual(Scatter) |> draw
    end
end
