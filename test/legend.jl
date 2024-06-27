function _compute_legend(spec; scales = (;), order = nothing)
    scales = AlgebraOfGraphics._kwdict(scales)
    for (key, value) in pairs(scales)
        scales[key] = AlgebraOfGraphics._kwdict(value)
    end
    axisgrid = compute_axes_grid(spec; scales)
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
    spec2 = data((; x = 1:3, y = 1:3, g1 = ["A", "B", "C"], g2 = ["D", "E", "F"])) *
        mapping(:x, :y, color = :g1, marker = :g2) *
        visual(Scatter)

    leg_els, el_labels, group_labels = _compute_legend(spec2)
    @test length(leg_els) == 2
    @test group_labels == ["g1", "g2"]

    leg_els, el_labels, group_labels = _compute_legend(spec2; scales = (; Color = (; legend = false)))
    @test length(leg_els) == 1
    @test group_labels == ["g2"]

    leg_els, el_labels, group_labels = _compute_legend(spec2; scales = (; Color = (; label = "Color"), Marker = (; label = "Marker")))
    @test length(leg_els) == 2
    @test group_labels == ["Color", "Marker"]
end
