using AlgebraOfGraphics, CairoMakie
using Shapefile, ZipFile
using Downloads: download

# Download, extract, and load shapefile
t = mktempdir() do dir
    url = "https://data.bas.ac.uk/download/7be3ab29-7caa-46b8-a355-2e3233796e86"
    r = ZipFile.Reader(seekstart(download(url, IOBuffer())))
    for f in r.files
        open(joinpath(dir, f.name), write = true) do io
            write(io, read(f, String));
        end
    end
    Shapefile.Table(joinpath(dir, "add_coastline_medium_res_polygon_v7_4.shp"))
end

# Draw map
plt = geodata(t) * mapping(:geometry, color = :surface) * visual(Poly)
fg = draw(plt; axis=(aspect=1,))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

