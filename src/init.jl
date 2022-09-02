function mpiexec(f::Function, comm::Dict{AbstractComm})
    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = remotecall(f, i, comm)
    end
    fut
end