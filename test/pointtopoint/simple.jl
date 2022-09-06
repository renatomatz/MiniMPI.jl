using Test
using Distributed
using MiniMPI

@testset "Point to Point" begin

    @testset "One Process" begin

        @everywhere comm = BaseComm(1)
        @everywhere init_comm(:comm)

        send(1, 1, comm)
        ret = recv(1, comm)
        @test ret == 1

    end

    @testset "Multiple Processes" begin

        addprocs(1)

        @everywhere begin
            using Pkg
            Pkg.activate(".")
            using MiniMPI
        end

        @everywhere comm = BaseComm(1)
        @everywhere init_comm(:comm)

        all_procs = ones(Int64, nprocs())
        if nprocs() > 1
            all_procs[2:end] = workers()
        end

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

    end

end