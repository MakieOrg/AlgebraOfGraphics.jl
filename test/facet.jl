@testset "clean facet attributes" begin
    collection = (a=11, b=automatic, c=:test)
    value = get_with_options(collection, :a, options=(11, 12))
    @test value == 11
    value = get_with_options(collection, :d, options=(11, 12))
    @test value == automatic
    @test @test_logs(
        (:warn, "Replaced invalid keyword a = 11 by automatic. Valid values are :c, :d, or automatic."),
        get_with_options(collection, :a, options=(:c, :d))
    ) == automatic
end

