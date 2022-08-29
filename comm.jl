using Distributed

abstract type AbstractComm{T, N<:Integer} end

Base.size(::AbstractComm{T, N}) where {N} = N
Base.eltype(::AbstractComm{T, N}) where {T} = T

struct BaseComm{T, N<:Integer} <: AbstractComm{T, N}

    mat::Matrix{RemoteChannel{Channel{T}}}
    me::Int64
    p::Int64

    function BaseComm{T, N}(p::Integer) where {T, N<:Integer}
        # TODO: Make this matrix more targetted, such that refferences only
        # exist between communicating processes.
        mat = make_comm_mat(T, N, p)
        new(mat, myid(), p)
    end

    function BaseComm{T, N}() where {T, N<:Integer}
        BaseComm{T, N}(nprocs())
    end

    # TODO: Create method for custom communication groups.
    #       Would mostly be the same initialization but parameter (me)
    #       would not necessarily be myid(), but rather some id relative
    #       to the communication group.

end

(BaseComm)(::Type{T}, N::Integer) where {T} = BaseComm{T, N}()
(BaseComm)(::Type{T}) where {T} = BaseComm(T, 0)
(BaseComm)(N::Integer) = BaseComm(Any, N)
(BaseComm)() = BaseComm(Any, 0)

getindex(comm::BaseComm, i...) = getindex(comm.mat, i...)

const UnbufferedComm{T} = BaseComm{T, 0} where {T}

(UnbufferedComm)(t::Type{T}) where {T} = BaseComm(t)
(UnbufferedComm)() = UnbufferedComm(Any)

const TaggedComm{S, T, N} = BaseComm{Tuple{S, T}, N} where {T, N}

struct CollectiveComm{T} <: AbstractComm{T, 0}

    comm::BaseComm{T, 0}
    vec_comm::BaseComm{Vector{T}, 0}
    barrier::BaseComm{Bool, 1}
    mux::Base.AbstractLock

    me::Int64
    p::Int64

    function CollectiveComm{T}(p::Integer) where {T}
        comm = BaseComm{T, 0}(p)
        vec_comm = BaseComm{Vector{T}, 0}(p)
        barrier = BaseComm{Bool, 1}(p)
        mux = Base.ReentrantLock()
        me = myid()
        p = p
        new(comm, vec_comm, barrier, mux)
    end

    function CollectiveComm{T}() where {T}
        CollectiveComm{T}(nprocs())
    end

end

(CollectiveComm)(::Type{T}) where {T} = CollectiveComm{T}()
(CollectiveComm)() = CollectiveComm(Any)

struct GeneralComm{T, N} <: AbstractComm{T, N}

    comm::BaseComm{T, N}
    tagged::TaggedComm{Int64, T, N}
    collective::CollectiveComm{T}

    me::Int64
    p::Int64

    function GeneralComm{T, N}(p::Integer) where {T, N}
        comm = BaseComm{T, N}(p)
        tagged = TaggedComm{Int64, T, N}(p)
        collective = CollectiveComm{T}(p)
        me = myid()
        p = p
        new(comm, tagged, collective, me, p)
    end

    function GeneralComm{T, N}() where {T, N}
        GeneralComm{T, N}(nprocs())
    end

end

(GeneralComm)(::Type{T}, N::Integer) where {T} = GeneralComm{T, N}()
(GeneralComm)(::Type{T}) where {T} = GeneralComm(T, 0)
(GeneralComm)(N::Integer) = GeneralComm(Any, N)
(GeneralComm)() = GeneralComm(Any, 0)