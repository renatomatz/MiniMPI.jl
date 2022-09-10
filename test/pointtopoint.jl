@testset "Point to Point" begin

    @everywhere comm = COMM_DICT[:base_1]

    send(1, 1, comm)
    ret = recv(1, comm)
    @test ret == 1

    #####

    for i in all_procs
        for j in all_procs
            MiniMPI.remote_return(:(send($i, $j, comm)), i)
        end
    end

    for i in all_procs
        for j in all_procs
            ret = MiniMPI.remote_return(:(recv($j, comm)), i)
            @test ret == j
        end
    end

    #####

    @everywhere begin

        comm = COMM_DICT[:base_0]
        ret_comm = COMM_DICT[:ret_comm]

        if comm.me == 1
            send(42, 2, comm)
        elseif comm.me == 2
            ret = recv(1, comm)
            send(ret, 1, ret_comm)
        end

    end

    ret = recv(2, ret_comm)
    @test ret == 42

    #####

    @everywhere begin

        comm = COMM_DICT[:tagged_1]
        ret_comm = COMM_DICT[:ret_comm]

        if comm.me == 1
            send(42, 2, 2, comm)
        elseif comm.me == 2
            ret = recv(1, 2, comm)
            send(ret, 1, ret_comm)
        end

    end

    ret = recv(2, ret_comm)
    @test ret == 42

end