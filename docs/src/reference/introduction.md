# Introduction

Layers are the key building blocks of AlgebraOfGraphics.
Each layer is the product of the following elementary objects.

- [Data](@ref) (encoding the dataset).
- [Mapping](@ref) (associating variables to plot attributes).
- [Visual](@ref) (encoding data-independent plot information).
- [Analyses](@ref) (encoding transformations that are applied to the data before plotting).

Data, mappings, visuals and analyses can be combined together using [Algebraic Operations](@ref)
to form one or more layers.

The output of these algebraic operations can be visualized, as shown in the section
[Drawing Layers](@ref).
