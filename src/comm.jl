using Distributed

abstract type AbstractComm{T, N} end

Base.size(::AbstractComm{T, N}) where {T, N} = N
Base.eltype(::AbstractComm{T, N}) where {T, N} = T

const CommDict = Dict{Symbol, AbstractComm}

RemoteChannelVector{T} = Vector{RemoteChannel{Channel{T}}} where {T}
ChannelVector{T} = Vector{Channel{T}} where {T}

struct BaseComm{T, N} <: AbstractComm{T, N}

    ich::ChannelVector{T}
    och::RemoteChannelVector{T}
    me::Int64
    p::Int64

    function BaseComm{T, N}(p::Integer) where {T, N}
        ich = ChannelVector{T}(undef, p)
        och = RemoteChannelVector{T}(undef, p)
        new(ich, och, myid(), p)
    end

    function BaseComm{T, N}() where {T, N}
        BaseComm{T, N}(nprocs())
    end

    # TODO: Create method for custom communication groups.
    #       Would mostly be the same initialization but parameter (me)
    #       would not necessarily be myid(), but rather some id relative
    #       to the communication group.
    #       One good way of implementing this is creating a named group struct
    #       that contains information about your position in a group. Instances
    #       of AbstractComm contain a reference to one of these.

end

(BaseComm)(::Type{T}, N::Integer) where {T} = BaseComm{T, N}()
(BaseComm)(::Type{T}) where {T} = BaseComm(T, 0)
(BaseComm)(N::Integer) = BaseComm(Any, N)
(BaseComm)() = BaseComm(Any, 0)

OptTuple{S, T} = Tuple{Union{S, Nothing}, T}

struct TaggedComm{S, T, N} <: AbstractComm{OptTuple{S, T}, N}

    comm::BaseComm{OptTuple{S, T}, N} where {S, T, N}
    me::Int64
    p::Int64

    function TaggedComm{S, T, N}(p::Integer) where {S, T, N}
        comm = BaseComm{OptTuple{S, T}, N}(p)
        new(comm, myid(), p)
    end

    function TaggedComm{S, T, N}() where {S, T, N}
        TaggedComm{S, T, N}(nprocs())
    end

end

(TaggedComm)(::Type{S}, ::Type{T}, N::Integer) where {S, T} = TaggedComm{S, T, N}()
(TaggedComm)(::Type{S}, ::Type{T}) where {S, T} = TaggedComm(S, T, 1)
(TaggedComm)(::Type{T}, N::Integer) where {T} = TaggedComm(Int64, T, N)
(TaggedComm)(::Type{T}) where {T} = TaggedComm(Int64, T, 1)
(TaggedComm)(N::Integer) = TaggedComm(Int64, Any, N)
(TaggedComm)() = TaggedComm(Any, 1)

struct CollectiveComm{T} <: AbstractComm{T, 0}

    comm::BaseComm{T, 0}
    vec_comm::BaseComm{Vector{T}, 0}
    comm_lock::Base.AbstractLock

    barrier::BaseComm{Bool, 1}
    bar_lock::Base.AbstractLock

    me::Int64
    p::Int64

    function CollectiveComm{T}(p::Integer) where {T}
        comm = BaseComm{T, 0}(p)
        vec_comm = BaseComm{Vector{T}, 0}(p)
        comm_lock = Base.ReentrantLock()
        barrier = BaseComm{Bool, 1}(p)
        bar_lock = Base.ReentrantLock()
        me = myid()
        p = p
        new(comm, vec_comm, comm_lock, barrier, bar_lock, me, p)
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

    function GeneralComm{S, T, N}(p::Integer) where {S, T, N}
        comm = BaseComm{T, N}(p)
        tagged = TaggedComm{S, T, N}(p)
        collective = CollectiveComm{T}(p)
        me = myid()
        p = p
        new(comm, tagged, collective, me, p)
    end

    function GeneralComm{S, T, N}() where {S, T, N}
        GeneralComm{S, T, N}(nprocs())
    end

end

(GeneralComm)(::Type{S}, ::Type{T}, N::Integer) where {S, T} = GeneralComm{S, T, N}()
(GeneralComm)(::Type{S}, ::Type{T}) where {S, T} = GeneralComm(S, T, 0)
(GeneralComm)(::Type{T}, N::Integer) where {T} = GeneralComm(Int64, T, N)
(GeneralComm)(::Type{T}) where {T} = GeneralComm(Int64, T, 0)
(GeneralComm)(N::Integer) = GeneralComm(Int64, Any, N)
(GeneralComm)() = GeneralComm(Any, 0)
