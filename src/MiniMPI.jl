module MiniMPI

include("utils.jl")
include("comm.jl")
include("init.jl")

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
    mpiexec

end