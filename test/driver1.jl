using LBFGSB
using Base.Test

@testset "driver1" begin
# translated from driver1.f
# "This simple driver demonstrates how to call the L-BFGS-B code to solve a sample
#  problem (the extended Rosenbrock function subject to bounds on the variables).
#  The dimension n of this problem is variable.

nmax = 1024   # the dimension of the largest problem to be solved
mmax = 17    # the maximum number of limited memory corrections

task = fill(Cuchar(' '), 60)    # fortran's blank padding
csave = fill(Cuchar(' '), 60)    # fortran's blank padding
lsave = zeros(Bool, 4)
isave = zeros(Cint, 44)
dsave = zeros(Cdouble, 29)

iprint = Ref{Cint}(1)    # print output at every iteration

# "f is a DOUBLE PRECISION variable.  If the routine setulb returns with task(1:2)= 'FG',
#  then f must be set by the user to contain the value of the function at the point x."
f = 0.0
fRef = Ref{Cdouble}(f)

# "g is a DOUBLE PRECISION array of length n.  If the routine setulb returns with taskb(1:2)= 'FG',
#  then g must be set by the user to contain the components of the gradient at the point x."
g = zeros(Cdouble, nmax)

wa = zeros(Cdouble, 2mmax*nmax + 5nmax + 11mmax*mmax + 8mmax)
iwa = zeros(Cint, 3*nmax)

# specify the tolerances in the stopping criteri
factr = Ref{Cdouble}(1e7)
pgtol = Ref{Cdouble}(1e-5)

n = 25    # the dimension n of the sample problem
m = 5     # the number of m of limited memory correction stored
nRef = Ref{Cint}(n)
mRef = Ref{Cint}(m)

# provide nbd which defines the bounds on the variables:
nbd = zeros(Cint, nmax)
l = zeros(Cdouble, nmax)    # the lower bounds
u = zeros(Cdouble, nmax)    # the upper bounds
# "First set bounds on the odd-numbered variables."
for i = 1:2:n
    nbd[i] = 2
    l[i] = 1e0
    u[i] = 1e2
end
# "Next set bounds on the even-numbered variables."
for i = 2:2:n
    nbd[i] = 2
    l[i] = -1e2
    u[i] = 1e2
end

# "We now define the starting point."
x = zeros(Cdouble, nmax)
for i = 1:n
    x[i] = 3
end

println("Solving sample problem.")
println(" (f = 0.0 at the optimal solution.)")

# "We start the iteration by initializing task."
task[1:5] = b"START"

## ------- the beginning of the loop ----------
let
    @label CALLLBFGSB

    # This is the call to the L-BFGS-B code.
    setulb!(nRef, mRef, x, l, u, nbd, fRef, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)

    # "the minimization routine has returned to request the function f and gradient g values at the current x."
    if task[1:2] == b"FG"
        f = fRef[]

        # "Compute function value f for the sample problem."
        f = 0.25 * (x[1] - 1)^2
        for i = 2:n
            f = f + (x[i] - x[i-1]^2)^2
        end

        f = 4 * f

        # "Compute gradient g for the sample problem."
        t₁ = x[2] - x[1]^2
        g[1] = 2 * (x[1] - 1) - 1.6e1 * x[1] * t₁
        for i = 2:n-1
            t₂ = t₁
            t₁ = x[i+1] - x[i]^2
            g[i] = 8 * t₂ - 1.6e1 * x[i] * t₁
        end
        g[n] = 8 * t₁

        fRef[] = f

        # "go back to the minimization routine."
        @goto CALLLBFGSB
    end

    # "the minimization routine has returned with a new iterate, and we have opted to continue the iteration."
    task[1:5] == b"NEW_X" && @goto CALLLBFGSB

    # ---------- the end of the loop -------------
    # "If task is neither FG nor NEW_X we terminate execution."
end

@test fRef[] ≈ 1.083490083518441e-9

end # EOT
