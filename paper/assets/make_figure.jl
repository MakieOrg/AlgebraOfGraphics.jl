using Pkg
Pkg.activate(@__DIR__)

using AlgebraOfGraphics, CairoMakie
using Colors

penguins = AlgebraOfGraphics.penguins()

set_aog_theme!()
update_theme!(Scatter = (; markersize = 6.75))  # 75% of Makie's default 9

s1 = data(penguins) * mapping(:bill_length_mm, :bill_depth_mm)
s2 = s1 * mapping(color = :species)
s3 = s2 * (linear() + visual(alpha = 0.3))
s4 = s3 * mapping(col = :sex)
s5 = s4

# Space-containing blank lines force equal code-cell heights within a row.
blank = " "

steps = [
    (label = "1. data and positional mapping",
     code = "data(penguins) *\n    mapping(:bill_length_mm,\n            :bill_depth_mm)",
     spec = s1, scales_kw = (;)),
    (label = "2. add a color grouping",
     code = "... * mapping(color = :species)\n$blank\n$blank",
     spec = s2, scales_kw = (;)),
    (label = "3. add a regression layer",
     code = "... * (linear() +\n       visual(alpha = 0.3))\n$blank",
     spec = s3, scales_kw = (;)),
    (label = "4. add faceting",
     code = "... * mapping(col = :sex)\n$blank",
     spec = s4, scales_kw = (;)),
    (label = "5. customize the color scale",
     code = "draw(..., scales(Color = (; palette = :Set1_3,\n                          categories = reverse)))",
     spec = s5, scales_kw = (; Color = (; palette = :Set1_3, categories = reverse))),
]

function pastel_hues(n; L = 95, C = 18, h0 = 10)
    return [RGB(convert(RGB, LCHuv(L, C, mod(h0 + 360 * (i - 1) / n, 360)))) for i in 1:n]
end

const SYMBOL_COLOR = RGB(0.35, 0.45, 0.80)   # blue-ish
const NUMBER_COLOR = RGB(0.80, 0.40, 0.15)   # orange-ish

function highlight_code(code; default_color = (:black, 0.75),
        symbol_color = SYMBOL_COLOR, number_color = NUMBER_COLOR)
    # Match either a Julia :symbol or a number literal.
    re = r":\w+|(?<![A-Za-z_\d])\d+(?:\.\d+)?"
    parts = Any[]
    pos = 1
    for m in eachmatch(re, code)
        s = m.offset
        if s > pos
            push!(parts, String(SubString(code, pos, prevind(code, s))))
        end
        segment = String(m.match)
        color = startswith(segment, ':') ? symbol_color : number_color
        push!(parts, rich(segment; color))
        pos = s + ncodeunits(segment)
    end
    if pos <= ncodeunits(code)
        push!(parts, String(SubString(code, pos)))
    end
    return rich(parts...; color = default_color)
end

