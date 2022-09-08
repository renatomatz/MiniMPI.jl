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

function reduc(elem::T, op::Function, dest::Integer, comm::CollectiveComm{T}) where {T}

    lock(comm.comm_lock)

    p = comm.p
    me = comm.me

    mid, gap = 1, 2
    this = elem
    while mid < p
        if (me+mid <= p) & (mod(me-1, gap) == 0)
            # First condition: process that would send data is valid
            # Second condition: this process is in the start of a gap
            other = recv(me+mid, comm.comm)
            this = op(this, other)
        elseif mod(me-mid-1, gap) == 0
            # Condition: process that would receive data is in the start of
            #            a gap.
            # If process gets here, it is implied it is valid.
            send(this, me-mid, comm.comm)
        end
        mid, gap = gap, gap*2
        barrier(comm)
    end

    if dest != 1
        # If dest is 1, no need to send result to itself
        if me == 1
            # Results are condensed at 1, so it must be sent to the
            # destination.
            send(this, dest, comm.comm)
        end
        if me == dest
            this = recv(1, comm.comm)
        end
    end

    unlock(comm.comm_lock)

    this

end
