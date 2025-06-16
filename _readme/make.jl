cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.develop(path = "..")
Pkg.precompile()

run(`quarto render README.qmd`)
mv("README.md", "../README.md", force = true)
mv("README_files/", "../README_files/", force = true)
