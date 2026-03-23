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

@testset "paginate preserves layout wrap palette" begin
    d = (; x = 1:90, y = 1:90, group = repeat(string.("g", 1:9), 10))
    spec = data(d) * mapping(:x, :y, layout = :group) * visual(Scatter)

    # with wrapped(cols = 2), each page should have at most 2 columns
    sc = scales(Layout = (; palette = wrapped(cols = 2)))
    pag = paginate(spec, sc, layout = 6)
    @test length(pag) == 2
    fgrids = draw(pag)

    # page 1: 6 items in 3 rows × 2 cols
    axes_1 = [entry.axis for entry in pag.each[1] if !isempty(entry.entries)]
    positions_1 = [ax.position for ax in axes_1]
    @test maximum(first, positions_1) == 3
    @test maximum(last, positions_1) == 2

    # page 2: 3 items in 2 rows × 2 cols (one empty)
    axes_2 = [entry.axis for entry in pag.each[2] if !isempty(entry.entries)]
    positions_2 = [ax.position for ax in axes_2]
    @test maximum(first, positions_2) == 2
    @test maximum(last, positions_2) == 2

    # without custom palette, default wrapped() gives squarish layout
    pag_default = paginate(spec, layout = 6)
    axes_default = [entry.axis for entry in pag_default.each[1] if !isempty(entry.entries)]
    positions_default = [ax.position for ax in axes_default]
    # default wrapped() for 6 items: ceil(sqrt(6)) = 3 cols → 2 rows × 3 cols
    @test maximum(first, positions_default) == 2
    @test maximum(last, positions_default) == 3

    # with wrapped(cols = 1), single column layout
    sc_1col = scales(Layout = (; palette = wrapped(cols = 1)))
    pag_1col = paginate(spec, sc_1col, layout = 4)
    @test length(pag_1col) == 3
    axes_1col = [entry.axis for entry in pag_1col.each[1] if !isempty(entry.entries)]
    positions_1col = [ax.position for ax in axes_1col]
    @test maximum(first, positions_1col) == 4
    @test maximum(last, positions_1col) == 1
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
