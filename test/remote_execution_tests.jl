using Distributed

all_procs = [1; workers()]

for i in all_procs
    remote_assgn(:a, :(myid()), i)
end

for i in all_procs
    remote_a = remote_exec(:a, i)
end

ch = Vector{Any}(undef, nprocs())
for i in workers()
    ch[i] = assigned_remote_channel(:ch, i, Int64, 3)
    put!(ch[i], i)
end

for i in workers()
    remote_val = remote_return(:(take!(ch)))
    remote_exec(:(put!(ch, i)))
end

for i in workers()
    local_val = take!(ch[i])
end