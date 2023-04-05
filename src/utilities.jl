const world = Extent(X = (-180, 180), Y = (-90, 90))

"""
    geotile_extent(lat, lon, width)

Return extents of geotile
"""
function geotile_extent(lat, lon, width)
    (min_x = (lon - width/2), min_y = (lat - width/2), 
    max_x = (lon + width/2), max_y = (lat + width/2));
end

"""
    geotile_id(extent)

Returns the geotile id given a geotile `extent`
"""
function geotile_id(extent)
    id = @sprintf("lat[%+03.0f%+03.0f]lon[%+04.0f%+04.0f]", extent.min_y, extent.max_y, extent.min_x, extent.max_x)
    return id
end

"""
    within(extent, x, y)

Determine if a point falls within extents
"""
function within(extent::NamedTuple{(:min_x, :min_y, :max_x, :max_y)}, x, y)
    in = (x >= extent.min_x) .&& (x <= extent.max_x) .&& (y >= extent.min_y) .&& (y <= extent.max_y)
    return in
end

"""
    within(extent_major, extent_minor)

Determine if any part of extent_minor is contained within extent_major
"""
function within(extent_major::NamedTuple{(:min_x, :min_y, :max_x, :max_y)}, extent_minor::NamedTuple{(:min_x, :min_y, :max_x, :max_y)})
    in = (extent_minor.max_x >= extent_major.min_x) .&& (extent_minor.min_x <= extent_major.max_x) .&& 
        (extent_minor.max_y >= extent_major.min_y) .&& (extent_minor.min_y <= extent_major.max_y)
    return in
end

"""
    geotile_define(geotile_width)

Returns a DataFrame with geotile ids and extents
"""
function geotile_define(geotile_width::Number)

    if mod(180, geotile_width) != 0
        error("a geotile width of $geotile_width does not divide evenly into 180")
    end
    
    # geotile package uses fixed extents for consistancy, once defined a subset of tiles can be selected
    dt = geotile_width/2;
    lat_center = (world.Y[1] + dt):geotile_width:(world.Y[2] - dt)
    lon_center = (world.X[1] + dt):geotile_width:(world.X[2] - dt)

    extent = vec([geotile_extent(lat, lon, geotile_width) for lon in(lon_center), lat in(lat_center)]);
    id = geotile_id.(extent)
    DataFrame(id = id, extent = extent)
end

"""
    itslive_proj!(df::DataFrame{}; height = nothing)
add x and y coodinates for local itslive projection to the DataFrame `df`
"""
function itslive_proj!(df; height = nothing)
    zone, north = itslive_zone(mean(df.latitude), mean(df.longitude); alwaysxy = false)
    
    if isnothing(height)
        points_lla = LLA.(df.latitude, df.longitude, df.height);
    else
        points_lla = LLA.(df.latitude, df.longitude, height);
    end
    
    utm_from_lla = UTMfromLLA(zone, north, Geodesy.wgs84); 

    #points_utm = [utm_from_lla(p) for p in points_lla]
    #x = [p.x for p in points_utm]
    #y = [p.y for p in points_utm]
    df[!, :x] = Vector{Float64}(undef, length(df.latitude))
    df[!, :y] = Vector{Float64}(undef, length(df.latitude))

    Threads.@threads for i in eachindex(points_lla)
        p = utm_from_lla(points_lla[i])::UTM{Float64}
        df[i,:x] = p.x;
        df[i,:y] = p.y;
    end

    return df, zone, north
end

"""
    itslive_epsg(lon, lat)
Return epsg code for the ITS_LIVE projection
"""
function itslive_epsg(longitude, latitude; alwaysxy = true)

    if !alwaysxy
        longitude0 = copy(longitude);
        longitude = cppy(latitude);
        latitude = longitude0;
    end

    if latitude > 55
        # NSIDC Sea Ice Polar Stereographic North
        return epsg = 3413
    elseif latitude < -56
        # Antarctic Polar Stereographic
        return epsg = 3031
    end

    # make sure lon is from -180 to 180
    lon = longitude - floor((longitude+180) / (360)) * 360

    # int versions
    ilat = floor(Int64, latitude)
    ilon = floor(Int64, lon)

    # get the latitude band
    band = max(-10, min(9,  fld((ilat + 80), 8) - 10))

    # and check for weird ones
    zone = fld((ilon + 186), 6)
    if ((band == 7) && (zone == 31) && (ilon >= 3)) # Norway
        zone = 32
    elseif ((band == 9) && (ilon >= 0) && (ilon < 42)) # Svalbard
        zone = 2 * fld((ilon + 183), 12) + 1
    end

    if latitude >= 0
        epsg = 32600 + zone
    else
        epsg = 32700 + zone
    end
    return epsg
end


"""
    itslive_zone(lon, lat; alwaysxy = true)
Return the utm `zone` and `isnorth` variables for the ITS_LIVE projection
"""
function itslive_zone(lon, lat; alwaysxy = true)
    if !alwaysxy
        lon0 = copy(lon);
        lon = copy(lat);
        lat = lon0;
    end

    if lat > 55
        return (0, true)
    elseif lat < -56
        return (0, false)
    end

    # int versions
    ilon = floor(Int64, Geodesy.bound_thetad(lon))

    # zone
    zone = fld((ilon + 186), 6)
   
    isnorth = lat >= 0
    return (zone, isnorth)
end

"""
    epsg2epsg(x, y, from_epsg, to_epsg)

Returns `x`, `y` in `to_epsg` projection
"""
function epsg2epsg(
    x::Union{Vector{<:Number}, Number}, 
    y::Union{Vector{<:Number}, Number}, 
    from_epsg::String,
    to_epsg::String;
    parse_output = true
    )
    # this function was slower when using @threads, tested with length(x) == 10000

    # build transformation 
    trans = Proj.Transformation(from_epsg, to_epsg, always_xy=true)

    # project points
    if x isa Vector{}
        data = trans.(x,y)
    else
        data = trans(x,y)
    end

    if parse_output
        if x isa Vector{}
            x = getindex.(data, 1)
            y = getindex.(data, 2)
        else
            x = getindex(data, 1)
            y = getindex(data, 2)
        end
        return x, y
    else
        return data
    end
end
