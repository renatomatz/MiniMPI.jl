using Distributed

@everywhere begin
    using MiniMPI

    comm = Dict([
        ("int_1", Comm(Int64, 1)),
        ("int_0", Comm(Int64)),
        ("any_1", Comm(1)),
        ("any_0", Comm()),
        ("any_tag_0", TaggedComm(Any, Any, 1)),
        ("any_tag", TaggedComm()),
    ])
end
