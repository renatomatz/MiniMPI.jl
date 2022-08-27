function send(elem::T, dest::Integer, comm::Comm{T}) where {T}
     put!(comm[comm.me, dest], elem)
end

function recv(src::Integer, comm::Comm)
    take!(comm[src, comm.me])
end

function isend(elem::T, dest::Integer, comm::Comm{T}) where {T}
    @async send(comm, dest)
end

function irecv(src::Integer, comm::Comm)
    @async recv(comm, src)
end

const TaggedComm{S, T, N} = Comm{Tuple{S, T}, N} where {T, N}

function send(elem::T, dest::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    send((tag, elem), dest, comm)
end

function recv(src::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    backlog = Vector{Tuple{S, T}}()
    while true
        recv_tag, elem = recv(src, comm)
        recv_tag == tag && break
        push!(backlog, (recv_tag, elem))
    end
    # TODO: This approach can cause the receiving image to get too much
    #       data, which imbalances memory usage between images.
    for elem in backlog
        # As tagged receives don't care for order, this approach won't cause
        # bugs from possibly miss-ordering channel elements.
        @async put!(comm[src, comm.me], elem)
    end
end

function isend(elem::T, dest::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    @async send(elem, dest, tag, comm)
end

function irecv(src::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    @async recv(src, tag, comm)
end
