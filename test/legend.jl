function _compute_legend(spec; scales = scales(), order = nothing, hide_unused = true)
    axisgrid = compute_axes_grid(spec, scales)
    figure = Figure()
    axisentries = AlgebraOfGraphics.AxisEntries.(axisgrid, Ref(figure))
    return AlgebraOfGraphics.compute_legend(axisentries; order, hide_unused)
end

@testset "Merged Legend" begin
    base = data((; x = 1:3, y = 4:6, z = ["A", "B", "C"])) * visual(Scatter)
    spec1 = base * mapping(:x, :y, color = :z, marker = :z)
    leg_els, el_labels, group_labels = _compute_legend(spec1)
    @test length(leg_els) == 1
    @test length(leg_els[]) == 3
    @test group_labels[] == "z"

    leg_els, el_labels, group_labels = _compute_legend(spec1, order = [:Color, :Marker])
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 3
    @test group_labels[1] == "z"
    @test group_labels[2] == "z"

    leg_els, el_labels, group_labels = _compute_legend(spec1, order = [(:Color, :Marker)])
    @test length(leg_els) == 1
    @test length(leg_els[]) == 3
    @test group_labels[] == "z"

    spec2 = base * mapping(:x, :y, color = :z, marker = :z => "Renamed")
    leg_els, el_labels, group_labels = _compute_legend(spec2)
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 3
    @test group_labels[1] == "z"
    @test group_labels[2] == "Renamed"

    leg_els, el_labels, group_labels = _compute_legend(spec2, order = [(:Color, :Marker)])
    @test length(leg_els) == 1
    @test length(leg_els[]) == 3
    @test group_labels[] === nothing
end

@testset "Legend order" begin
    base = data((; x = 1:3, y = 1:3, g1 = ["A", "B", "C"], g2 = ["D", "E", "F"])) * visual(Scatter) * mapping(:x, :y)
    spec1 = base * mapping(color = :g1, marker = :g2)
    leg_els, el_labels, group_labels = _compute_legend(spec1)
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 3
    @test group_labels == ["g1", "g2"]

    spec2 = base * mapping(marker = :g2, color = :g1)
    leg_els, el_labels, group_labels = _compute_legend(spec2)
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 3
    @test group_labels == ["g2", "g1"]

    leg_els, el_labels, group_labels = _compute_legend(spec2, order = [:Color, :Marker])
    @test length(leg_els) == 2
    @test length(leg_els[1]) == 3
    @test length(leg_els[2]) == 3
    @test group_labels == ["g1", "g2"]

    leg_els, el_labels, group_labels = _compute_legend(spec2, order = [[:Color, :Marker]])
    @test length(leg_els) == 1
    @test length(leg_els[]) == 6
    @test group_labels[] === nothing

    leg_els, el_labels, group_labels = _compute_legend(spec2, order = [[:Color, :Marker] => "Title"])
    @test length(leg_els) == 1
    @test length(leg_els[]) == 6
    @test group_labels[] === "Title"

    @test_throws_message "Got passed scales :Color and :Marker as a mergeable legend group but their data values don't match" _compute_legend(spec2, order = [(:Color, :Marker)])
end

@testset "Empty legend" begin
    spec1 = data((; x = 1:3, y = 4:6)) * mapping(:x, :y) * visual(Scatter)
    @test _compute_legend(spec1) === nothing
end

@testset "Scale properties" begin
    df = (; x = 1:3, y = 1:3, g1 = ["A", "B", "C"], g2 = ["D", "E", "F"])
    spec1 = data(df) * mapping(:x, :y, color = :g1, marker = :g2) * visual(Scatter)

    leg_els, el_labels, group_labels = _compute_legend(spec1)
    @test length(leg_els) == 2
    @test group_labels == ["g1", "g2"]

    leg_els, el_labels, group_labels = _compute_legend(spec1, scales = scales(Color = (; legend = false)))
    @test length(leg_els) == 1
    @test group_labels == ["g2"]

    leg_els, el_labels, group_labels = _compute_legend(spec1, scales = scales(Color = (; label = "Color"), Marker = (; label = "Marker")))
    @test length(leg_els) == 2
    @test group_labels == ["Color", "Marker"]

    spec2 = data(df) * mapping(:x, :y, color = :g1) * visual(Scatter)
    leg_els, el_labels, group_labels = _compute_legend(spec2)
    @test length(leg_els) == 1
    @test el_labels[] == ["A", "B", "C"]

    categories = reverse
    leg_els, el_labels, group_labels = _compute_legend(spec2, scales = scales(Color = (; categories)))
    @test length(leg_els) == 1
    @test el_labels[] == ["C", "B", "A"]

    categories = ["A" => rich("a"), "C" => L"c", "B" => "b"]
    leg_els, el_labels, group_labels = _compute_legend(spec2, scales = scales(Color = (; categories)))
    @test length(leg_els) == 1
    @test el_labels[] == last.(categories)
