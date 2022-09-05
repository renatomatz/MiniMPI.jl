using Test
using Distributed
using MiniMPI

@everywhere begin
    COMM = CommDict()
    COMM[:base] = BaseComm(1)
end

MiniMPI.init_comm()

ch = COMM[:base]

send(1, 1, COMM[:base])
ret = recv(1, COMM[:base])

addprocs(1)

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using MiniMPI
end

@everywhere begin
    COMM = CommDict()
    COMM[:base] = BaseComm(1)
end

MiniMPI.init_comm()

@everywhere ch = COMM[:base]

all_procs = ones(Int64, nprocs())
if nprocs() > 1
    all_procs[2:end] = workers()
end

for i in all_procs
    for j in all_procs
        MiniMPI.remote_return(:(send($i, $j, COMM[:base])), i)
    end
end

for i in all_procs
    for j in all_procs
        ret = MiniMPI.remote_return(:(recv($j, COMM[:base])), i)
        @test ret == j
    end
end
