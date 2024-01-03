# TaijaParallel

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaTrustworthyAI.github.io/TaijaParallel.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaTrustworthyAI.github.io/TaijaParallel.jl/dev/)
[![Build Status](https://github.com/JuliaTrustworthyAI/TaijaParallel.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaTrustworthyAI/TaijaParallel.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/JuliaTrustworthyAI/TaijaParallel.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaTrustworthyAI/TaijaParallel.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

This package adds custom support for parallelization for certain [Taija](https://github.com/JuliaTrustworthyAI) packages.

## Installation

The stable version of this package can be installed as follows:

``` julia
using Pkg
Pkg.add("TaijaParallel.jl")
```

The development version can be installed like so:

``` julia
using Pkg
Pkg.add("https://github.com/JuliaTrustworthyAI/TaijaParallel.jl")
```

## Usage

Since this package extends the functionality of other Taija packages, it should be used in combination with those packages. For example, see this [tutorial](https://juliatrustworthyai.github.io/CounterfactualExplanations.jl/v0.1/tutorials/parallelization/) to see how `TaijaParallel.jl` can be used with `CounterfactualExplanations.jl`.

