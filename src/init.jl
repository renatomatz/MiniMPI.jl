function mpiexec(f::Function, comm::Dict{AbstractComm})
    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = remotecall(f, i, comm)
    end
    fut
end

function make_name(comm::BaseComm{T, N}) where {T, N}
end

function populate_channels(comm::BaseComm{T, N}) where {T, N}
    for i in 1:comm.p
        # create a way of making names
        name = make_name(comm)
        comm.och[i] = assigned_remote_channel(name, i, T, N)
        # This executes remotely but creates a channel locally
        name = :($name[$i])
        remote_exec(:(assigned_remote_channel(name, 1, $T, $N)), i)
    end
end

function populate_channels(comm::CollectiveComm)
    populate_channels(comm.comm)
    populate_channels(comm.vec_comm)
    populate_channels(comm.barrier)
end

function populate_channels(comm::GeneralComm)
    populate_channels(comm.comm)
    populate_channels(comm.tagged)
    populate_channels(comm.collective)
end
