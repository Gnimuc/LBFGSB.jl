module LBFGSB

if VERSION >= v"0.7.0-DEV.3382"
    import Libdl
end

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LBFGSB not installed properly, run Pkg.build(\"LBFGSB\"), restart Julia and try again")
end
include(depsjl_path)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

function setulb!(n, m, x, l, u, nbd, f, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave)
    global liblbfgsb
    hdl = Libdl.dlopen_e(liblbfgsb)
    @assert hdl != C_NULL "Could not open $liblbfgsb"
    setulb = Libdl.dlsym_e(hdl, :setulb_)
    @assert setulb != C_NULL "Could not find `setulb` within $liblbfgsb"
    ccall(setulb, Void, (Ptr{Cint}, Ptr{Cint}, Ref{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},
          Ptr{Cint}, Ref{Cdouble}, Ref{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble},
          Ptr{Cint}, Ptr{Cuchar}, Ptr{Cint}, Ref{Cuchar}, Ref{Bool}, Ref{Cint}, Ref{Cdouble}, Csize_t, Csize_t),
          n, m, x, l, u, nbd, f, g, factr, pgtol, wa, iwa, task, iprint, csave, lsave, isave, dsave, 60, 60)
end

"""
    timer(x)
The double precision cpu timing subroutine in the L-BFGS-B code. 
"""
function timer(x)
    global liblbfgsb
    hdl = Libdl.dlopen_e(liblbfgsb)
    @assert hdl != C_NULL "Could not open $liblbfgsb"
    timer_ = Libdl.dlsym_e(hdl, :timer_)
    @assert timer_ != C_NULL "Could not find `timer` within $liblbfgsb"
    ccall(timer_, Void, (Ref{Cdouble},), x)
end

export setulb, timer

end # module
