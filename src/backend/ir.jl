export to_dice_ir

struct IrMgr <: DiceManager end

abstract type IrNode end

struct IrFlip <: IrNode
    prob::Float64
end

new_var(::IrMgr, prob) =
    IrFlip(prob)

struct IrNegate <: IrNode
    x::IrNode
end
    
negate(::IrMgr, x) =
    IrNegate(x)


struct IrConjoin <: IrNode
    x::IrNode
    y::IrNode
end
    
conjoin(::IrMgr, x, y) =
    IrConjoin(x, y)
    
struct IrDisjoin <: IrNode
    x::IrNode
    y::IrNode
end
    
disjoin(::IrMgr, x, y) =
    IrDisjoin(x, y)
    
struct IrIte <: IrNode
    cond::IrNode
    then::IrNode
    elze::IrNode
end
    
ite(::IrMgr, x, y, z) =
    IrIte(x, y, z)
    
###################################

to_dice_ir(pb::DistBool) =
    to_dice_ir(pb.bit)

to_dice_ir(ir::IrFlip) = 
    "flip $(ir.prob)"

to_dice_ir(ir::IrNegate) = 
    "!($(to_dice_ir(ir.x)))"

to_dice_ir(ir::IrConjoin) = 
    "($(to_dice_ir(ir.x))) && ($(to_dice_ir(ir.y)))"

to_dice_ir(ir::IrDisjoin) = 
    "($(to_dice_ir(ir.x))) || ($(to_dice_ir(ir.y)))"

to_dice_ir(ir::IrIte) = 
    """
    if $(to_dice_ir(ir.cond)) then
        $(to_dice_ir(ir.then))
    else
        $(to_dice_ir(ir.elze))
    """