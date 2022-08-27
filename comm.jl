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
        mat = make_comm_mat(T, N, p)
        new(mat, myid(), p)
    end

    function Comm{T, N}() where {T, N<:Integer}
        Comm{T, N}(nprocs())
    end
end

function make_comm_mat(::Type{T}, N::Integer, p::Int64)
    reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:p^2], (p,p))
end

(Comm)(::Type{T}, N::Integer) where {T} = Comm{T, N}()
(Comm)(N::Integer) = Comm(Any, N)

(Comm)(::Type{T}) where {T} = Comm(T, 0)
(Comm)() = Comm(Any, 0)

getindex(comm::Comm, i...) = getindex(comm.mat, i...)

const UnbufferedComm{T} = Comm{T, 0} where {T}

(UnbufferedComm)(t::Type{T}) where {T} = Comm(t)
(UnbufferedComm)() = Comm()

struct CollectiveComm{T} <: AbstractComm{T, 0}
    comm::Comm{T, 0}
    barrier::CommMat{Bool, 1}
    me::Int64
    p::Int64

    function CollectiveComm{T}(p::Integer) where {T}
        comm = Comm{T, 0}(p)
        barrier = Comm{Bool, 1}(p)
        me = myid()
        p = p
        new(comm, barrier)
    end

    function CollectiveComm{T}() where {T}
        CollectiveComm{T}(nprocs())
    end
end

(CollectiveComm)(::Type{T}) where {T} = CollectiveComm{T}()
(CollectiveComm)() = CollectiveComm(Any)
