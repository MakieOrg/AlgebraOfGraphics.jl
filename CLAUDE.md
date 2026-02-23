# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Code Formatting

Format code using `julia tooling/formatter/format.jl`.

## Changelog

Each PR with meaningful user-facing changes needs an entry in `CHANGELOG.md`.

## Testing

Tests are split into **unit tests** (`test/*.jl`) and **reference tests** (`test/reference_tests.jl` with images in `test/reference_tests/`).

- Prefer unit tests for internal mechanics and invariants.
- Only add reference images when a complex interplay of features needs to be validated end-to-end (e.g., a new plot type exercising the full pipeline from data ingestion to Makie rendering). Reference tests ensure the final plot output never changes unintentionally.
- Do not use random numbers in tests. Manually specify small, parsimonious datasets that a human can easily check against visual output.
- The full test suite is heavy. During development, run only the relevant test files or snippets interactively (e.g., via julia-mcp) before running the full suite.
