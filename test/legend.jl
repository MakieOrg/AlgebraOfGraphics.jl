@testset "legend_merging" begin
    mwe_data = (; t = 1:20, y1 = ones(20), y2 = rand(20))
    mwe_names = ["f_n", "f_d"]
    plt = data(mwe_data) *
        mapping("t", ["y1", "y2"] .=> "y"; color = dims(1) => (i -> mwe_names[i]), marker=dims(1)) *
        (visual(Lines) + visual(Scatter))
    @static if 
    @test_throws Makie.MakieCore.InvalidAttributeError draw(plt)
end
