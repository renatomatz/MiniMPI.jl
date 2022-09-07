using Test
using Distributed
using MiniMPI

addprocs(1)

@everywhere begin
    using Pkg; Pkg.activate(".")
    using MiniMPI
end

@everywhere begin
    COMM_DICT = CommDict()
    COMM_DICT[:collective] = CollectiveComm()
    COMM_DICT[:res] = BaseComm(nprocs())
end

@everywhere init_comm(:COMM_DICT)

@everywhere begin

    comm = COMM_DICT[:collective]
    res_comm = COMM_DICT[:res]

    elem = myid()
    res = bcast(elem, 1, comm)
    send(res, 1, res_comm)

end

for i in 1:comm.p
    res = recv(i, res_comm)
end