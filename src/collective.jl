# TODO: Add support for GeneralComm


function barrier(comm::CollectiveComm)
    lock(comm.bar_lock)
    for i in 1:comm.p
        send(true, i, comm.barrier)
    end
    for i in reverse(1:comm.p)
        recv(i, comm.barrier)
    end
    unlock(comm.bar_lock)
end

function bcast(elem::T, src::Integer, comm::CollectiveComm{T}) where {T}
    lock(comm.comm_lock)
    if comm.me == src
        for i in 1:comm.p
            if i != comm.me
                send(elem, i, comm.comm)
            end
        end
        ret = elem
    else
        ret = bcast_recv(src, comm)
    end
    unlock(comm.comm_lock)
    ret
end

function bcast(src::Integer, comm::CollectiveComm)
    lock(comm.comm_lock)
    comm.me == src || error("source image must specify an element")
    ret = bcast_recv(src, comm)
    unlock(comm.comm_lock)
    ret
end

function bcast_recv(src::Integer, comm::CollectiveComm)
    recv(src, comm.comm)
end

function reduce(elem::T, op::Function, dest::Integer, comm::CollectiveComm{T}) where {T}

    lock(comm.comm_lock)
    p = comm.p
    me = comm.me

    L = 1
    this = elem
    while L < p
        if (me+L <= p) & (mod(me-1, 2*L) == 0)
            other = recv(me+L, comm.comm)
            this = op(this, other)
        elseif mod(me-L-1, 2*L) == 0
            send(this, me-L, comm.comm)
        end
        L *= 2
        barrier(comm)
    end

    if me == 1
        send(this, dest, comm.comm)
    end
    if me == dest
        this = recv(1, comm.comm)
    end

    unlock(comm.comm_lock)

    this

end
