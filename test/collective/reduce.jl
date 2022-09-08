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
    elem = myid()
    res = reduce(elem, Base.:+, 1, comm)
end

println(res)