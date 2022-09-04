function mpiexec(f::Function)

    init_comm()

    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = remotecall(f, i)
    end
    fut

end

function init_comm()

    @everywhere begin
        for (name, comm) in COMM
            #TODO: implement group comms
            MiniMPI.populate_channels(comm, MiniMPI.ref_expr(:COMM, QuoteNode(name)))
        end
    end

end

function populate_channels(comm::BaseComm{T, N}, name) where {T, N}
    for i in 1:comm.p
        #TODO: implement group comms
        comm.och[i] = assigned_remote_channel(
            ref_expr(dot_expr(name, QuoteNode(:ich)), comm.me),
            i, T, N
        )
    end
end

function populate_channels(comm::CollectiveComm, name)
    populate_channels(comm.comm, dot_expr(name, :comm))
    populate_channels(comm.vec_comm, dot_expr(name, :vec_comm))
    populate_channels(comm.barrier, dot_expr(name, :barrier))
end

function populate_channels(comm::GeneralComm, name)
    populate_channels(comm.comm, dot_expr(name, :comm))
    populate_channels(comm.tagged, dot_expr(name, :tagged))
    populate_channels(comm.collective, dot_expr(name, :collective))
end
