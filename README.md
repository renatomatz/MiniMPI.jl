# MiniMPI.jl
## Basic MPI implemented in Julia

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://renatomatz.github.io/MiniMPI.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://renatomatz.github.io/MiniMPI.jl/dev)
[![Build Status](https://github.com/renatomatz/MiniMPI.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/renatomatz/MiniMPI.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/renatomatz/MiniMPI.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/renatomatz/MiniMPI.jl)

MiniMPI.jl implements basic features of the Message Passing Interface (MPI) using only the Julia standard library, with Distributed.jl as its backbone. This is not meant to replace MPI.jl in any way, but rather serve as a natively implemented tool for simple workflows in mostly sequential Julia code.
