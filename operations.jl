send(elem::T, id::Integer, comm::Comm{T}) where {T} = put!(comm[comm.me, id], elem)
recv(id::Integer, comm::Comm) = take!(comm[id, comm.me])

isend(elem::T, id::Integer, comm::Comm{T}) where {T} = @async send(comm, id)
irecv(id::Integer, comm::Comm) = @async recv(comm, id)

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
