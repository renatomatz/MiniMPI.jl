using Distributed

function asgn_expr(name, val)
    Expr(:(=), Symbol(name), val)
end

function remote_return(expr, p::Integer, mod::Module=Main)
    @fetchfrom(p, Core.eval(mod, expr))
end

function remote_exec(expr, p::Integer, mod::Module=Main)
    @spawnat(p, Core.eval(mod, expr))
end

function remote_asgn(name, val, p::Integer, mod::Module=Main)
    remote_return(asgn_expr(name, val), p, mod)
end

function channel_lambda(name, ::Type{T}, N::Integer, mod::Module=Main) where {T}
    ()->Core.eval(mod, asgn_expr(name, Channel{T}(N)))
end

function assigned_remote_channel(name, p, ::Type{T}, N::Integer, mod::Module=Main) where {T}
    RemoteChannel(channel_lambda(name, T, N, mod), p)
end

# TODO: Add support for expression nesting and multiple evals.
# e.g. >> expr = :(Expr(:(=), Symbol(:a, myid()), myid()))
#      >> eval(expr)
#         :(a1 = 1)
#      >> @fetchfrom 2 eval(expr)
#         :(a2 = 2)
#      >> eval(eval(expr))
#         1
#      >> a1
#         1
#      >> @fetchfrom 2 eval(eval(expr))
#         2
#      >> @fetchfrom 2 :a2
#         2
#      >> a2
#         UndefinedVarError: a2 not defined
