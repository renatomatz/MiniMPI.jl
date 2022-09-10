@testset "Remote Execution" begin

    for i in all_procs
        ret = MiniMPI.remote_asgn(:a, :(myid()), i)
        @test ret == i
    end

    for i in all_procs
        ret = MiniMPI.remote_return(:a, i)
        @test ret == i
    end

    #####

    rch = Vector{Any}(undef, nprocs())
    for i in all_procs
        rch[i] = MiniMPI.assigned_remote_channel(:ch, i, Int64, 3)
        put!(rch[i], i)
    end

    for i in all_procs
        ret = MiniMPI.remote_return(:(take!(ch)), i)
        @test ret == i
        MiniMPI.remote_return(:(put!(ch, $i)), i)
    end

    for i in all_procs
        ret = take!(rch[i])
        @test ret == i
    end

end