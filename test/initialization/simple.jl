using Test
using Distributed
using MiniMPI

@testset "sdf" begin

    @testset "Single Process" begin

        @everywhere begin
            COMM = CommDict()
            COMM[:base] = BaseComm(1)
        end

        MiniMPI.init_comm()

        ch = COMM[:base]

        put!(ch.och[1], 1)
        ret = take!(ch.ich[1])
        @test ret == 1

    end

    @testset "Multiple Processes" begin

        addprocs(1)

        @everywhere begin
            using Pkg
            Pkg.activate(".")
            using MiniMPI
        end

        @everywhere begin
            COMM = CommDict()
            COMM[:base] = BaseComm(1)
        end

        MiniMPI.init_comm()

        @everywhere ch = COMM[:base]

        # TODO: Create testing utils for expressions like this
        all_procs = ones(Int64, nprocs())
        if nprocs() > 1
            all_procs[2:end] = workers()
        end

        for i in all_procs
            for j in all_procs
                MiniMPI.remote_return(:(put!(ch.och[$j], $i)), i)
            end
        end

        for i in all_procs
            for j in all_procs
                ret = MiniMPI.remote_return(:(take!(ch.ich[$j])), i)
                @test ret == j
            end
        end

    end

end