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
    COMM_DICT[:unbuf] = TaggedComm(Int64, Any, 1)
    COMM_DICT[:ret] = BaseComm(1)
end

@everywhere init_comm(:COMM_DICT)

@everywhere begin

   comm = COMM_DICT[:unbuf]
   ret_comm = COMM_DICT[:ret]

   if comm.me == 1
       send(42, 2, 2, comm)
   else
       ret = recv(1, 2, comm)
       send(ret, 1, ret_comm)
   end

end

ret = recv(2, ret_comm)
println(ret)
@test ret == 42