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

(UnbufferedComm)(::Type{T}) where {T} = BaseComm(T)
(UnbufferedComm)() = UnbufferedComm(Any)

const TaggedComm{S, T, N} = BaseComm{Tuple{S, T}, N} where {T, N}

(TaggedComm)(::Type{S}, ::Type{T}, N::Integer) where {S, T} = TaggedComm{S, T, N}()
(TaggedComm)(::Type{S}, ::Type{T}) where {S, T} = TaggedComm(S, T, 0)
(TaggedComm)(::Type{T}, N::Integer) where {T} = TaggedComm(Int64, T, N)
(TaggedComm)(::Type{T}) where {T} = TaggedComm(Int64, T, 0)
(TaggedComm)(N::Integer) = TaggedComm(Int64, Any, N)
(TaggedComm)() = TaggedComm(Any, 0)

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

struct GeneralComm{S, T, N} <: AbstractComm{T, N}

    comm::BaseComm{T, N}
    tagged::TaggedComm{S, T, N}
    collective::CollectiveComm{T}

    me::Int64
    p::Int64

    function GeneralComm{T, N}(p::Integer) where {T, N}
        comm = BaseComm{T, N}(p)
        tagged = TaggedComm{S, T, N}(p)
        collective = CollectiveComm{T}(p)
        me = myid()
        p = p
        new(comm, tagged, collective, me, p)
    end

    function GeneralComm{T, N}() where {T, N}
        GeneralComm{T, N}(nprocs())
    end

end

(GeneralComm)(::Type{S}, ::Type{T}, N::Integer) where {S, T} = GeneralComm{S, T, N}()
(GeneralComm)(::Type{S}, ::Type{T}) where {S, T} = GeneralComm(S, T, 0)
(GeneralComm)(::Type{T}, N::Integer) where {T} = GeneralComm(Int64, T, N)
(GeneralComm)(::Type{T}) where {T} = GeneralComm(Int64, T, 0)
(GeneralComm)(N::Integer) = GeneralComm(Int64, Any, N)
(GeneralComm)() = GeneralComm(Any, 0)
