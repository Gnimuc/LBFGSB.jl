using LBFGSB
using Base.Test

# @testset "driver3" begin
# translated from driver3.f
# "This time-controlled driver shows that it is possible to terminate a run by
#  elapsed CPU time, and yet be able to print all desired information. This driver
#  also illustrates the use of two stopping criteria that may be used in conjunction
#  with a limit on execution time. The sample problem used here is the same as in
#  driver1 and driver2 (the extended Rosenbrock function with bounds on the variables).

nmax = 1024   # the dimension of the largest problem to be solved
mmax = 17    # the maximum number of limited memory corrections

task = fill(Cuchar(' '), 60)    # fortran's blank padding
csave = fill(Cuchar(' '), 60)    # fortran's blank padding
lsave = zeros(Bool, 4)
isave = zeros(Cint, 44)
dsave = zeros(Cdouble, 29)

# "We specify a limite on the CPU time (in seconds)."
tlimit = 0.2

# "We suppress the default output.
#  (The user could also elect to use the default output by choosing iprint >= 0.)"
iprint = Ref{Cint}(-1)

# "f is a DOUBLE PRECISION variable.  If the routine setulb returns with task(1:2)= 'FG',
#  then f must be set by the user to contain the value of the function at the point x."
f = 0.0
fRef = Ref{Cdouble}(f)

# "g is a DOUBLE PRECISION array of length n.  If the routine setulb returns with taskb(1:2)= 'FG',
#  then g must be set by the user to contain the components of the gradient at the point x."
g = zeros(Cdouble, nmax)

wa = zeros(Cdouble, 2mmax*nmax + 5nmax + 11mmax*mmax + 8mmax)
iwa = zeros(Cint, 3*nmax)

# "We suppress both code-supplied stopping tests because we will provide our own termination conditions"
factr = Ref{Cdouble}(0.0)
pgtol = Ref{Cdouble}(0.0)

n = 1000    # the dimension n of the sample problem
m = 10      # the number of m of limited memory correction stored
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
time1Ref = Ref{Cdouble}(0)
time2Ref = Ref{Cdouble}(0)

timer(time1Ref)

let
    @label CALLLBFGSB

    # This is the call to the L-BFGS-B code.
    setulb(nRef, mRef, x, l, u, nbd, fRef, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)

    # "the minimization routine has returned to request the function f and gradient g values at the current x."
    if task[1:2] == b"FG"
        f = fRef[]
        # "Before evaluating f and g we check the CPU time spent."
        timer(time2Ref)

        if time2Ref[] - time1Ref[] > tlimit
            task[1:4] = b"STOP"
            # "In this driver we have chosen to disable the printing options of the
            #  code (we set iprint=-1); instead we are using customized output: we
            #  print the latest value of x, the corresponding function value f and
            #  the norm of the projected gradient |proj g|."

            println("STOP: CPU EXCEEDING THE TIME LIMIT.")

            # "We print the latest iterate contained in wa(j+1:j+n), where j = 3*n+2*m*n+11*m**2"
            j = 3n + 2m*n + 11m^2
            println("Latest iterate X =")
            for i = j+1:j+n
                println("wa[$i] = ", wa[i])
            end
        else
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
        end
            # "go back to the minimization routine."
            @goto CALLLBFGSB
    end

    # "the minimization routine has returned with a new iterate, The time limit
    #  has not been reached, and we test whether the following two stopping tests are satisfied:
    if task[1:5] == b"NEW_X"
        f = fRef[]

        # "1) Terminate if the total number of f and g evaluations exceeds 900."
        isave[34] ≥ 900 && (task[1:4] = b"STOP"; terminate_info="TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT")

        # "2) Terminate if  |proj g|/(1+|f|) < 1.0d-10"
        dsave[13] ≤ 1e-10 * (1e0 + abs(f)) && (task[1:4] = b"STOP"; terminate_info="THE PROJECTED GRADIENT IS SUFFICIENTLY SMALL")


        # "We wish to print the following information at each iteration:"
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

# @test fRef[] ≈ 1.083490083518441e-9
