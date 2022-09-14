using Distributed

# TODO: reconsider N as a necessary template parameter
abstract type AbstractComm{T} end

Base.eltype(::AbstractComm{T}) where {T} = T

nprocs(comm::AbstractComm) = nprocs(comm.group)
myid(comm::AbstractComm) = myid(comm.group)
ltog(comm::AbstractComm, li::Int64) = ltof(comm.group, li)

const CommDict = Dict{Symbol, AbstractComm}

RemoteChannelVector{T} = Vector{RemoteChannel{Channel{T}}} where {T}
ChannelVector{T} = Vector{Channel{T}} where {T}

struct BaseComm{T} <: AbstractComm{T}

    ich::ChannelVector{T}
    och::RemoteChannelVector{T}
    buf_size::Int64
    group::CommGroup

    function BaseComm{T}(buf_size::Int64, group::CommGroup) where {T}
        ich = ChannelVector{T}(undef, nprocs(group))
        och = RemoteChannelVector{T}(undef, nprocs(group))
        new(ich, och, buf_size, group)
    end

end

# TODO: Add more group initializers to BaseComm and other AbstractComm
# subtypes.

(BaseComm)(::Type{T}, buf_size::Integer) where {T} = BaseComm{T}(sz, CommGroup())
(BaseComm)(::Type{T}) where {T} = BaseComm(T, 0)
(BaseComm)(buf_size::Integer) = BaseComm(Any, buf_size)
(BaseComm)() = BaseComm(Any, 0)

Base.size(comm::BaseComm) = comm.buf_size

OptTuple{S, T} = Tuple{Union{Nothing}, T}

struct TaggedComm{S, T} <: AbstractComm{OptTuple{S, T}}

    comm::BaseComm{OptTuple{S, T}} where {S, T}
    group::CommGroup

    function TaggedComm{S, T}(buf_size::Int64, group::CommGroup) where {S, T}
        comm = BaseComm{OptTuple{S, T}}(buf_size, group)
        new(comm, group)
    end

end

(TaggedComm)(::Type{S}, ::Type{T}, buf_size::Integer) where {S, T} = TaggedComm{S, T}(buf_size, CommGroup())
(TaggedComm)(::Type{S}, ::Type{T}) where {S, T} = TaggedComm(S, T, 1)
(TaggedComm)(::Type{T}, buf_size::Integer) where {T} = TaggedComm(Int64, T, buf_size)
(TaggedComm)(::Type{T}) where {T} = TaggedComm(T, 1)
(TaggedComm)(buf_size::Integer) = TaggedComm(Int64, Any, buf_size)
(TaggedComm)() = TaggedComm(Any, 1)

Base.size(comm::TaggedComm) = Base.size(comm.comm)

struct CollectiveComm{T} <: AbstractComm{T}

    comm::BaseComm{T}
    vec_comm::BaseComm{Vector{T}}
    comm_lock::Base.AbstractLock

    barrier::BaseComm{Bool}
    bar_lock::Base.AbstractLock

    group::CommGroup

    function CollectiveComm{T}(group::CommGroup) where {T}
        comm = BaseComm{T}(0, group)
        vec_comm = BaseComm{Vector{T}}(0, group)
        comm_lock = Base.ReentrantLock()
        barrier = BaseComm{Bool}(1, group)
        bar_lock = Base.ReentrantLock()
        new(comm, vec_comm, comm_lock, barrier, bar_lock, group)
    end

end

(CollectiveComm)(::Type{T}) where {T} = CollectiveComm{T}(CommGroup())
(CollectiveComm)() = CollectiveComm(Any)

struct GeneralComm{S, T} <: AbstractComm{T}

    comm::BaseComm{T}
    tagged::TaggedComm{S, T}
    collective::CollectiveComm{T}
    group::CommGroup

    function GeneralComm{S, T}(buf_size::Int64, group::CommGroup) where {S, T}
        comm = BaseComm{T}(buf_size, group)
        tagged = TaggedComm{S, T}(buf_size, group)
        collective = CollectiveComm{T}(group)
        new(comm, tagged, collective, group)
    end

end

(GeneralComm)(::Type{S}, ::Type{T}, buf_size::Integer) where {S, T} = GeneralComm{S, T}(buf_size, CommGroup())
(GeneralComm)(::Type{S}, ::Type{T}) where {S, T} = GeneralComm(S, T, 0)
(GeneralComm)(::Type{T}, buf_size::Integer) where {T} = GeneralComm(Int64, T)
(GeneralComm)(::Type{T}) where {T} = GeneralComm(Int64, T, 0)
(GeneralComm)(buf_size::Integer) = GeneralComm(Int64, Any, buf_size)
(GeneralComm)() = GeneralComm(Any, 0)

Base.size(comm::GeneralComm) = Base.size(comm.comm)
