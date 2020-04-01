#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#

const wong_colors = [
    "rgb(230, 159, 0)",
    "rgb(86, 180, 233)",
    "rgb(0, 158, 115)",
    "rgb(240, 228, 66)",
    "rgb(0, 114, 178)",
    "rgb(213, 94, 0)",
    "rgb(204, 121, 167)",
]

const default_palettes = Dict(
                              :marker => Dict(
                                              :color => wong_colors,
                                              :symbol => [
                                                          "circle",
                                                          "cross",
                                                          "square",
                                                          "triangle-up",
                                                          "diamond",
                                                          "triangle-down"
                                                         ]
                                             ),
                              :line => Dict(
                                            :color => wong_colors,
                                            :das => ["solid", "dash", "dot", "dashdot"]
                                           ),
                              :side => ["left", "right"]
                             )

# TODO deal with names, link axes, and avoid default color cycling
function to_dict(ts::GraphicalOrContextual)
    rks = rankdicts(ts)
    serieslist = specs(ts, default_palettes, rks)
    Nx, Ny = 1, 1
    for series in serieslist
        for (primary, trace) in series
            Nx = max(Nx, get(trace.kwargs, :layout_x, Nx))
            Ny = max(Ny, get(trace.kwargs, :layout_y, Ny))
        end
    end

    layout = (; grid = (rows = Ny, columns = Nx, pattern = "independent"))
    traces = []
    for series in serieslist
        for (primary, trace) in series
            args = trace.args
            attrs = Dict(pairs(trace.kwargs))
            pop!(attrs, :names)
            x_pos = pop!(attrs, :layout_x, 1) |> to_value
            y_pos = pop!(attrs, :layout_y, 1) |> to_value
            counter = x_pos + Nx * (y_pos - 1)
            push!(traces, (;
                           attrs...,
                           xaxis = "x$counter",
                           yaxis = "y$counter",
                          )
                 )
        end
    end
    return (data = traces, layout = layout)
end

const pre_html = """
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>test plot</title>
    <script src='https://cdn.plot.ly/plotly-latest.min.js'></script>
  </head>
  <body>
    <div id='plotdiv' style="width: 800px"></div>
    <script>
"""

const post_html = """
    </script>
  </body>
</html>
"""

function writeplot(s::GraphicalOrContextual, file::AbstractString)
    ts, l = to_dict(s)
    open(file, "w") do io
        print(io, pre_html)
        print(io, "var data = ")
        JSON.print(io, ts)
        println(io, ";")
        print(io, "var layout = ")
        JSON.print(io, l)
        println(io, ";")
        println(io, "Plotly.newPlot('plotdiv', data, layout);")
        print(io, post_html)
    end
end
