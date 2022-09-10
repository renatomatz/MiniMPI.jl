using Distributed
using Test

addprocs(3)

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using MiniMPI

    all_procs = 1:nprocs()
end

@everywhere begin
    COMM_DICT = CommDict()

    COMM_DICT[:base_0] = BaseComm()
    COMM_DICT[:base_1] = BaseComm(1)
    COMM_DICT[:tagged_1] = TaggedComm(Int64, Any, 1)
    COMM_DICT[:collective] = CollectiveComm()
    COMM_DICT[:ret_comm] = BaseComm(1)
end

@everywhere init_comm(:COMM_DICT)

@testset "MiniMPI.jl" begin
    for file in readlines(joinpath(@__DIR__, "testgroups"))
        include(file * ".jl")
    end
end