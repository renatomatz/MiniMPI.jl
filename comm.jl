using Distributed

CommMat = Matrix{RemoteChannel{Channel{T}}} where {T}

abstract type AbstractComm{T, N<:Integer} end

size(comm::AbstractComm{T, N}) where {N} = N

struct Comm{T, N<:Integer} <: AbstractComm{T, N}
    mat::CommMat{T}
    me::Int64
    p::Int64

    function Comm{T, N}(p::Integer) where {T, N<:Integer}
        # TODO: Make this matrix more targetted, such that refferences only
        # exist between valid indexes.
        mat = reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:p^2], (p,p))
        new(mat, myid(), p)
    end

    function Comm{T, N}() where {T, N<:Integer}
        Comm{T, N}(nprocs())
    end
end

const UnbufferedComm{T} = Comm{T, 0}

(Comm)(::Type{T}, N::Integer) where {T} = Comm{T, N}()
(Comm)(N::Integer) = Comm(Any, N)

(Comm)(::Type{T}) where {T} = Comm(T, 0)
(Comm)() = Comm(Any, 0)

getindex(comm::Comm, i...) = getindex(comm.mat, i...)
