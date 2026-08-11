cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.develop(path = "..")
Pkg.precompile()

using PixelMatch
using PNGFiles
using quarto_jll

const rendered_markdown = "README.md"
const rendered_figures = "README_files"
const committed_markdown = joinpath("..", "README.md")
const committed_figures = joinpath("..", "README_files")

figure_names(dir) = sort([relpath(joinpath(root, file), dir) for (root, _, files) in walkdir(dir) for file in files])

function figure_problem(name, diff_dir)
    committed_path = joinpath(committed_figures, name)
    rendered_path = joinpath(rendered_figures, name)
    committed_image = PNGFiles.load(committed_path)
    rendered_image = PNGFiles.load(rendered_path)

    if size(committed_image) != size(rendered_image)
        PixelMatch._record_failure(;
            name, status = :size_mismatch,
            ref_path = committed_path, rec_path = rendered_path,
            ref_size = size(committed_image), rec_size = size(rendered_image),
        )
        return "$name: committed size is $(size(committed_image)), rendered size is $(size(rendered_image))"
    end

    n_pixels_different, diff_image = pixelmatch(committed_image, rendered_image)
    n_pixels_different == 0 && return nothing

    diff_path = joinpath(diff_dir, replace(name, '/' => '_'))
    PNGFiles.save(diff_path, diff_image)
    PixelMatch._record_failure(;
        name, status = :mismatch, num_pixels_diff = n_pixels_different,
        ref_path = committed_path, rec_path = rendered_path, diff_path,
        ref_size = size(committed_image), rec_size = size(rendered_image),
    )
    return "$name: $n_pixels_different pixels differ from the committed version"
end

function problems(diff_dir)
    ps = String[]

    if read(rendered_markdown, String) != read(committed_markdown, String)
        push!(ps, "README.md differs from the rendered version")
    end

    committed_names = figure_names(committed_figures)
    rendered_names = figure_names(rendered_figures)
    if committed_names != rendered_names
        push!(ps, "committed figures $committed_names differ from rendered figures $rendered_names")
        return ps
    end

    for name in rendered_names
        problem = figure_problem(name, diff_dir)
        problem === nothing || push!(ps, problem)
    end

    return ps
end

run(`$(quarto()) render README.qmd`)

if "--check" in ARGS
    PixelMatch.@pixelmatch_report out_file = "pixelmatch-report.html" begin
        ps = problems(mktempdir())
        if !isempty(ps)
            foreach(p -> println("  ", p), ps)
            error("The committed README is out of date, run `julia _readme/make.jl` and commit the result")
        end
    end
else
    mv(rendered_markdown, committed_markdown, force = true)
    mv(rendered_figures, committed_figures, force = true)
end
