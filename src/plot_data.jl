geotile_width = 2 #geotile width [degrees]
import EarthGPR
using Arrow 
using DataFrames
using GLMakie
using Tyler
using Statistics
using TileProviders
using ColorSchemes
using Colors

# data directory
data_dir = "data/"

# define geotiles
geotiles = EarthGPR.geotile_define(geotile_width)

# Greenland extent
extent = (min_x = -73.5, min_y = 59.5, max_x = -12., max_y = 84.)

# geotiles within extent
ind = EarthGPR.within.(Ref(extent), geotiles.extent)
geotiles = geotiles[ind,:]

# read in data for all geotiles
dem = "cop30_v2"

df1 = DataFrame()
df2 = DataFrame()

for geotile in eachrow(geotiles)
    dh_file = joinpath(data_dir, "$(geotile.id).$(dem)")
    anccilary_file = joinpath(data_dir, "$(geotile.id).$(dem)+")
    if isfile(dh_file)
        df1 = append!(df1,DataFrame(Arrow.Table(dh_file)))
        println(anccilary_file)
        df2 = append!(df2,DataFrame(Arrow.Table(anccilary_file)))
    end
end

# select data only over landice
df = df1[df2.landice, :]

# select a map provider
provider = TileProviders.Esri(:WorldImagery)

# convert to Web Mercator projection
x,y = EarthGPR.epsg2epsg(df.longitude, df.latitude, "EPSG:4326", "EPSG:3857")

# add frame
frame = Rect2f(extent.min_x, extent.min_y, extent.max_x - extent.min_x, extent.max_y - extent.min_y)

# show map
m = Tyler.Map(frame;
    provider, figure=Figure(resolution=(2000, 1200)))
    
# choose color map [https://docs.juliahub.com/AbstractPlotting/6fydZ/0.12.10/generated/colors.html]
cmap = reverse(ColorSchemes.balance.colors)
n = length(cmap);
alpha = ones(n)
nmod = 50;
mod = -nmod:1:nmod
alpha[mod .+ round(Int64,n/2)] = abs.(mod ./ nmod)
cmap = RGBA.(cmap, alpha)

# set color axis limits which by default is automatically equal to the extrema of the color values
colorrange = [-.25, .25];
objscatter = scatter!(m.axis, x, y; color = df.trend, colormap = cmap, colorrange = colorrange, markersize = 20)

# hide ticks, grid and lables
hidedecorations!(m.axis) 

# hide frames
hidespines!(m.axis)