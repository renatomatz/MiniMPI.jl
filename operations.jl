send(elem::T, id::Integer, comm::Comm{T}) where {T} = put!(comm[comm.me, id], elem)
recv(id::Integer, comm::Comm) = take!(comm[id, comm.me])

isend(elem::T, id::Integer, comm::Comm{T}) where {T} = @async send(comm, id)
irecv(id::Integer, comm::Comm) = @async recv(comm, id)

# TODO: Allow for custom tag type
const TaggedComm{T, N} = Comm{Tuple{Integer, T}, N} where {T, N}

send(elem::T, id::Integer, tag::Integer, comm::TaggedComm{T}) where {T} =
    send(comm, id, (tag, elem))

function recv(id::Integer, tag::Integer, comm::TaggedComm{T}) where {T}
    backlog = Vector{Tuple{Integer, T}}()
    while true
        recv_tag, elem = recv(comm, id)
        recv_tag == tag && break
        push!(backlog, (recv_tag, elem))
    end
    # TODO: Solve potential bug:
    # buffer size: 0; sender: x; receiver: y
    # x: isend(1, y, 1, comm)
    # x: send(0, y, 0, comm)
    # y: recv(y, 0, comm)
    #    backlog = [1]
    #    BUG: put! blocks
    for elem in backlog
        put!(comm[id, comm.me], elem)
    end
end

make_barrier() = Comm(::Bool, 1)

function barrier(comm::Comm{Bool, 1})
    for i in 1:comm.p
        send(comm, i, true)
    end
    for i in reverse(1:comm.p)
        recv(comm, i)
    end
end

function broadcast(elem::T, comm::Comm{T}) where {T}

end
