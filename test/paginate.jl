@testset "paginate" begin
    d = (
        a = 1:100,
        b = 101:200,
        c = repeat(string.(1:10), 10),
        d = repeat(string.('a':'j'), inner = 10)
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
        pag = paginate(spec, row = 3, col = 3)
        @test length(pag) == 16
        pag = paginate(spec, row = 10, col = 10)
        @test length(pag) == 1
    end
end