function build_figure_fullcode(steps;
        ax_w = 80, ax_h = 80, ax_w_row2 = 86,
        code_fs = 9, label_fs = 11, full_code_fs = 10,
        col_gap = 16, row_gap = 16,
        box_colors = pastel_hues(6),
        box_cornerradius = 8,
        box_outside = -4,
        content_pad = 4,
        legend_labelsize = 9, legend_patchsize = (10, 10),
        facet_colgap = 5,
        legend_plot_gap = 5,
    )
    fig = Figure(; fontsize = 10)

    axis_kw_noticks = (; xticksvisible = false, yticksvisible = false)

    function code_block!(parent, code_str; fontsize, default_color = (:black, 0.75),
            top_pad = 0, bottom_pad = 4, tellwidth = true)
        gl = GridLayout(parent; halign = :left)
        lines = split(code_str, '\n')
        line_h = round(fontsize * 1.2)
        for (i, line) in enumerate(lines)
            tpad = i == 1 ? top_pad : 0
            bpad = i == length(lines) ? bottom_pad : 0
            Label(gl[i, 1], highlight_code(String(line); default_color);
                font = "DejaVu Sans Mono", fontsize = fontsize,
                halign = :left, justification = :left, word_wrap = false,
                tellwidth = tellwidth,
                padding = (content_pad, content_pad, tpad, bpad))
            rowsize!(gl, i, Fixed(line_h + tpad + bpad))
        end
        rowgap!(gl, 0)
        return gl
    end

    function add_step!(parent, step; axis_width = ax_w, tellwidth = true)
        cell = GridLayout(parent)
        Label(cell[1, 1], step.label;
            font = :bold, fontsize = label_fs,
            halign = :left, justification = :left, tellwidth = tellwidth,
            padding = (content_pad, content_pad, content_pad, 2))
        code_block!(cell[2, 1], step.code; fontsize = code_fs,
            bottom_pad = 4, tellwidth = tellwidth)
        plotbox = GridLayout(cell[3, 1]; alignmode = Outside(content_pad))
        axis_kw = axis_width === nothing ?
            (; height = ax_h, axis_kw_noticks...) :
            (; width = axis_width, height = ax_h, axis_kw_noticks...)
        ag = draw!(plotbox[1, 1], step.spec, scales(; step.scales_kw...);
            axis = axis_kw)
        try
            inner_gl = only(contents(plotbox[1, 1]))
            colgap!(inner_gl, facet_colgap)
        catch
        end
        try
            legend!(plotbox[1, 2], ag;
                tellheight = false, tellwidth = true,
                framevisible = false,
                labelsize = legend_labelsize, patchsize = legend_patchsize)
            colgap!(plotbox, legend_plot_gap)
        catch
        end
        rowgap!(cell, 2)
        return cell
    end

    function add_code_panel!(parent, title, code)
        cell = GridLayout(parent)
        Label(cell[1, 1], title;
            font = :bold, fontsize = label_fs,
            halign = :left, justification = :left,
            tellwidth = false,
            padding = (content_pad, content_pad, content_pad, 2))
        inner = GridLayout(cell[2, 1]; tellwidth = false, halign = :left)
        lines = split(code, '\n')
        line_h = round(full_code_fs * 1.2)
        for (i, line) in enumerate(lines)
            bpad = i == length(lines) ? content_pad : 0
            Label(inner[i, 1], highlight_code(String(line); default_color = (:black, 0.85));
                font = "DejaVu Sans Mono", fontsize = full_code_fs,
                halign = :left, justification = :left, tellwidth = false, word_wrap = false,
                padding = (content_pad, content_pad, 0, bpad))
            rowsize!(inner, i, Fixed(line_h + bpad))
        end
        rowgap!(inner, 0)
        rowgap!(cell, 2)
        return cell
    end

    function step_box!(g, row, col, fillcolor)
        box = Box(g[row, col, Makie.GridLayoutBase.Outer()];
            cornerradius = box_cornerradius,
            color = fillcolor,
            strokecolor = :transparent,
            strokewidth = 0,
            alignmode = Outside(box_outside))
        Makie.translate!(box.blockscene, 0, 0, -100)
        return box
    end

    top = GridLayout(fig[1, 1]; halign = :left)
    for (i, step) in enumerate(steps[1:3])
        add_step!(top[1, i], step)
        step_box!(top, 1, i, box_colors[i])
    end
    colgap!(top, col_gap)

    bot = GridLayout(fig[2, 1])
    for (i, step) in enumerate(steps[4:5])
        add_step!(bot[1, i], step; axis_width = nothing, tellwidth = false)
        step_box!(bot, 1, i, box_colors[3 + i])
    end
    colgap!(bot, col_gap)

    combined_code = "data(penguins) *\n" *
                    "    mapping(:bill_length_mm, :bill_depth_mm, color = :species, col = :sex) *\n" *
                    "    (linear() + visual(alpha = 0.3)) |>\n" *
                    "    draw(scales(Color = (; palette = :Set1_3, categories = reverse)))"
    third = GridLayout(fig[3, 1])
    add_code_panel!(third[1, 1], "6. combined code", combined_code)
    step_box!(third, 1, 1, box_colors[6])

    rowgap!(fig.layout, row_gap)
    resize_to_layout!(fig)
    return fig
end

if abspath(PROGRAM_FILE) == @__FILE__
    fig = build_figure_fullcode(steps)
    outpath = joinpath(@__DIR__, "..", "figure_overview.png")
    save(outpath, fig; px_per_unit = 2)
    println("wrote $(abspath(outpath)), size = ", size(fig.scene))
end
