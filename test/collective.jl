@testset "Collective" begin

    ch = RemoteChannel(()->Channel{Any}(2*nprocs()))
    @everywhere ch = $ch

    @everywhere begin

        comm = COMM_DICT[:collective]

        put!(ch, 1)
        sleep(myid()/nprocs())
        barrier(comm)
        put!(ch, 2)

    end

    for i in 1:2
        for j in 1:nprocs()
            ret = take!(ch)
            @test ret == i
        end
    end

    #####

    @everywhere begin

        comm = COMM_DICT[:collective]
        ret_comm = COMM_DICT[:ret_comm]

        elem = myid()
        ret = bcast(elem, 1, comm)
        send(ret, 1, ret_comm)

    end

    for i in 1:comm.p
        ret = recv(i, ret_comm)
        @test ret == 1
    end

    #####

    @everywhere begin
        elem = myid()
        ret = reduc(elem, Base.:+, 1, comm)
    end

    @test ret == sum(1:nprocs())

end