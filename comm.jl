using Distributed

CommMat= Matrix{RemoteChannel{Channel{T}}} where {T}

struct Comm{T, N}
    mat::CommMat{T}
    me::Int64
    p::Int64
end

(Comm)(mat::CommMat{T}) = Comm{T, N}()
(Comm)(::Type{T}, N::Integer) = Comm{T, N}(CommMat(T, N, (nprocs(), nprocs())), myid(), nprocs())

(CommMat)(::Type{T}, N::Integer, shape::Tuple{Integer, Integer}) =
    reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:prod(shape)], shape)

getindex(comm::Comm, i...) = getindex(comm.mat, i...)

send(comm::Comm{T}, id::Integer, elem::T) where {T}= put!(comm[comm.me, id], elem)
recv(comm::Comm{T}, id::Integer, elem::T) where {T}= take!(comm[id, comm.me])
