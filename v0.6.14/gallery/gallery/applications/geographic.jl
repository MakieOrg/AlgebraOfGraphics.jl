using AlgebraOfGraphics, CairoMakie
using Shapefile, ZipFile
using Downloads

# Download, extract, and load shapefile
t = mktempdir() do dir
    url = "https://ramadda.data.bas.ac.uk/repository/entry/get/add_coastline_medium_res_polygon_v7_4.zip?entryid=synth%3Ae747e63e-9d93-49c2-bafc-cf3d3f8e5afa%3AL2FkZF9jb2FzdGxpbmVfbWVkaXVtX3Jlc19wb2x5Z29uX3Y3XzQuemlw"
    r = ZipFile.Reader(seekstart(Downloads.download(url, IOBuffer())))
    for f in r.files
        open(joinpath(dir, f.name), write = true) do io
            write(io, read(f, String));
        end
    end
    Shapefile.Table(joinpath(dir, "add_coastline_medium_res_polygon_v7_4.shp"))
end

# Draw map
plt = data(t) * mapping(:geometry, color = :surface) * visual(Choropleth)
fg = draw(plt; axis=(aspect=1,))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

