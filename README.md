<div style="text-align: center;">
![logo](/images/logo.png)
</div>

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://renatomatz.github.io/MiniMPI.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://renatomatz.github.io/MiniMPI.jl/dev)
[![Build Status](https://github.com/renatomatz/MiniMPI.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/renatomatz/MiniMPI.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/renatomatz/MiniMPI.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/renatomatz/MiniMPI.jl)

MiniMPI.jl implements basic features of the Message Passing Interface (MPI) implemented with the Julia standard library, with Distributed.jl as its backbone. Keeping things native to Julia means that using MiniMPI does not require users to have an implementation of the MPI standard installed, nor any additional libraries beyond what is included with Julia. This library is not meant to replace MPI.jl in any way, but rather serve as a natively implemented tool for simple workflows in mostly sequential Julia code.

As this is not a wrapper of the MPI library in C, much of the syntax and names from the MPI standard are changed to suit the structure of Julia code. As a simple example, both tagged and untagged communication is possible through `BaseComm` and `TaggedComm` objects, respectfully, while `GeneralComm` allows for both. Additionally, users can specify the type and buffer size of each communicator. This possibility to specialize communication channels allows for more efficient communications, and conforms to the paradigm exposed by the Distributed library. Keeping the implementaion native to Julia also means that the usual structure of an MPI program needs to be adapted to use available structures, as is shown in the examples below.

## Example 1: Simple Point-to-Point operations

To illustrate a minimal program using MiniMPI, we begin with a simple send and receive operation between two processes.

```julia
using Distributed

addprocs(1)

@everywhere using MiniMPI

@everywhere comm = BaseComm(Int64)

@everywhere init_comm(:comm)

@everywhere begin
    if comm.me == 2
        send(42, 1, comm)
    elseif comm.me == 1
        ret = recv(2, comm)
    end
end

ret == 42
```

The three steps to running this and most other programs in MiniMPI, after the processed are added and the library is imported is as follows:

1. Create communicator objects.
2. Initialize communicators.
3. Execute distributed script.

Note that each of these steps must be performed in **separate** `@everywhere` blocks due to its intrinsic syncronization. That is, for the program to be executed, the communicators must be inizialized in all processes, and for the communicators to be initialized, all processors must have the communicators defined on the global scope. While this seems verbose for a simple example as above, thise three steps are the same regardless of the number of communicators and size of the program.

This example also illustrates how by the end of a distributed segment, all globally-defined variables remain accessible to each process, which allows for any sequental code that follows to use them. It is also important to note that any subsequent distributed block will also have access to the previously-defined global variables.

A similar but slightly more involved point-to-point example could go as follows:

```julia
using Distributed

addprocs(2)

@everywhere using MiniMPI

@everywhere begin
    COMM_DICT = CommDict()
    COMM_DICT[:int_comm] = BaseComm(Int64)
    COMM_DICT[:ret_comm] = BaseComm(1)
end

@everywhere init_comm(:COMM_DICT)

@everywhere begin

    comm = COMM_DICT[:int_comm]
    ret_comm = COMM_DICT[:ret_comm]

    if comm.me == 1
        send(42, 2, comm)
    elseif comm.me == 2
        res = recv(1, comm)
        send(res, 3, comm)
    elseif comm.me == 3
        res = recv(2, comm)
        send(float(res), 1, ret_comm)
    end

end

ret = recv(3, ret_comm)
ret == 42.0
```

In this example we add a new process to program and define a buffered `BaseComm` within a `CommDict` (which is just an alias for `Dict{Symbol, AbstractComm}`). As of this version, the initializer routine allows for symbols naming either an `AbstractComm` or a `CommDict`, with additional containers to be added in the future.

One small yet significant detail of the above example is the _need_ for the buffered communicator initialized with `BaseComm(1)`; as the `@everywhere` block requires all processes to finish before exiting, the third process cannot block on its send to `ret_comm` in order for the first process to perform a receive operation outside of the `@everywhere` block. There are several ways to solve this, including using the non-blocking `isend`, or, in the spirit of the first example, use

```julia
using Distributed

addprocs(2)

@everywhere using MiniMPI

@everywhere comm = BaseComm()

@everywhere init_comm(:comm)

@everywhere begin

    if comm.me == 1
        send(42, 2, comm)
        ret = recv(3, comm)
    elseif comm.me == 2
        res = recv(1, comm)
        send(res, 3, comm)
    elseif comm.me == 3
        res = recv(2, comm)
        send(float(res), 1, comm)
    end

end

ret == 42.0
```

where we define the global variable `ret` on the first process and access it outside of the `@everywhere` block. This could also be considered cleaner, as we keep all inter-process communications within the `@everywhere` block.