end

@testset "hidden legend" begin
    df = (;
        x = repeat(1:3, 3),
        y = abs.(sin.(1:9)),
        z = ["a", "a", "a", "b", "b", "b", "c", "c", "c"],
    )
    for show in [true, false]
        fg = draw(
            data(df) * mapping(:x, :y; stack = :z, color = :z) * visual(BarPlot),
            legend = (; show)
        )
        @test any(x -> x isa Legend, fg.figure.content) == show
    end
end

@testset "hidden colorbar" begin
    df = (;
        x = 1:3,
        y = 4:6,
        z = 7:9,
    )
    for show in [true, false]
        fg = draw(
            data(df) * mapping(:x, :y; color = :z) * visual(BarPlot),
            colorbar = (; show)
        )
        @test any(x -> x isa Colorbar, fg.figure.content) == show
    end
end

@testset "per-layer legend visible" begin
    df = (; x = 1:3, y = 1:3, g = ["A", "B", "C"])

    spec_hidden = data(df) * mapping(:x, :y, color = :g) * (visual(Scatter) + visual(Scatter, legend = (; visible = false)))
    leg_els, el_labels, group_labels = _compute_legend(spec_hidden)
    @test length(leg_els) == 1
    for els in leg_els[]
        @test length(els) == 1
        @test els[1] isa MarkerElement
    end

    spec_visible = data(df) * mapping(:x, :y, color = :g) * (visual(Scatter) + visual(Scatter, legend = (; visible = true)))
    leg_els2, _, _ = _compute_legend(spec_visible)
    @test length(leg_els2) == 1
    for els in leg_els2[]
        @test length(els) == 2
    end

    spec_default = data(df) * mapping(:x, :y, color = :g) * (visual(Scatter) + visual(Lines))
    leg_els3, _, _ = _compute_legend(spec_default)
    @test length(leg_els3) == 1
    for els in leg_els3[]
        @test length(els) == 2
    end
end

@testset "alpha" begin
    df = (;
        x = repeat(1:3, 3),
        y = abs.(sin.(1:9)),
        z = ["a", "a", "a", "b", "b", "b", "c", "c", "c"],
    )
    spec = data(df) * mapping(:x, :y, color = :z) * ((visual(Scatter) + visual(BarPlot) + visual(Lines)) * visual(alpha = 0.5) + visual(Violin))
    leg_els, el_labels, group_labels = _compute_legend(spec)
    els = reduce(vcat, leg_els[])
    @test Makie.to_value(els[1].alpha) == 0.5
    @test Makie.to_value(els[2].alpha) == 0.5
    @test Makie.to_value(els[3].alpha) == 0.5
    @test Makie.to_value(els[4].alpha) == 1.0
end

