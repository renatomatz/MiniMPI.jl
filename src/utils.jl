using Distributed

function mpiexec(f::Function, comm::Dict{AbstractComm})
    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = remotecall(f, i, comm)
    end
    fut
end

function make_comm_mat(::Type{T}, N::Integer, p::Int64)
    reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:(p^2)], (p,p))
end

function asgn_expr(name, val)
    Expr(:(=), Symbol(name), Symbol(val))
end

function remote_exec(expr, p::Integer, mod::Module=Main)
    @spawnat(p, Core.eval(mod, expr))
end

function remote_asgn(name, val, p::Integer, mod::Module=Main)
    remote_exec(asgn_expr(name, val), p, mod)
end

function channel_lambda(name, ::Type{T}, N::Integer, mod::Module=Main)
    ()->Core.eval(mod, asgn_expr(name, Channel{T}(N)))
end

function (RemoteChannel)(name, p, ::Type{T}, N::Integer, mod::Module=Main)
    RemoteChannel(channel_lambda(name, T, N, mod), p)
end
