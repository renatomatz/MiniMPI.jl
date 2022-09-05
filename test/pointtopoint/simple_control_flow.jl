using Test
using Distributed
using MiniMPI

addprocs(1)

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using MiniMPI
end

@everywhere begin
    COMM = CommDict()
    COMM[:unbuf] = BaseComm()
    COMM[:buf] = BaseComm(1)
end

MiniMPI.init_comm()

@everywhere begin
    if COMM[:unbuf].me == 1
        send(42, 2, COMM[:unbuf])
    else
        ret = recv(1, COMM[:unbuf])
        println(ret)
    end
end