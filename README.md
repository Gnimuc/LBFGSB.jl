# LBFGSB

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/Gnimuc/LBFGSB.jl.svg?branch=master)](https://travis-ci.org/Gnimuc/LBFGSB.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/xlub93nifbjnit7a/branch/master?svg=true)](https://ci.appveyor.com/project/Gnimuc/lbfgsb-jl/branch/master)

This is a Julia wrapper for [L-BFGS-B Nonlinear Optimization Code](http://users.iems.northwestern.edu/%7Enocedal/lbfgsb.html).
It will use and download pre-compiled binaries from [L-BFGS-B-Builder](https://github.com/Gnimuc/L-BFGS-B-Builder).

## Installation
```julia
Pkg.add("LBFGSB")
```

## Usage
```julia
julia> using LBFGSB
help?> setulb
```
The original examples/drivers in the L-BFGS-B library are translated in the `test` folder.

## License
Note that, only the wrapper code in this repo is licensed under MIT, those downloaded
binaries are released under BSD-3-Clause license.
