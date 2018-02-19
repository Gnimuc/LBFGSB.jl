using LBFGSB
using Base.Test

@testset "driver2" begin
# translated from driver2.f
# "This driver shows how to replace the default stopping test by other termination
#  criteria. It also illustrates how to print the values of several parameters
#  during the course of the iteration. The sample problem used here is the same
#  as in DRIVER1 (the extended Rosenbrock function with bounds on the variables)."

nmax = 1024   # the dimension of the largest problem to be solved
mmax = 17    # the maximum number of limited memory corrections

task = fill(Cuchar(' '), 60)    # fortran's blank padding
csave = fill(Cuchar(' '), 60)    # fortran's blank padding
lsave = zeros(Bool, 4)
isave = zeros(Cint, 44)
dsave = zeros(Cdouble, 29)

iprint = Ref{Cint}(-1)    # suppress the default output

# "f is a DOUBLE PRECISION variable.  If the routine setulb returns with task(1:2)= 'FG',
#  then f must be set by the user to contain the value of the function at the point x."
f = 0.0
fRef = Ref{Cdouble}(f)

# "g is a DOUBLE PRECISION array of length n.  If the routine setulb returns with taskb(1:2)= 'FG',
#  then g must be set by the user to contain the components of the gradient at the point x."
g = zeros(Cdouble, nmax)

wa = zeros(Cdouble, 2mmax*nmax + 5nmax + 11mmax*mmax + 8mmax)
iwa = zeros(Cint, 3*nmax)

# "We suppress both code-supplied stopping tests because the user is providing his own stopping criteria."
factr = Ref{Cdouble}(0.0)
pgtol = Ref{Cdouble}(0.0)

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
    x[i] = 3e0
end

println("Solving sample problem.")
println(" (f = 0.0 at the optimal solution.)")

# "We start the iteration by initializing task."
task[1:5] = b"START"

## ------- the beginning of the loop ----------
let
    @label CALLLBFGSB

    # This is the call to the L-BFGS-B code.
    setulb(nRef, mRef, x, l, u, nbd, fRef, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)

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

    # "the minimization routine has returned with a new iterate, At this point have the
    #  opportunity of stopping the iteration or observing the values of certain parameters"
    if task[1:5] == b"NEW_X"
        f = fRef[]

        # "First are two examples of stopping tests."

        # "Note: task(1:4) must be assigned the value 'STOP' to terminate the iteration
        #  and ensure that the final results are printed in the default format. The
        #  rest of the character string TASK may be used to store other information.

        # "1) Terminate if the total number of f and g evaluations exceeds 99."
        isave[34] ≥ 99 && (task[1:4] = b"STOP"; terminate_info="TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT")

        # "2) Terminate if  |proj g|/(1+|f|) < 1.0d-10, where "proj g" denoted the projected gradient"
        dsave[13] ≤ 1e-10 * (1e0 + abs(f)) && (task[1:4] = b"STOP"; terminate_info="THE PROJECTED GRADIENT IS SUFFICIENTLY SMALL")


        # "We now wish to print the following information at each iteration:"
        # "1) the current iteration number, isave(30),"
        # "2) the total number of f and g evaluations, isave(34),"
        # "3) the value of the objective function f,"
        # "4) the norm of the projected gradient,  dsave(13)"

        println("Iterate ", isave[30], "  nfg = ", isave[34], "  f = ", f, "  |proj g| = ", dsave[13])

        # "If the run is to be terminated, we print also the information contained
        #  in task as well as the final value of x."
        if task[1:4] == b"STOP"
            println(terminate_info)
            for i = 1:n
                println("x($i) = ", x[i])
            end
        end

        # "go back to the minimization routine."
        @goto CALLLBFGSB
    end

    # ---------- the end of the loop -------------
    # "If task is neither FG nor NEW_X we terminate execution."
end

tol = 1e-4

@test all(x[1:10] - 1.0000 .< tol)
@test x[11] - 1.0001 < tol
@test x[12] - 1.0002 < tol
@test x[13] - 1.0003 < tol
@test x[14] - 1.0006 < tol
@test x[15] - 1.0013 < tol
@test x[16] - 1.0026 < tol
@test x[17] - 1.0052 < tol
@test x[18] - 1.0105 < tol
@test x[19] - 1.0210 < tol
@test x[20] - 1.0425 < tol
@test x[21] - 1.0867 < tol
@test x[22] - 1.1810 < tol
@test x[23] - 1.3947 < tol
@test x[24] - 1.9452 < tol
@test x[25] - 3.7837 < tol

end # EOB
