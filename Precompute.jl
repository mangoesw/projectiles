import DifferentialEquations as DE
import SimpleNonlinearSolve as NLS
import StaticArrays
using SymbolicRegression
using DynamicQuantities: m, s, rad

const L = 0.1501 # Characteristic length (diameter)
const A = pi * (L / 2)^2
const rho = 1.22 # Air density
const v = 1.516e-5 # Kinematic viscosity
const g = 9.80665 # Gravitational acceleration
const mass = 0.215002783 # Projectile mass
const air = 0.5 * rho * A
const I = 2/5 * mass * (L/2)^2 # Moment of inertia
const p = ( # Motion ODE parameters (passed like this for future parameter estimation)
    S0 = 0.2 * air, # Magnus/lift coefficient
    k = 0.02 # "Torque parameter"
)

const tspan = (0.0, 4.5) # if not terminated
const uspan = (0.0, pi/2)
const goal_dydx = -tand(51)
const untild = 6.54157776883
const untily = 1.8288
const v00 = 6.3
const increment = 0.05
# const increment = 0.1
const abstol = 5e-6

function C_d(Re)
    # https://pages.mtu.edu/~fmorriso/DataCorrelationForSphereDrag2016.pdf
    24/Re +
    (2.6*(Re/5.0)) / (1 + (Re/5.0)^1.52) +
    (0.411*(Re/(2.63 * 10^5))^-7.94) / (1 + (Re/(2.63 * 10^5))^-8.0) +
    (0.25*(Re/10^6)) / (1 + (Re/10^6))
end

function ballmotion(u, p, t)
    # https://open.library.ubc.ca/media/stream/pdf/51869/1.0107239/1

    vx, vy = u[3:4]
    omega = u[5]

    speed = hypot(vx, vy)
    Re = speed * L / v
    C = air * C_d(Re)
    S = L/2 * omega / speed

    dx = vx
    dy = vy
    dvx = (-C * vx * speed - p.S0 * omega * vy) / mass
    dvy = -g - (C * vy * speed + p.S0 * omega * vx) / mass
    domega = omega * (-air * speed^2 * S * p.k / I)
    StaticArrays.SA[dx, dy, dvx, dvy, domega]
end

function ode(v0, radians, goalHeight)
    v0y, v0x = sincos(radians) .* v0
    u0 = StaticArrays.SA[0.0, 0.0, v0x, v0y, v0/(pi * L)]
    prob = DE.ODEProblem(ballmotion, u0, tspan, p)
    stopCond(u, t, integrator) = u[4] < 0 ? u[2] - goalHeight : 1.0
    affect!(integrator) = DE.terminate!(integrator)
    cb = DE.ContinuousCallback(stopCond, affect!)
    DE.solve(prob, callback=cb, save_everystep=false)
end

function objective(angle, p)
    odesol = ode(p.v0, angle, p.goalHeight)
    dydx = odesol.u[end][4] / odesol.u[end][3]
    derivative = dydx - goal_dydx
    # displacement = odesol.u[end][2] - p.goalHeight
    derivative
end

function point(v0, goalHeight)
    p = (v0=v0, goalHeight=goalHeight)
    prob = NLS.NonlinearProblem(objective, 0.5, p)
    sol = NLS.solve(prob)
    angle = sol.u
    finalsol = ode(v0, angle, goalHeight)
    d = finalsol.u[end][1]
    (d=d, angle=angle, obj=sol.resid)
end

function regression(data)
    ys = QuantityArray(data.ys, m)
    ds = QuantityArray(data.ds, m)
    v0s = QuantityArray(data.v0s, m/s)
    angles = QuantityArray(data.angles, rad)
    
end

function run(doplot)
    ys = []
    ds = []
    v0s = []
    angles = []
    objs = []
    for goalHeight in 0.0:increment:untily
        v0 = v00
        while (print("height=", goalHeight, ", v0=", v0, "; "); (_point = @show point(v0, goalHeight)).d < untild)
        # while (_point = point(v0, goalHeight)).d < untild
            push!(ys, goalHeight)
            push!(ds, _point.d)
            push!(v0s, v0)
            push!(angles, _point.angle)
            push!(objs, _point.obj)
            v0 += increment
        end
    end

    if doplot == false
        return
    end
    
    println("Plotting")
    plotlyjs()
    default(ms=2)

    pv0 = scatter(ds, v0s, ys, ylabel="v0")
    # plot!(d, x -> v0fit(x))
    # pv0r = scatter(d, CF.fitted(v0fit) .- v0)
    # pv0r = scatter(d, map(x -> v0fit(x), d) .- v0)

    pangle = scatter(ds, angles, ys, ylabel="rad")
    # plot!(d, x -> anglefit(x))
    # pangler = scatter(d, CF.fitted(anglefit) .- angle)
    # pangler = scatter(d, map(x -> anglefit(x), d) .- angle)

    pobj = scatter(ds, objs, ys, ylabel="obj")

    plot(pv0, pangle, pobj, layout=(1,3), legend=false, size=(1200, 650))
end

println("Plot?")
run(readline() == "y" ? (true; using Plots) : false)
