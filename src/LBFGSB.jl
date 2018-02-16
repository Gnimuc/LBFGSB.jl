module LBFGSB

if VERSION >= v"0.7.0-DEV.3382"
    import Libdl
end

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LibFoo not installed properly, run Pkg.build(\"LibFoo\"), restart Julia and try again")
end
include(depsjl_path)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

end # module
