function _equal(l1::ProcessedLayer, l2::ProcessedLayer)
    return all(fieldnames(ProcessedLayer)) do n
        getproperty(l1, n) == getproperty(l2, n)
    end
end

function _equal(l1::ProcessedLayers, l2::ProcessedLayers)
    length(l1.layers) == length(l2.layers) || return false
    return all(zip(l1.layers, l2.layers)) do (l1l, l2l)
        _equal(l1l, l2l)
    end
end

@testset "paginate" begin
    cs = string.(0:9)
    ds = string.('a':'j')

    d = (
        a = 1:100,
        b = 101:200,
        c = repeat(cs, 10),
        d = repeat(ds, inner = 10),
    )

    # test both Layer and Layers
    for vis in [visual(Scatter), visual(Scatter) + visual(Lines)]
        spec = data(d) * mapping(:a, :b, layout = :c) * vis
        pag = paginate(spec)
        @test length(pag) == 1
        pag = paginate(spec, layout = 10)
        @test length(pag) == 1
        pag = paginate(spec, layout = 1)
        @test length(pag) == 10
        pag = paginate(spec, layout = 2)
        @test length(pag) == 5
        pag = paginate(spec, layout = 3)
        @test length(pag) == 4
        pag = paginate(spec, layout = 4)
        @test length(pag) == 3

        fgrids = draw(pag)
        @test fgrids isa Vector{FigureGrid}
        @test length(fgrids) == length(pag)
        for i in 1:length(pag)
            @test draw(pag, 1) isa FigureGrid
        end
        @test_throws ArgumentError draw(pag, 0)
        @test_throws ArgumentError draw(pag, length(pag) + 1)

        spec = data(d) * mapping(:a, :b, row = :c, col = :d) * vis
        pag = paginate(spec)
        @test length(pag) == 1
        pag = paginate(spec, row = 1, col = 10)
        @test length(pag) == 10
        pag = paginate(spec, row = 10, col = 1)
        @test length(pag) == 10
        pag = paginate(spec, row = 10, col = 10)
        @test length(pag) == 1
        pag = paginate(spec, row = 3, col = 3)
        @test length(pag) == 16
        pag = paginate(spec, row = 5)
        @test length(pag) == 2
        pag = paginate(spec, col = 5)
        @test length(pag) == 2
    end
end

@testset "pagination with scales" begin
    spec = data((; x = 1:10, y = 11:20, group = repeat(["A", "B"]))) * mapping(:x, :y, layout = :group)
    scl = scales(Layout = (; categories = ["B", "A"]))
    p = paginate(spec, scl, layout = 1)
    ae1 = only(p.each[1])
    ae2 = only(p.each[2])
    cat1 = AlgebraOfGraphics.extract_single(AlgebraOfGraphics.AesLayout, ae1.categoricalscales)
    cat2 = AlgebraOfGraphics.extract_single(AlgebraOfGraphics.AesLayout, ae2.categoricalscales)
    @test only(AlgebraOfGraphics.datavalues(cat1)) == "B"
    @test only(AlgebraOfGraphics.datavalues(cat2)) == "A"

    @test_throws_message "Calling `draw` with a `Pagination` object and `scales` is invalid." draw(p, scl)
end

@testset "Axis attributes when drawing pagination" begin
    spec = data((; x = 1:10, y = 11:20, group = repeat(["A", "B"]))) * mapping(:x, :y, layout = :group)
    p = paginate(spec, layout = 1)
    fgrid = draw(p, 1; axis = (; xlabelcolor = :tomato))
    ax = only(fgrid.grid).axis
    @test ax.xlabelcolor[] == Makie.to_color(:tomato)

    fgrids = draw(p; axis = (; xlabelcolor = :tomato))
    ax = only(fgrids[1].grid).axis
    @test ax.xlabelcolor[] == Makie.to_color(:tomato)
end
