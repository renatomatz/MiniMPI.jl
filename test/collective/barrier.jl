using Test
using Distributed
using MiniMPI

addprocs(1)

@everywhere begin
    using Pkg; Pkg.activate(".")
    using MiniMPI
end

@everywhere comm = CollectiveComm()

@everywhere init_comm(:comm)

@everywhere begin

    println("IN")
    barrier(comm)
    println("OUT")

end