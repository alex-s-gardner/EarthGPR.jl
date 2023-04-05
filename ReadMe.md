# Example height change data derived from satellite altimetry

Data are stored in the `data/` directory as `Arrow Tables` and can be read in using `DataFrames(Arrow.Table(filename))`

Individual files are created for each 2x2 degree rectangle on the surface of the Earth which are called `geotiles`. This repository contains all geotiles covering Greenland.

There are two files for each geotile. One contains the parameters of a least-squares model fit to the full archive of elevation measurements (e.g. data/lat[+82+84]lon[-072-070].cop30_v2) and the other contains all of the ancillary information and has the same file name but ending in with a `+` (e.g. lat[+82+84]lon[-072-070].cop30_v2+)

# Here's what the height change data looks like:

```julia 
julia> DataFrame(Arrow.Table("data/lat[+82+84]lon[-072-070].cop30_v2"))
8170×8 DataFrame
  Row │ longitude  latitude  offset     trend        amplitude  phase       count  rmse     
      │ Float64    Float64   Float64    Float64      Float64    Float64     Int16  Float64  
──────┼─────────────────────────────────────────────────────────────────────────────────────
    1 │  -71.1945   82.0001  0.585444   -0.0901259    0.373921   0.476692      27  2.91935
  ⋮   │     ⋮         ⋮          ⋮           ⋮           ⋮          ⋮         ⋮       ⋮
```

`longitude`: degrees longitude
`latitude`: degrees latitude
`offset`: model intercept in meters [can be ignored]
`trend`: model trend in meters per year, this is the variable that we want to extrapolate
`amplitude`: amplitude of seasonal sinusoid included in model fit in meters
`phase`: phase of seasonal sinusoid included in model fit in meters
`count`: number of observations that the model was fit to
`rmse`: the root mean square error of the observations to the model

# Here's what the ancillary data looks like:
```julia
julia> DataFrame(Arrow.Table("data/lat[+82+84]lon[-072-070].cop30_v2+"))
8170×12 DataFrame
  Row │ h      inlandwater  landice  floatingice  land   ocean  thickness  region  vx0      vy0      dhdxs    ⋯
      │ Int16  Bool         Bool     Bool         Bool   Bool   Int16      UInt8   Float32  Float32  Float32  ⋯
──────┼────────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │   784        false    false        false   true  false         10       1      0.0      0.0      0.0  ⋯
  ⋮   │   ⋮         ⋮          ⋮          ⋮         ⋮      ⋮        ⋮        ⋮        ⋮        ⋮        ⋮     ⋱
  ```

 `h`: elevation in meters [this is a strong predictor]
 `inlandwater`: inland water body [true/false]
 `landice`: land ice, i.e. glacier, ice sheet, ice cap, icefield [true/false]
 `floatingice`: ice shelf [true/false]
 `land`: ice shelf [true/false]
 `ocean`: ocean [true/false]
 `thickness`: land ice thickness in meters [this is a weak predictor]
 `region`: Randolph Glacier Inventory region code
 `vx0`: surface velocity in meters per year in x direction [EPSG:3413 corrdinates]
 `vy0`: surface velocity in meters per year in y direction [EPSG:3413 corrdinates]
 `dhdxs`: smoothed surface slope in x [EPSG:3413 corrdinates]
 `dhdys`: smoothed surface slope in y [EPSG:3413 corrdinates]

Note: velocity magnitude (v = sqrt(vx.^2 .+ vy.^2)) is a strong predictor


# Plot all data
using the `plot_data` script you can create an interactive plot to explore the data

![example 1](https://github.com/alex-s-gardner/EarthGPR.jl/blob/main/assets/height_change_example.jpg?raw=true)