using Distributed

function init_comm(name)
    init_comm_(Core.eval(Main, name), name)
end

function init_comm_(comm_dict::CommDict, name)
    for (key, comm) in comm_dict
        init_comm_(comm, ref_expr(name, key))
    end
end

function init_comm_(comm::AbstractComm, name)
    populate_channels(comm, name)
end

function populate_channels(comm::BaseComm{T}, name) where {T, N}
    for li in 1:nprocs(comm)
        comm.och[li] = assigned_remote_channel(
            ref_expr(dot_expr(name, :ich), myid(comm)),
            ltog(comm, li), T, size(comm)
        )
    end
end

function populate_channels(comm::TaggedComm, name)
    populate_channels(comm.comm, dot_expr(name, :comm))
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