@testset "hide_unused_legend" begin
    # Disjoint categories (issue #576): Scatter has "Data 1", Lines has "Data 2"
    @testset "disjoint categories via direct()" begin
        df = (; x = 1:5, y = 1:5)
        spec = data(df) * mapping(:x, :y) *
            (mapping(color = direct("Data 1")) * visual(Scatter) + mapping(color = direct("Data 2")) * visual(Lines))

        # Without hide_unused: both entries have both element types
        leg_els, el_labels, _ = _compute_legend(spec, hide_unused = false)
        @test length(leg_els[]) == 2
        @test length(leg_els[][1]) == 2
        @test length(leg_els[][2]) == 2

        # With hide_unused (default): each entry has only its own element
        leg_els, el_labels, _ = _compute_legend(spec)
        @test length(leg_els[]) == 2
        @test el_labels[] == ["Data 1", "Data 2"]
        @test length(leg_els[][1]) == 1
        @test leg_els[][1][1] isa MarkerElement
        @test length(leg_els[][2]) == 1
        @test leg_els[][2][1] isa LineElement

        # With hide_unused via per-scale option
        leg_els2, el_labels2, _ = _compute_legend(spec, scales = scales(Color = (; hide_unused_legend = true)))
        @test el_labels2[] == ["Data 1", "Data 2"]
        @test length(leg_els2[][1]) == 1
        @test leg_els2[][1][1] isa MarkerElement
        @test length(leg_els2[][2]) == 1
        @test leg_els2[][2][1] isa LineElement
    end

    # Full overlap: both layers have all categories, elements should still merge
    @testset "full overlap keeps all elements" begin
        df = (; x = 1:3, y = 1:3, g = ["a", "b", "c"])
        spec = data(df) * mapping(:x, :y, color = :g) * (visual(Scatter) + visual(Lines))

        leg_els, _, _ = _compute_legend(spec, hide_unused = true)
        @test length(leg_els[]) == 3
        for els in leg_els[]
            @test length(els) == 2
            @test els[1] isa MarkerElement
            @test els[2] isa LineElement
        end
    end

    # Partial overlap: Scatter has a,b,c; Lines has b,c,d
    @testset "partial overlap" begin
        df1 = (; x = 1:3, y = 1:3, g = ["a", "b", "c"])
        df2 = (; x = 1:3, y = 1:3, g = ["b", "c", "d"])
        spec = data(df1) * mapping(:x, :y, color = :g) * visual(Scatter) +
            data(df2) * mapping(:x, :y, color = :g) * visual(Lines)

        leg_els, el_labels, _ = _compute_legend(spec, hide_unused = true)
        @test el_labels[] == ["a", "b", "c", "d"]

        # "a": only Scatter
        @test length(leg_els[][1]) == 1
        @test leg_els[][1][1] isa MarkerElement
        # "b","c": both
        @test length(leg_els[][2]) == 2
        @test length(leg_els[][3]) == 2
        # "d": only Lines
        @test length(leg_els[][4]) == 1
        @test leg_els[][4][1] isa LineElement
    end

    # Categories in scale but not in data are removed
    @testset "unused categories removed" begin
        df = (; x = 1:2, y = 1:2, g = ["a", "b"])
        spec = data(df) * mapping(:x, :y, color = :g) * visual(Scatter)

        leg_els, el_labels, _ = _compute_legend(
            spec,
            scales = scales(Color = (; categories = ["a", "b", "c", "d"], hide_unused_legend = true))
        )
        @test el_labels[] == ["a", "b"]
        @test length(leg_els[]) == 2
    end

    # Pagination: each page only shows legend entries for present categories
    @testset "pagination filters per page" begin
        df = (
            x = repeat(1:5, 4),
            y = rand(20),
            layout = repeat(["p", "q", "r", "s"], inner = 5),
            color = [repeat(["X", "Y"], 5); repeat(["Y", "Z"], 5)],
        )
        spec = data(df) * mapping(:x, :y, layout = :layout, color = :color) * visual(Scatter)

        pag = paginate(spec, scales(Color = (; hide_unused_legend = true)), layout = 2)
        fgs = draw(pag)

        # Page 1 (p, q): has X and Y
        leg1 = AlgebraOfGraphics.compute_legend(fgs[1].grid; order = nothing, hide_unused = true)
        @test length(leg1[2][1]) == 2
        @test "X" in leg1[2][1]
        @test "Y" in leg1[2][1]

        # Page 2 (r, s): has Y and Z
        leg2 = AlgebraOfGraphics.compute_legend(fgs[2].grid; order = nothing, hide_unused = true)
        @test length(leg2[2][1]) == 2
        @test "Y" in leg2[2][1]
        @test "Z" in leg2[2][1]
    end

    # Pregrouped with empty arrays: category exists but data is empty
    @testset "pregrouped with empty arrays" begin
        spec = pregrouped([1:3, Int[]], [1:3, Int[]], color = ["a", "b"]) * visual(Scatter) +
            pregrouped([Int[], 1:3], [Int[], 1:3], color = ["a", "b"]) * visual(Lines)

        leg_els, el_labels, _ = _compute_legend(spec, hide_unused = true)
        @test el_labels[] == ["a", "b"]
        @test length(leg_els[][1]) == 1
        @test leg_els[][1][1] isa MarkerElement
        @test length(leg_els[][2]) == 1
        @test leg_els[][2][1] isa LineElement
    end

    # Default is hide_unused = true
    @testset "default hides unused" begin
        df = (; x = 1:5, y = 1:5)
        spec = data(df) * mapping(:x, :y) *
            (mapping(color = direct("A")) * visual(Scatter) + mapping(color = direct("B")) * visual(Lines))

        leg_els, _, _ = _compute_legend(spec)
        @test length(leg_els[]) == 2
        @test length(leg_els[][1]) == 1
        @test leg_els[][1][1] isa MarkerElement
        @test length(leg_els[][2]) == 1
        @test leg_els[][2][1] isa LineElement
    end

    # Can opt out with hide_unused = false
    @testset "opt out with hide_unused = false" begin
        df = (; x = 1:5, y = 1:5)
        spec = data(df) * mapping(:x, :y) *
            (mapping(color = direct("A")) * visual(Scatter) + mapping(color = direct("B")) * visual(Lines))

        leg_els, _, _ = _compute_legend(spec, hide_unused = false)
        @test length(leg_els[]) == 2
        @test length(leg_els[][1]) == 2
        @test length(leg_els[][2]) == 2
    end
end
