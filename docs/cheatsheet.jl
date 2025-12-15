using AlgebraOfGraphics
using CairoMakie
using Makie.Colors
using Typst_jll

struct Typst
    s::String
end



to_typst(io::IO, v::AbstractVector) = foreach(v) do el
    to_typst(io, el)
end

to_typst(io::IO, s::String) = print(io, s) # just simple, no escaping

function assetname!(io, ext)
    ref = get(io, :assetcounter, nothing)
    i = ref[]
    ref[] += 1
    path = "$i.$ext"
    return path
end

function to_typst(io::IO, x::Union{Makie.Figure,Makie.FigureAxisPlot,AlgebraOfGraphics.FigureGrid})
    p = assetname!(io, "pdf")
    Makie.save(p, x)
    print(io, "#image($(repr(p)))")
end

struct SVG
    path::String
end

function to_typst(io::IO, s::SVG)
    p = assetname!(io, "svg")
    cp(s.path, p)
    print(io, "#image($(repr(p)))")
end

function render(x)
    assetcounter = Ref(0)
    mktempdir() do dir
        cd(dir) do
            open("script.typ", "w") do io
                to_typst(IOContext(io, :assetcounter => assetcounter), x)
            end
            run(`$(typst()) compile script.typ`)
        end
        cp(joinpath(dir, "script.pdf"), joinpath(@__DIR__, "cheatsheet.pdf"), force = true)
    end
end

makieyellow = colorant"#e8cb26"
makieblue = colorant"#3182bb"
makiered = colorant"#dd3366"

set_theme!(
    Axis = (;
        width = 35,
        height = 35,
        xticksvisible = false,
        yticksvisible = false,
        xticklabelsvisible = false,
        yticklabelsvisible = false,
        xautolimitmargin = (0.15, 0.15),
        yautolimitmargin = (0.15, 0.15),
        xlabelpadding = 0,
        ylabelpadding = 0,
        titlegap = 1,
    ),
    Colorbar = (;
        labelpadding = 0,
        ticklabelsvisible = false,
        ticksvisible = false,
        spinewidth = 0,
        width = 5,
    ),
    Legend = (;
        rowgap = 0,
        colgap = 0,
        padding = 1,
        patchlabelgap = 3,
        # nbanks = 2,
        titlegap = -2,
        patchsize = (6, 6),
        framevisible = false,
        tellheight = true,
    ),
    colgap = 3,
    rowgap = 3,
    fontsize = 6 / 0.75,
    figure_padding = (2, 2, 2, 2),
    backgroundcolor = :transparent,
    linecolor = makiered,
    markercolor = makiered,
    markersize = 8,
    patchcolor = makiered,
    colormap = [makieblue, "gray90"],
    palettes = (;
        color = [makiered, makieblue, makieyellow],
    ),
)

macro vec(x)
    x isa String && return x
    @assert x isa Expr && x.head === :string
    esc(Expr(:vect, x.args...))
end


datasets = """
df_one = (A=[1,4,6,8], B=[2,6,4,5], C=[3,2,1,0], D=["a","b","c","d"])
df_two = (E=repeat(["e","f"],inner=50), F=[randn(50);randn(50).+3])
df_three = (G=1:30, H=sin.(range(0,2pi,30)).+rand.(), I=cos.(range(0,2pi,30)).+rand.())
df_four = (J=repeat(1:3,3), K=repeat(1:3,inner=3), L=[0,1,2,0.5,2,4,1,4,5])
df_five = (M=repeat(1:3,3), N=[0,2,3,0.5,3.5,5,1,5,7], O=repeat(["g","h","i"],inner=3))
df_six = (P=1:4, Q=["A","B","A","B"], R=4:-1:1, S=[0.5,0.6,0.3,0.7], T=[5.1,3.9,2.7,1.5], U=[1,1,2,2])
"""

eval(Meta.parseall(datasets))

function plottable(args...)
    @assert iseven(length(args))
    v = Any["#table(columns: 2, stroke: none, inset: 0pt, column-gutter: 5pt"]
    for (i, j) in Iterators.partition(args, 2)
        push!(
            v, ",[",
            i,
            "],table.cell(align: horizon, [",
            j,
            "])"
        )
    end
    push!(v, ")")
    v
end

block(title, content) = [
    "#block(fill: oklch(97%, 0.02, 0deg), inset: 0pt, radius: 4pt, clip: true, [#block(fill: oklch(92%, 0.04, 0deg), width: 100%, inset: 4pt, sticky: true)[$title]\n#block(inset: 4pt)[",
    content,
    "]])"
]

