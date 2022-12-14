function send(elem::T, dest::Integer, comm::BaseComm{T}) where {T}
    put!(comm.och[dest], elem)
end

function send(elem::T, dest::Integer, comm::TaggedComm{S, T}) where {S, T}
    send(elem, dest, nothing, comm)
end

function send(elem::T, dest::Integer, comm::GeneralComm{T}) where {T}
    send(elem, dest, comm.comm)
end

function send(elem::T, dest::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    send((tag, elem), dest, comm.comm)
end

function send(elem::T, dest::Integer, tag::S, comm::GeneralComm{S, T}) where {S, T}
    send(elem, dest, tag, comm.tagged)
end

function recv(src::Integer, comm::BaseComm)
    take!(comm.ich[src])
end

function recv(src::Integer, comm::GeneralComm)
    recv(src, comm.comm)
end

function recv(src::Integer, comm::TaggedComm{S, T}) where {S, T}
    recv(src, nothing, comm)
end

function recv(src::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    backlog = Vector{OptTuple{S, T}}()
    elem = nothing
    while true
        recv_tag, elem = recv(src, comm.comm)
        recv_tag == tag && break
        push!(backlog, (recv_tag, elem))
    end
    # TODO: This approach can cause the receiving image to get too much
    #       data, which imbalances memory usage between images.
    for belem in backlog
        # As tagged receives don't care for order, this approach won't cause
        # bugs from possibly miss-ordering channel elements.
        @async put!(comm.ich[src], belem)
    end
    elem
end

function recv(src::Integer, tag::S, comm::GeneralComm{S, T}) where {S, T}
    recv(src, tag, comm.tagged)
end

function isend(elem::T, dest::Integer, comm::BaseComm{T}) where {T}
    @async send(elem, dest, comm)
end

function isend(elem::T, dest::Integer, comm::GeneralComm{T}) where {T}
    isend(src, dest, comm.comm)
end

function isend(elem::T, dest::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    @async send(elem, dest, tag, comm)
end

function isend(elem::T, dest::Integer, tag::S, comm::GeneralComm{S, T}) where {S, T}
    isend(elem, dest, tag, comm.tagged)
end

function irecv(src::Integer, comm::BaseComm)
    @async recv(comm, src)
end

function irecv(src::Integer, comm::GeneralComm)
    irecv(src, comm.comm)
end

function irecv(src::Integer, tag::S, comm::TaggedComm{S, T}) where {S, T}
    @async recv(src, tag, comm)
end

function irecv(src::Integer, tag::S, comm::GeneralComm{S, T}) where {S, T}
    irecv(src, tag, comm.tagged)
end

# TODO: allow for symbol lookup of communicators from global COMM
