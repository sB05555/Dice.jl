using Distributions

export DistFixedPoint, continuous

##################################
# types, structs, and constructors
##################################

struct DistFixedPoint{W, F} <: Dist{Int}
    number::DistInt{W}
    function DistFixedPoint{W, F}(b) where W where F
        @assert W >= F
        new{W, F}(b)
    end

end

function DistFixedPoint{W, F}(b::Vector) where W where F
    DistFixedPoint{W, F}(DistInt{W}(b))
end

function DistFixedPoint{W, F}(i::Float64) where W where F
    new_i = Int(round(if i >= 0 i*2^F else i*2^F + 2^W end))
    DistFixedPoint{W, F}(DistInt{W}(DistUInt{W}(new_i)))
end

# ##################################
# # inference
# ##################################

tobits(x::DistFixedPoint) = tobits(x.number)

function frombits(x::DistFixedPoint{W, F}, world) where W where F
    frombits(x.number, world)/2^F
end

# ##################################
# # expectation
# ##################################

function expectation(x::DistFixedPoint{W, F}) where W where F
    expectation(x.number)/2^F
end
    

# ##################################
# # methods
# ##################################

bitwidth(::DistFixedPoint{W, F}) where W where F = W

function uniform(::Type{DistFixedPoint{W, F}}, n = W) where W where F
    DistFixedPoint{W, F}(DistInt{W}(uniform(DistUInt{W}, n).bits))
end

function triangle(t::Type{DistFixedPoint{W, F}}, b::Int) where W where F
    @assert b <= W
    DistFixedPoint{W, F}(triangle(DistInt{W}, b))
end

##################################
# other method overloading
##################################

function prob_equals(x::DistFixedPoint{W, F}, y::DistFixedPoint{W, F}) where W where F
    prob_equals(x.number, y.number)
end

function Base.ifelse(cond::Dist{Bool}, then::DistFixedPoint{W, F}, elze::DistFixedPoint{W, F}) where W where F
    DistFixedPoint{W, F}(ifelse(cond, then.number, elze.number))
end

function Base.:(+)(x::DistFixedPoint{W, F}, y::DistFixedPoint{W, F}) where {W, F}
    DistFixedPoint{W, F}(x.number + y.number)
end

function Base.:(-)(x::DistFixedPoint{W, F}, y::DistFixedPoint{W, F}) where {W, F}
    DistFixedPoint{W, F}(x.number - y.number)
end

#################################
# continuous distributions
#################################
  
function continuous(t::Type{DistFixedPoint{W, F}}, d::ContinuousUnivariateDistribution, pieces::Int, start::Float64, stop::Float64) where {W, F}

    # basic checks
    @assert start >= -(2^(W - F - 1))
    @assert stop <= (2^(W - F - 1))
    @assert start < stop
    a = Int(log2((stop - start)*2^F))
    @assert typeof(a) == Int 
    piece_bits = Int(log2(pieces))
    if piece_bits == 0
        piece_bits = 1
    end
    @assert typeof(piece_bits) == Int

    # preliminaries
    d = Truncated(d, start, stop)
    whole_bits = a
    point = F
    interval_sz = (2^whole_bits/pieces)
    bits = Int(log2(interval_sz))
    areas = Vector(undef, pieces)
    trap_areas = Vector(undef, pieces)
    total_area = 0
    end_pts = Vector(undef, pieces)

    # Figuring out end points
    for i=1:pieces
        p1 = start + (i-1)*interval_sz/2^point 
        p2 = p1 + 1/2^(point) 
        p3 = start + (i)*interval_sz/2^point 
        p4 = p3 - 1/2^point 

        # @show p1, p2, p3, p4

        pts = [cdf.(d, p2) - cdf.(d, p1), cdf.(d, p3) - cdf.(d, p4)]
        end_pts[i] = pts

        trap_areas[i] = (pts[1] + pts[2])*2^(bits - 1)
        areas[i] = (cdf.(d, p3) - cdf.(d, p1))
        # @show p1, p2, p3, p4, areas[i]

        total_area += areas[i]
    end

    rel_prob = areas/total_area

    # @show rel_prob
    # @show areas

    b = discrete(DistUInt{piece_bits}, rel_prob)
    
    #Move flips here
    piece_flips = Vector(undef, pieces)
    l_vector = Vector(undef, pieces)
    for i=pieces:-1:1
        if (trap_areas[i] == 0)
            a = 0.0
        else
            a = end_pts[i][1]/trap_areas[i]
        end
        l_vector[i] = a > 1/2^bits
        if l_vector[i]
            # @show 2 - a*2^bits, i, areas[i]
            piece_flips[i] = flip(2 - a*2^bits)
        else
            # @show a*2^bits
            piece_flips[i] = flip(a*2^bits)
        end  
    end

    unif = uniform(DistFixedPoint{W, F}, bits)
    tria = triangle(DistFixedPoint{W, F}, bits)
    ans = DistFixedPoint{W, F}((2^(W-1)-1)/2^F)

    for i=pieces:-1:1
        ans = ifelse( prob_equals(b, DistUInt{piece_bits}(i-1)), 
                (if l_vector[i]
                    (ifelse(piece_flips[i], 
                        (DistFixedPoint{W, F}((i - 1)*2^bits/2^F + start) + unif), 
                        (DistFixedPoint{W, F}((i*2^bits - 1)/2^F + start) - tria)))
                else
                    (DistFixedPoint{W, F}((i - 1)*2^bits/2^F + start) + 
                        ifelse(piece_flips[i], unif, tria))
                    
                end),
                ans)  
    end
    return ans
end