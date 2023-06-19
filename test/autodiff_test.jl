using Dice
using Test

@testset "test autodiff" begin
    x = add_param!("x", 5)
    e = x^2
    derivs = differentiate(Dict(e => π))
    @test derivs[x] ≈ 10 * π
    clear_params!()

    x = add_param!("x", 5)
    e = 1/x
    derivs = differentiate(Dict(e => π))
    @test derivs[x] ≈ -1/25 * π
    clear_params!()
end

@testset "test GD" begin
    x = add_param!("x", 0)
    e = 7 - (x-5)^2
    for _ in 1:100
        step_maximize!([e], 0.1)
    end
    @test compute(e) ≈ 7
    @test compute(x) ≈ 5
    clear_params!()

    x = add_param!("x", 7)
    y = add_param!("y", 1)
    e = -(x*y-5)^2
    for i in 1:100
        step_maximize!([e], 0.01)
    end
    vals = Dict{ADNode, Real}()
    @test abs(compute(e, vals)) < 0.001
    @test compute(x, vals) * compute(y, vals) ≈ 5
    clear_params!()

    
    psp = add_param!("psp", 0) # pre-sigmoid probability
    p = sigmoid(psp)
    # maximize logpr of flip(p) & flip(p) & !flip(p)
    e = log(p * p * (1 - p))
    for i in 1:500
        step_maximize!([e], 0.1)
    end
    @test compute(p) ≈ 2/3
    clear_params!()
end