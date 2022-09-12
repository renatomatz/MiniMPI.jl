using Distributed

addprocs(2)

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using MiniMPI
end

@everywhere begin
    COMM_DICT = CommDict()
    COMM_DICT[:int_comm] = BaseComm(Int64)
    COMM_DICT[:ret_comm] = BaseComm(Float64)
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
        isend(float(res), 1, ret_comm)
    end

end

ret = recv(3, ret_comm)
ret == 42.0