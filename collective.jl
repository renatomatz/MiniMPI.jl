function barrier(comm::BarrierComm)
    for i in 1:comm.p
        send(comm.barrier, i, true)
    end
    for i in reverse(1:comm.p)
        recv(comm.barrier, i)
    end
end

function bcast(elem::T, src::Integer, comm::CollectiveComm{T}) where {T}
    if comm.me == src
        for i in 1:comm.p
            if i != comm.me
                send(elem, i, comm.comm)
            end
        end
    else
        bcast_recv(src, comm)
    end
end

function bcast(src::Integer, comm::CollectiveComm)
    comm.me == src || "source image must specify an element"
    bcast_recv(src, comm)
end
bcast_recv(src::Integer, comm::CollectiveComm) = recv(src, comm)

function reduce(elem::T, dest::Integer, op::Function, comm::CollectiveComm{T}) where {T}
    p = comm.p
    me = comm.me
    L = 1
    this = elem
    while (L < p)
        if (me <= p & mod(me-1, 2*L) == 0)
            other = recv(me+L, comm)
            this = op(this, other)
        else
            send(this, me-L, comm)
        end
        L *= 2
        barrier(comm)
    end
    if me == 1
        send(this, dest, comm)
    end
    if me == dest
        this = recv(1, comm)
    end
    this
end
