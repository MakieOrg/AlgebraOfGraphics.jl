# Contributing

Thanks for your interest in contributing to AlgebraOfGraphics.jl! The package is part of the [Makie ecosystem](https://github.com/MakieOrg) and follows the [Julia Community Standards](https://julialang.org/community/standards/).

## Getting help

For usage questions, please don't open GitHub issues. Instead, ask on the [Julia Discourse forum](https://discourse.julialang.org/) (tag your post with `aog` or `makie`) or in the `#makie` channel on the [Julia Slack](https://julialang.org/slack/).

## Reporting bugs

Please report bugs as [GitHub issues](https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues). Check first whether an issue for your problem already exists. A good bug report includes:

- A minimal reproducible example with a small self-contained dataset, so the code can be run as-is.
- The versions of Julia, AlgebraOfGraphics, and Makie you are using (`import Pkg; Pkg.status()`).
- For visual bugs, a screenshot or saved image of the incorrect output.

## Pull requests

Pull requests are welcome, you don't need to open an issue first. If your code isn't ready yet or you want feedback on the direction before investing more time, open a draft PR or an issue for discussion.

Contributions made with the help of AI tools are fine, but you should understand the code you submit and be able to discuss it in review.

PRs are squash-merged, so the commit history doesn't have to be perfect, but a reasonably clean history makes review easier.

## Development

- **Tests**: Run the test suite with `Pkg.test()` or, for a faster loop during development, include individual files from `test/` in a session using the `test` environment. Unit tests live in `test/*.jl`, reference image tests in `test/reference_tests.jl`. Prefer unit tests for AlgebraOfGraphics's internal machinery (do these values convert correctly, etc.) and reference tests for larger integration features (does this render correctly, does Makie handle the output as expected). If your change intentionally alters plot output, regenerate the reference images by running the reference tests with `ENV["UPDATE_REFIMAGES"] = "true"` and commit the changed images.
- **Formatting**: Format your changes with `julia tooling/formatter/format.jl` before submitting.
- **Changelog**: Add a short entry to `CHANGELOG.md` for user-facing changes, with a link to your PR. If no entry is necessary, add the `skip-changelog` label to the PR.
- **Docs**: Build the documentation locally with `julia --project=docs docs/make.jl`.
- **Readme**: `README.md` is generated from `_readme/README.qmd` with [Quarto](https://quarto.org/), which comes from `quarto_jll` so no local installation is needed. If you change the readme or the output of the example code it contains, regenerate it with `julia _readme/make.jl` and commit the result. CI renders the readme again and fails if the committed markdown differs or if the committed images don't match the rendered ones pixel by pixel.
