using Distributed

struct CommGroup
    myid::Int64
    nprocs::Int64
    ltog::Function
end

function (CommGroups)(genv_to_lenv::Function, ltog::Function)
    CommGroup(gtol(myid(), nprocs())..., ltog)
end

function (CommGroups)(gtol::Function, gntoln::Function, ltog::Function)
    CommGroup(gtol(myid()), gntoln(nprocs()), ltog)
end

(CommGroups)() = CommGroup(identity, identity)

nprocs(group::CommGroup) = group.nprocs
myid(group::CommGroup) = group.myid
ltog(group::CommGroup, li::Int64) = group.ltog(li)
