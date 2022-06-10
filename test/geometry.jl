@testset "geometry" begin
    path = joinpath(dirname(pathof(Shapefile)),"..","test","shapelib_testcases","test.shp")
    table = Shapefile.Table(path)
    geoms = Shapefile.shapes(table)
    