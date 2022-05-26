# Trees
export DistTree, prob_append_child, prob_extend_children, leaves

struct DistTree{T} <: Dist{Any} where T <: Dist
    mgr
    val::T
    children::DistVector{DistTree{T}}
end

function DistTree{T}(mgr, val::T) where T <: Dist
    DistTree{T}(mgr, val, DistVector{DistTree{T}}(mgr))
end

function DistTree(mgr, val::T) where T <: Dist
    DistTree{T}(mgr, val, DistVector{DistTree{T}}(mgr))
end

function group_infer(f, d::DistTree, prior, prior_p::Float64)
    group_infer(d.val, prior, prior_p) do val, val_prior, val_p
        group_infer(d.children, val_prior, val_p) do children, children_prior, children_p
            f((val, children), children_prior, children_p)
        end
    end
end

bools(d::DistTree) =
    bools(vcat(bools(d.val), bools(d.children)))

ifelse(c::DistBool, x::DistTree, y::DistTree) =
    DistTree(c.mgr, ifelse(c, x.val, y.val), ifelse(c, x.children, y.children))

prob_equals(x::DistTree, y::DistTree) =
    prob_equals(x.val, y.val) & prob_equals(x.children, y.children)

prob_append_child(d::DistTree{T}, child::DistTree{T}) where T <: Dist = 
    DistTree{T}(d.mgr, d.val, prob_append(d.children, child))

prob_extend_children(d::DistTree{T}, children::DistVector{DistTree{T}}) where T <: Dist = 
    DistTree{T}(d.mgr, d.val, prob_extend(d.children, children))

function leaves(d::DistTree{T})::DistVector{T} where T <: Dist
    children_leaves = DistVector{T}(d.mgr, Vector{T}())
    for (i, child) in enumerate(d.children.contents)
        children_leaves = ifelse(i > d.children.len,
            children_leaves,
            prob_extend(children_leaves, leaves(child))
        )
    end
    ifelse(prob_equals(d.children.len, 0),
        DistVector(d.mgr, [d.val]),
        children_leaves
    )
end
