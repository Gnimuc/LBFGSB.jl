module LBFGSB

using Libdl

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LBFGSB not installed properly, run Pkg.build(\"LBFGSB\"), restart Julia and try again")
end
include(depsjl_path)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

include("subroutine.jl")
export setulb, timer

include("wrapper.jl")
export L_BFGS_B

end # module
