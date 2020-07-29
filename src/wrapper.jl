struct L_BFGS_B
    nmax::Int
    mmax::Int
    task::Vector{UInt8}
    csave::Vector{UInt8}
    lsave::Vector{Cint}
    isave::Vector{Cint}
    dsave::Vector{Cdouble}
    wa::Vector{Cdouble}
    iwa::Vector{Cint}
    g::Vector{Cdouble}
    nbd::Vector{Cint}
    l::Vector{Cdouble}
    u::Vector{Cdouble}
    function L_BFGS_B(nmax, mmax)
        task = fill(Cuchar(' '), 60)
        csave = fill(Cuchar(' '), 60)
        lsave = zeros(Cint, 4)
        isave = zeros(Cint, 44)
        dsave = zeros(Cdouble, 29)
        wa = zeros(Cdouble, 2mmax*nmax + 5nmax + 11mmax*mmax + 8mmax)
        iwa = zeros(Cint, 3*nmax)
        g = zeros(Cdouble, nmax)
        nbd = zeros(Cint, nmax)
        l = zeros(Cdouble, nmax)
        u = zeros(Cdouble, nmax)
        new(nmax, mmax, task, csave, lsave, isave, dsave, wa, iwa, g, nbd, l, u)
    end
end

function (obj::L_BFGS_B)(func, grad!, x0::AbstractVector, bounds::AbstractMatrix;
    m=10, factr=1e7, pgtol=1e-5, iprint=-1, maxfun=15000, maxiter=15000)
    x = copy(x0)
    n = length(x)
    f = 0.0
    # clean up
    fill!(obj.task, Cuchar(' '))
    fill!(obj.csave, Cuchar(' '))
    fill!(obj.lsave, zero(Cint))
    fill!(obj.isave, zero(Cint))
    fill!(obj.dsave, zero(Cdouble))
    fill!(obj.wa, zero(Cdouble))
    fill!(obj.iwa, zero(Cint))
    fill!(obj.g, zero(Cdouble))
    fill!(obj.nbd, zero(Cint))
    fill!(obj.l, zero(Cdouble))
    fill!(obj.u, zero(Cdouble))
    # set bounds
    for i = 1:n
        obj.nbd[i] = bounds[1,i]
        obj.l[i] = bounds[2,i]
        obj.u[i] = bounds[3,i]
    end
    # start
    obj.task[1:5] = b"START"
    while true
        setulb(n, m, x, obj.l, obj.u, obj.nbd, f, obj.g, factr, pgtol, obj.wa,
               obj.iwa, obj.task, iprint, obj.csave, obj.lsave, obj.isave, obj.dsave)
        if obj.task[1:2] == b"FG"
            f = func(x)
            grad!(obj.g, x)
        elseif obj.task[1:5] == b"NEW_X"
            if obj.isave[30] ≥ maxiter
                obj.task[1:43] = b"STOP: TOTAL NO. of ITERATIONS REACHED LIMIT"
            elseif obj.isave[34] ≥ maxfun
                obj.task[1:52] = b"STOP: TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT"
            end
        else
            return f, x
        end
    end
end

function (obj::L_BFGS_B)(func, x0::AbstractVector, bounds::AbstractMatrix;
    m=10, factr=1e7, pgtol=1e-5, iprint=-1, maxfun=15000, maxiter=15000)
    x = copy(x0)
    n = length(x)
    f = 0.0
    # clean up
    fill!(obj.task, Cuchar(' '))
    fill!(obj.csave, Cuchar(' '))
    fill!(obj.lsave, zero(Cint))
    fill!(obj.isave, zero(Cint))
    fill!(obj.dsave, zero(Cdouble))
    fill!(obj.wa, zero(Cdouble))
    fill!(obj.iwa, zero(Cint))
    fill!(obj.g, zero(Cdouble))
    fill!(obj.nbd, zero(Cint))
    fill!(obj.l, zero(Cdouble))
    fill!(obj.u, zero(Cdouble))
    # set bounds
    for i = 1:n
        obj.nbd[i] = bounds[1,i]
        obj.l[i] = bounds[2,i]
        obj.u[i] = bounds[3,i]
    end
    # start
    obj.task[1:5] = b"START"
    while true
        setulb(n, m, x, obj.l, obj.u, obj.nbd, f, obj.g, factr, pgtol, obj.wa,
               obj.iwa, obj.task, iprint, obj.csave, obj.lsave, obj.isave, obj.dsave)
        if obj.task[1:2] == b"FG"
            f, grad = func(x)
            obj.g[1:n] = grad
        elseif obj.task[1:5] == b"NEW_X"
            if obj.isave[30] ≥ maxiter
                obj.task[1:43] = b"STOP: TOTAL NO. of ITERATIONS REACHED LIMIT"
            elseif obj.isave[34] ≥ maxfun
                obj.task[1:52] = b"STOP: TOTAL NO. of f AND g EVALUATIONS EXCEEDS LIMIT"
            end
        else
            return f, x
        end
    end
end

function typ_bnd(lb,ub)
        lb > ub && error("Inconsistent bounds")
    
        lbinf = lb==-Inf
        ubinf = ub==+Inf

        lbinf && ubinf && return 0
        !lbinf && ubinf && return 1
        !lbinf && !ubinf && return 2
        lbinf && !ubinf && return 3
end

function _opt_bounds(n,m,lb,ub)
    optimizer=L_BFGS_B(n,m)
    bounds=zeros(3,n)
    bounds[2,:].=lb
    bounds[3,:].=ub
    bounds[1,:].= typ_bnd.(lb,ub)
    return optimizer,bounds
end

function lbfgsb(f,g!,x0;m=10,lb=[-Inf for i in x0],ub=[Inf for i in x0],kwargs...)
    n=length(x0)
    optimizer,bounds=_opt_bounds(n,m,lb,ub)
   
    optimizer(f,g!,x0,bounds;m=m,kwargs...)
end

function lbfgsb(f,x0;m=10,lb=[-Inf for i in x0],ub=[Inf for i in x0],kwargs...)
    n=length(x0)
    optimizer,bounds=_opt_bounds(n,m,lb,ub)
    
    optimizer(f,x0,bounds;m=m,kwargs...)
end
