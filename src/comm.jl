using Distributed

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

    function BaseComm{T}(buf_size::Integer, group::CommGroup) where {T}
        ich = ChannelVector{T}(undef, nprocs(group))
        och = RemoteChannelVector{T}(undef, nprocs(group))
        new(ich, och, buf_size, group)
    end

end

BaseComm(::Type{T}=Any,
         buf_size::Integer=0,
         group::CommGroup=CommGroup()) where {T}
   = BaseComm{T}(buf_size, group)

Base.size(comm::BaseComm) = comm.buf_size

OptTuple{S, T} = Tuple{Union{Nothing, S}, T}

struct TaggedComm{S, T} <: AbstractComm{OptTuple{S, T}}

    comm::BaseComm{OptTuple{S, T}}
    group::CommGroup

    function TaggedComm{S, T}(buf_size::Integer, group::CommGroup) where {S, T}
        comm = BaseComm{OptTuple{S, T}}(buf_size, group)
        new(comm, group)
    end

end

TaggedComm(::Type{S}=Int64,
           ::Type{T}=Any,
           buf_size::Integer=1,
           group::CommGroup=CommGroup()) where {S, T}
   = TaggedComm{S, T}(buf_size, group)

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

CollectiveComm(::Type{T}=Any,
               group::CommGroup=CommGroup()) where {T}
    = CollectiveComm{T}(group)

struct GeneralComm{S, T} <: AbstractComm{T}

    comm::BaseComm{T}
    tagged::TaggedComm{S, T}
    collective::CollectiveComm{T}
    group::CommGroup

    function GeneralComm{S, T}(buf_size::Integer, group::CommGroup) where {S, T}
        comm = BaseComm{T}(buf_size, group)
        tagged = TaggedComm{S, T}(buf_size, group)
        collective = CollectiveComm{T}(group)
        new(comm, tagged, collective, group)
    end

end

GeneralComm(::Type{S}=Int64,
            ::Type{T}=Any,
            buf_size::Integer=0,
            group::CommGroup=CommGroup()) where {S, T}
   = GeneralComm{S, T}(buf_size, group)

Base.size(comm::GeneralComm) = Base.size(comm.comm)
