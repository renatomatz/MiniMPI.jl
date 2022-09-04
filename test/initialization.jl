using Test
using Distributed
using MiniMPI

COMM = CommDict()
COMM[:base] = BaseComm(1)

MiniMPI.init_comm()

ch = COMM[:base]

put!(ch.och[1], 1)
ret = take!(ch.ich[1])

addprocs(1)

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using MiniMPI

@everywhere begin
    COMM = CommDict()
    COMM[:base] = BaseComm(1)
end

MiniMPI.init_comm()

ch = COMM[:base]

# TODO: Create testing utils for expressions like this
all_procs = ones(Int64, nprocs())
if nprocs() > 1
    all_procs[2:end] = workers()
end

for i in all_procs
    MiniMPI.remote_return(:(put!(ch.och, $i)), i)
end

for i in all_procs
    ret = MiniMPI.remote_return(:(take(ch.ich)), i)
end

for i in workers()

println("DONE")