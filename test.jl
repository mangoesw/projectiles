import OrdinaryDiffEq as ODE
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
# using DynamicQuantities

@constants(
    ρ = 1.225, # Air density
    L = 0.1501, # Diameter
    C_over_C_d = ρ*π*(L/2)^2/2,
    ν = 1.470e-5, # Kinematic viscosity
    m = 0.21500278, # Mass
    g = 9.80665
)

@variables(
    x(t) = 0.0,
    y(t) = 0.0,
    vx(t),
    vy(t),
    ω(t)
) 

eqs = [
    Re ~ hypot(vx, vy)*L/ν
    C_d ~ 24/Re + (2.6*Re/5)/(1 + (Re/5)^1.52) + 0.411*(Re/2.63e5)^-7.94/(1 + (Re/2.63e5)^-8) + (Re/4e6)/(1 + Re/1e6)
    C ~ (ρ*C_d*)

    D(x) ~ vx
    D(y) ~ vy
    D(vx) ~ (-C*vx*speed - p.S0*omega*vy)/m
    D(vy) ~ -g - (C*vy*speed + p.S0*omega*vx)/m
    D(ω)
]
