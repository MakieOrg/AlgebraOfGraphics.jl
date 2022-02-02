@testset "clean facet attributes" begin
    collection = (a=11, b=automatic, c=:test)
    value = get_with_options(collection, :a, options=(11, 12))
    @test value == 11
    value = get_with_options(collection, :d, options=(11, 12))
    @test value == automatic
    value = get_with_options(collection, :d, "", options=(11, 12))
    @test value ==  ""
    @test @test_logs(
        (:warn, "Replaced invalid keyword a = 11 by :default. Valid values are :c, :d, or :default."),
        get_with_options(collection, :a, :default, options=(:c, :d))
    ) == :default
end

