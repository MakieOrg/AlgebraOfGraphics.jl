# ---
# title: Geographic data
# cover: assets/geographic.png
# description: Antarctic coastline
# author: "[Pietro Vertechi](https://github.com/piever)"
# ---

using AlgebraOfGraphics, CairoMakie
using Shapefile, ZipFile
using Downloads: download
set_aog_theme!() #src

# Antarctic coastline. Data from the SCAR Antarctic Digital Database[^1].
#
# [^1]: Gerrish, L., Fretwell, P., & Cooper, P. (2021). Medium resolution vector polygons of the Antarctic coastline (7.4) [Data set]. UK Polar Data Centre, Natural Environment Research Council, UK Research & Innovation. https://doi.org/10.5285/747e63e-9d93-49c2-bafc-cf3d3f8e5afa

## Download, extract, and load shapefile
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

## Draw map
plt = geodata(t) * mapping(:geometry, color = :surface) * visual(Poly)
fg = draw(plt; axis=(aspect=1,))

# save cover image #src
mkpath("assets") #src
save("assets/geographic.png", fg) #src
