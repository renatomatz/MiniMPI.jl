using Test
using Distributed
using MiniMPI

@testset "Simple Initialization" begin

    @testset "Single Process" begin

        @everywhere comm = BaseComm(1)
        @everywhere init_comm(:comm)

        put!(comm.och[1], 1)
        ret = take!(comm.ich[1])
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

        # TODO: Create testing utils for expressions like this
        all_procs = ones(Int64, nprocs())
        if nprocs() > 1
            all_procs[2:end] = workers()
        end

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

end