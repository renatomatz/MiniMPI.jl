@testset "Initialization" begin

    comm = COMM_DICT[:base_1]

    put!(comm.och[1], 1)
    ret = take!(comm.ich[1])
    @test ret == 1

    #####

    @everywhere comm = COMM_DICT[:base_1]

    for i in all_procs
        for j in all_procs
            MiniMPI.remote_return(:(put!(comm.och[$j], $i)), i)
        end
    end

    for i in all_procs
        for j in all_procs
            ret = MiniMPI.remote_return(:(take!(comm.ich[$j])), i)
            @test ret == j
        end
    end

end