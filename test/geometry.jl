@testset "geometry" begin
    path = joinpath(dirname(pathof(Shapefile)),"..","test","shapelib_testcases","test.shp")
    table = Shapefile.Table(path)
    geoms = Shapefile.shapes(table)
    multipoly = AlgebraOfGraphics.to_geometry(AlgebraOfGraphics.trivialtransformation, geoms[1])
    poly1 = GeometryBasics.Polygon(
        [
            Point2f(20, 20),
            Point2f(20, 30),
            Point2f(30, 30),
            Point2f(20, 20)
        ]
    )
    poly2 = GeometryBasics.Polygon(
        [
            Point2f(0, 0),
            Point2f(100, 0),
            Point2f(100, 100),
            Point2f(0, 100),
            Point2f(0, 0)
        ]
    )
    @test multipoly.polygons[1] == poly1
    @test multipoly.polygons[2] == poly2
end