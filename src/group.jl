using Distributed

struct CommGroup
    myid::Int64
    nprocs::Int64
    ltog::Function

    function CommGroup(myid::Integer, nprocs::Integer, ltog::Function)
        # Check local-to-global function
        rep_check = Dict{Int64,Bool}()
        for li in 1:nprocs
            gi = ltog(li)

            (gi>nprocs()
             && error("global index output larger than number of processes"))
            (get(rep_check, gi, false)
             && error("local-to-global function must be injective"))

            rep_check[gi] = true
        end
        (!get(rep_check, myid(), false)
         && error("local process' global id must be mapped to"))

        new(myid, nprocs, ltog)
    end
end

function CommGroups(genv_to_lenv::Function, ltog::Function)
    CommGroup(genv_to_lenv(myid(), nprocs())..., ltog)
end

function CommGroups(gtol::Function, gntoln::Function, ltog::Function)
    CommGroup(gtol(myid()), gntoln(nprocs()), ltog)
end

CommGroups() = CommGroup(identity, identity)

nprocs(group::CommGroup) = group.nprocs
myid(group::CommGroup) = group.myid
ltog(group::CommGroup, li::Int64) = group.ltog(li)
