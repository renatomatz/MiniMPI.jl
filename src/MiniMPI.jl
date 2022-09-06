module MiniMPI

include("utils.jl")
include("comm.jl")
include("init.jl")
include("pointtopoint.jl")

export

    # Communicator types
    AbstractComm,
    BaseComm,
    UnbufferedComm,
    TaggedComm,
    CollectiveComm,
    GeneralComm,

    # Type Shortcuts
    CommDict,
    RemoteChannelVector,

    # Initializers
    init_comm,

    # Point to point communication
    send,
    recv

end