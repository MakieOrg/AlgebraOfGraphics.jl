using Documenter, AlgebraOfGraphics, Literate

# generate examples
GENERATED = joinpath(@__DIR__, "src", "generated")
Literate.markdown(joinpath(GENERATED, "tutorial.jl"), GENERATED)

makedocs(
         sitename="Algebra of Graphics",
         pages = Any[
                     "index.md",
                     "generated/tutorial.md"
                    ]
        )
