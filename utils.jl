function spawn_everywhere(expr::Expr)
    p = n_procs()
    fut = Vector{Future}(undef, p)
    for i in 1:p
        fut[i] = @spawnat i eval(expr)
    end
    fut
end

function get_item(p::Int, item::Symbol)
    @fetchfrom p getfield(Main, item)
end

function make_comm_mat(::Type{T}, N::Integer, p::Int64)
    reshape([RemoteChannel(()->Channel{T}(N)) for _ in 1:(p^2)], (p,p))
end