logo = SVG(joinpath(@__DIR__, "src", "assets", "logo_with_text.svg"))

doc = [
    @vec("""
    #set page(width: 297mm, height: 210mm, margin: 0.5cm)
    #set text(font: "Helvetica", size: 7pt)

    #table(
        columns: 3,
        inset: 0pt,
        column-gutter: (0pt, 10pt),
        stroke: none,
        align: horizon,
        box([$(logo)], height: 7em),
        table.cell(
            text(size: 3em, fill: gray, weight: "bold", style: "italic")[Cheat Sheet],
        ),
        table.cell(block(raw($(repr(datasets))), fill: luma(240), inset: 4pt, radius: 4pt)),
    )

    #columns(4, gutter: 1em)[
    """),
    block("`data(df_one) * mapping(:A, :B)`", plottable(
        data(df_one) * mapping(:A, :B) * visual(Scatter) |> draw,
        "`* visual(Scatter)`",
        data(df_one) * mapping(:A, :B, color = :C) * visual(Scatter) |> draw,
        "`* mapping(color=:C)\n* visual(Scatter)`",
        data(df_one) * mapping(:A, :B, color = :C) * visual(Scatter) |> draw(scales(Color = (; colormap = :plasma))),
        "`* mapping(color=:C)\n* visual(Scatter) |>\ndraw(scales(Color=(;colormap=:plasma))`",
        data(df_one) * mapping(:A, :B, color = :D) * visual(Scatter) |> draw,
        "`* mapping(color=:D)\n* visual(Scatter)`",
        data(df_one) * mapping(:A, :B, color = :D) * visual(Scatter) |> draw(scales(Color = (; palette = :Set1_5))),
        "`* mapping(color=:D)\n* visual(Scatter) |>\ndraw(scales(Color=(;palette=:Set1_5))`",
        data(df_one) * mapping(:A, :B) * visual(Lines) |> draw,
        "`* visual(Lines)`",
        data(df_one) * mapping(:A, :B) * visual(ScatterLines) |> draw,
        "`* visual(ScatterLines)`",
        data(df_one) * mapping(:A, :B) * visual(Stairs) |> draw,
        "`* visual(Stairs)`",
        data(df_one) * mapping(:D, :B) * visual(BarPlot) |> draw,
        "`* visual(BarPlot)`",
        data(df_one) * mapping(:D, :B) * visual(BarPlot, direction = :x) |> draw,
        "`* visual(BarPlot,direction=:x)`",
        data(df_one) * (mapping(:A, :B) * visual(Scatter, markersize = 5) + mapping(:A, :B, text = :D => verbatim) * visual(Makie.Text, align = (:center, :center))) |> draw,
        "`* mapping(text=:D=>verbatim)\n* visual(Makie.Text)`",
        data(df_one) * (mapping(:A, :B) * visual(Scatter, markersize = 5) + mapping(:A, :B, text = :D => verbatim) * visual(Annotation, color = :black)) |> draw,
        "`* mapping(text=:D=>verbatim)\n* visual(Annotation)`",
    )),
    block("`data(df_one) * mapping(:A)`", plottable(
        data(df_one) * mapping(:A) * visual(HLines) |> draw,
        "`* visual(HLines)`",
        data(df_one) * mapping(:A) * visual(VLines) |> draw,
        "`* visual(VLines)`",
    )),
    block("`data(df_two) * mapping(:E, :F)`", plottable(
        data(df_two) * mapping(:E, :F) * visual(Violin) |> draw,
        "`* visual(Violin)`",
        data(df_two) * mapping(:E, :F) * visual(Violin, orientation = :horizontal) |> draw,
        "`* visual(Violin,orientation=:horizontal)`",
        data(df_two) * mapping(:E, :F) * visual(BoxPlot, strokecolor = makiered, color = :white, strokewidth = 1, outliercolor = makiered, markersize = 5) |> draw,
         "`* visual(BoxPlot)`",
         data(df_two) * mapping(:E, :F) * visual(BoxPlot, orientation = :horizontal, strokecolor = makiered, color = :white, strokewidth = 1, outliercolor = makiered, markersize = 5) |> draw,
         "`* visual(BoxPlot,orientation=:horizontal)`",
    )),
    block("`data(df_two) * mapping(:F)`", plottable(
         data(df_two) * mapping(:F) * histogram() |> draw,
         "`* histogram()`",
         data(df_two) * mapping(:F) * AlgebraOfGraphics.density() |> draw,
         "`* AoG.density()`",
         data(df_two) * mapping(:F) * visual(QQNorm, markersize = 3, qqline = :fit) |> draw,
         "`* visual(QQNorm)`",
    )),
    block("`data(df_three) * mapping(:G, :H)`", plottable(
        data(df_three) * mapping(:G, :H) * (visual(Scatter, markersize = 2) + smooth()) |> draw,
        "`* smooth()`",
        data(df_three) * mapping(:G, :H) * (visual(Scatter, markersize = 2) + linear()) |> draw,
        "`* linear()`",
        data(df_three) * mapping(:H, :I) * (AlgebraOfGraphics.density() + visual(Scatter, markersize = 2)) |> draw,
        "`* AoG.density()`",
    )),
    block("`data(df_four) * mapping(:J, :K, :L)`", plottable(
        data(df_four) * mapping(:J, :K, :L) * visual(Heatmap) |> draw,
        "`* visual(Heatmap)`",
        data(df_four) * mapping(:J, :K, :L) * contours(levels = 5) |> draw,
        "`* contours(bands=4)`",
        data(df_four) * mapping(:J, :K, :L) * filled_contours(bands = 4) |> draw,
        "`* filled_contours(bands=4)`",
    )),
    block("`data(df_five) * mapping(:M, :N)`", plottable(
        data(df_five) * mapping(:M, :N, group = :O) * visual(Lines) |> draw,
        "`* mapping(group=:O)\n* visual(Lines)`",
        data(df_five) * mapping(:M, :N, color = :O) * visual(Lines) |> draw,
        "`* mapping(color=:O)\n* visual(Lines)`",
        data(df_five) * mapping(:M, :N, linestyle = :O) * visual(Lines) |> draw,
        "`* mapping(linestyle=:O)\n* visual(Lines)`",
        data(df_five) * mapping(:M, :N, marker = :O) * visual(ScatterLines) |> draw,
        "`* mapping(marker=:O)\n* visual(ScatterLines)`",
        data(df_five) * mapping(:M, :N, color = :O, dodge = :O) * visual(BarPlot) |> draw,
        "`* mapping(color=:O,dodge=:O)\n* visual(BarPlot)`",
        data(df_five) * mapping(:M, :N, color = :O, stack = :O) * visual(BarPlot) |> draw,
        "`* mapping(color=:O,stack=:O)\n* visual(BarPlot)`",
        data(df_five) * mapping(:M, :N, row = :O) * visual(Lines) |> draw(axis = (; width = 30, height = 15)),
        "`* mapping(row=:O)\n* visual(Lines)`",
        data(df_five) * mapping(:M, :N, col = :O) * visual(Lines) |> draw(axis = (; width = 15, height = 30)),
        "`* mapping(col=:O)\n* visual(Lines)`",
        data(df_five) * mapping(:M, :N, layout = :O) * visual(Lines) |> draw(axis = (; width = 20, height = 20)),
        "`* mapping(layout=:O)\n* visual(Lines)`",
    )),
    block("`data(df_six)`", plottable(
        data(df_six) * (mapping(:P, :R) * visual(BarPlot) + mapping(:P, :R, :S) * visual(Errorbars, color = :black)) |> draw,
        "`* (mapping(:P,:R) * visual(BarPlot)\n+ mapping(:P,:R,:S) * visual(Errorbars))`",
        data(df_six) * (mapping(:P, :R) * visual(BarPlot) + mapping(:P, :R, :S, :S => x -> 2x) * visual(Errorbars, color = :black)) |> draw,
        "`* (mapping(:P,:R) * visual(BarPlot)\n+ mapping(:P,:R,:S,:S=>x->2x) * visual(Errorbars))`",
        data(df_six) * (mapping(:P, :R) * visual(BarPlot) + mapping(:P, :S, :T) * visual(Rangebars, color = :black)) |> draw,
        "`* mapping(group=:O)\n* visual(Lines)`",
        data(df_six) * (mapping(:U, :R, dodge=:Q, color=:Q) * visual(BarPlot) + mapping(:U, :R, :S, dodge_x=:Q) * visual(Errorbars, color = :black)) |> draw,
        "`* (mapping(:U,:R,dodge=:Q,color=:Q) * visual(BarPlot)\n+ mapping(:U,:R,:S,dodge_x=:Q) * visual(Errorbars))`",
    )),
    "] // columns",
]

render(doc)