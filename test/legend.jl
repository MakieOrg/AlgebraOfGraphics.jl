function _compute_legend(spec; scales = scales(), order = nothing)
    axisgrid = compute_axes_grid(spec, scales)
    figure = Figure()
    axisentries = AlgebraOfGraphics.AxisEntries.(axisgrid, Ref(figure))
    AlgebraOfGraphics.compute_legend(axisentries; order)
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
    df  = (; x = 1:3, y = 1:3, g1 = ["A", "B", "C"], g2 = ["D", "E", "F"])
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
        z=["a", "a", "a", "b", "b", "b", "c", "c", "c"]
    )
    for show in [true, false]
        fg = draw(
            data(df) * mapping(:x, :y; stack=:z, color=:z) * visual(BarPlot),
            legend = (; show)
        )
        @test any(x -> x isa Legend, fg.figure.content) == show
    end
end

@testset "hidden colorbar" begin
    df = (;
        x = 1:3,
        y = 4:6,
        z = 7:9
    )
    for show in [true, false]
        fg = draw(
            data(df) * mapping(:x, :y; color=:z) * visual(BarPlot),
            colorbar = (; show)
        )
        @test any(x -> x isa Colorbar, fg.figure.content) == show
    end
end

@testset "alpha" begin
    df = (;
        x = repeat(1:3, 3),
        y = abs.(sin.(1:9)),
        z=["a", "a", "a", "b", "b", "b", "c", "c", "c"]
    )
    spec = data(df) * mapping(:x, :y, color = :z) * ((visual(Scatter) + visual(BarPlot) + visual(Lines)) * visual(alpha = 0.5) + visual(Violin))
    leg_els, el_labels, group_labels = _compute_legend(spec)
    els = reduce(vcat, leg_els[])
    @test Makie.to_value(els[1].alpha) == 0.5
    @test Makie.to_value(els[2].alpha) == 0.5
    @test Makie.to_value(els[3].alpha) == 0.5
    @test Makie.to_value(els[4].alpha) == 1.0
end

@testset "legend named tuple #PR #617" begin
    dat = DataFrame(grp = ["A", "B", "C"], x = [1., 2., 3.], y = [1., 2., 3.])
    plt = data(dat) * mapping(:x, :y, color = :grp) * visual(Scatter)
    @test_throws DomainError draw(plt, legend = (position = :bottom))
    @test isa(draw(plt, legend = (position = :bottom,)), AlgebraOfGraphics.FigureGrid)
end
