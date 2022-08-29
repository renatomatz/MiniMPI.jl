function mpiexec(f::Function, comm::Dict{AbstractComm})
    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = remotecall(f, i, comm)
    end
    fut
end

function make_comm_mat(::Type{T}, N::Integer, p::Int64)
    reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:(p^2)], (p,p))
end
