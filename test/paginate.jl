function _equal(l1::Layer, l2::Layer)
    all(fieldnames(Layer)) do n
        getproperty(l1, n) == getproperty(l2, n)
    end
end

function _equal(l1::Layers, l2::Layers)
    length(l1.layers) == length(l2.layers) || return false
    all(zip(l1.layers, l2.layers)) do (l1l, l2l)
        _equal(l1l, l2l)
    end
end

_to_layers(l::Layers) = l
_to_layers(l::Layer) = Layers([l])

@testset "paginate" begin
    cs = string.(0:9)
    ds = string.('a':'j')

    d = (
        a = 1:100,
        b = 101:200,
        c = repeat(cs, 10),
        d = repeat(ds, inner = 10)
    )

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

        # manually test that a spec built like a pagination is equivalent
        # to the output of the pagination
        pag = paginate(spec, row = 3, col = 4)

        c_parts = collect(Iterators.partition(cs, 3))
        d_parts = collect(Iterators.partition(ds, 4))
        @test length(c_parts) * length(d_parts) == length(pag.each)
        for (id, _ds) in enumerate(d_parts)
            # rows change faster
            for (ic, _cs) in enumerate(c_parts)
                idcs = (d.c .∈ Ref(_cs)) .&  (d.d .∈ Ref(_ds))
                # filter out all data not on the current page
                subset = (a = d.a[idcs], b = d.b[idcs], c = d.c[idcs], d = d.d[idcs])
                manual_pagination = data(subset) * mapping(:a, :b, row = :c, col = :d) * vis
                manual_pagination = _to_layers(manual_pagination)
                i = ic + length(c_parts) * (id - 1)
                @test _equal(manual_pagination, pag.each[i])
            end
        end

        # and once more for layout
        spec = data(d) * mapping(:a, :b, layout = :c) * vis
        pag = paginate(spec, layout = 3)

        c_parts = collect(Iterators.partition(cs, 3))
        @test length(c_parts) == length(pag.each)
        for (ic, _cs) in enumerate(c_parts)
            idcs = d.c .∈ Ref(_cs)
            # filter out all data not on the current page
            subset = (a = d.a[idcs], b = d.b[idcs], c = d.c[idcs], d = d.d[idcs])
            manual_pagination = data(subset) * mapping(:a, :b, layout = :c) * vis
            manual_pagination = _to_layers(manual_pagination)
            @test _equal(manual_pagination, pag.each[ic])
        end
    end
end
