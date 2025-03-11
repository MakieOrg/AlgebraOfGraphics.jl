# Geographic data


````@example geographic
using AlgebraOfGraphics, CairoMakie
using Shapefile, ZipFile
using Downloads
````

Antarctic coastline. Data from the SCAR Antarctic Digital Database[^1].

[^1]: Gerrish, L., Fretwell, P., & Cooper, P. (2021). Medium resolution vector polygons of the Antarctic coastline (7.4) [Data set]. UK Polar Data Centre, Natural Environment Research Council, UK Research & Innovation. https://doi.org/10.5285/747e63e-9d93-49c2-bafc-cf3d3f8e5afa

````@example geographic
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
````



