# Algebraic Operations

There are two _algebraic types_ that can be added or multiplied with each other:
[`AlgebraOfGraphics.Layer`](@ref) and [`AlgebraOfGraphics.Layers`](@ref).

## Multiplication on individual layers

Each layer is composed of data, mappings, and transformations.
Datasets can be replaced, mappings can be merged, and transformations can be
concatenated. These operations, taken together, define an associative operation
on layers, which we call multiplication `*`.

Multiplication is primarily useful to combine partially defined layers.

## Addition

The operation `+` is used to superimpose separate layers. `a + b` has as many
layers as `la + lb`, where `la` and `lb` are the number of layers in `a` and `b`
respectively.

## Multiplication on lists of layers

Multiplication naturally extends to lists of layers. Given two `Layers` objects
`a` and `b`, containing `la` and `lb` layers respectively, the product `a * b`
contains `la * lb` layers—all possible pair-wise products.
