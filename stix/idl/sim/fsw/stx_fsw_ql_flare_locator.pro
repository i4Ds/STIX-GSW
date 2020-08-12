;+
; :description:
;  flare location using data from quicklook accumulators
;
;  :categories:
;  quicklook, fsw
;
;  :params:
;  cfl_counts:             in, required, type = 'float array'
;                          accumulated counts in 8 large course flare locator pixels
;                          in configuration specified energy range.
;
;  quad_counts:            in, required type = 'float array'
;                          accumulated counts in four quadrants and  in configuration
;                          specified energy range.
;
;  total_background:       in, required, type =  'Long'
;                          weighted sum of stx_fsw_background_determination estimates
;                          averaged over a specified number of background time intervals
;
; :keywords:
;
;  lower_limit_counts:     in, optional, type = 'integer', default = 2^15 (should be scaled with ql time)
;                          lower limit for total counts from all 4 quadrants.
;
;  upper_limit_counts:     in, optional, type = 'integer', default = 2^19 (should be scaled with ql time)
;                          upper limit for total counts from all 4 quadrants.
;
;  out_of_range_factor:    in, optional, type = 'float', default = 2.0
;                          parameter used to determine if flare is out of range
;                          by comparing the counts in the 4 quadrants.
;
;  tot_bk_factor:          in, optional, type = 'float', default = 0.1
;                          factor for comparing background counts to total cfl
;                          counts to determine if background level is too high.
;                          Range 0.01 to 0.8
;
;  quad_bk_factor:         in, optional, type = 'float', default = 30.0
;                          factor for subtracting background counts from
;                          counts in each quadrant. Range 0 to 500
;
;  cfl_bk_factor:          in, optional, type = 'float', default = 1.0
;                          factor for subtracting background counts from
;                          counts in each cfl pixel. Range 0 to 30
;
;  tab_data:               in, optional, type = "[nvectors, npixels] array",
;                          the cfl reference table of ideal case CFL sky vectors, where
;                          nvectors is 1D representation of nsky_x*nsky_y individual sky
;                          vectors and npixels corresponds to 12 flux values -- the 8 CFL
;                          large pixels (normalized by their quadratic sum) and the average
;                          Fourier subcollimator summed-pixel quadrants (normalized by their
;                          quadratic sum).
;
;  sky_x:                  in, optional, type = "float", default=""
;                          1D array of CFL sky vector sky X sampling in arcminutes
;                          from STIX optical axis.
;
;  sky_y:                  in, optional, type = "float", default=""
;                          1D array of CFL sky vector sky Y sampling in arcminutes
;                          from STIX optical axis.
;
;  flare_flag:             in, required, type = "byte", default="0"
;                          the cfl sets 2 bits in the flare flag for error checking and cancelation detection
;
;
;
;
;  :returns:
;   {pos, flare_flag}:         giving the [x,y] position of the peak in arcminutes and the modified flare_flag
;
;  :examples:
;  location = stx_fsw_ql_flare_locator(  cfl_counts, quad_counts, total_background )
;
;  :history:
;   28-03-2014 - ECMD (GRAZ), initial release
;   28-05-2014 - ECMD (GRAZ), updated to work with accumulator structures generated
;                             by stx_fsw_eventlist_accumulator.pro.
;                             Default parameters in line with the 28 Feb 2014 CFL document
;                             Now runs over multiple quicklook time intervals
;                             Gives x,y positions as NaN if tests for proceeding
;                             for a given time interval fail.
;                             Added use_energy_weights keyword to set the background weights
;                             based on the used energy range.
;                             Can sum over a number of accumulator intervals specified by int_time
;                             Changed step_change to separate step sizes in x and y directions.
;   05-11-2014 - ECMD (GRAZ), If maximum is at an edge it no longer tries to interpolate.
;   10-11-2014 - ECMD (GRAZ), Now uses output from stx_fsw_background_determination as estimate of the
;                             background counts an calculates an average over a specified number of time
;                             intervals.
;   18-11-2014 - ECMD (GRAZ), if processing multiple cfl time intervals uses corresponding background estimates
;                             rather than one for all intervals
;   22-01-2015 - ECMD (GRAZ), If flare is out of range the edge coordinate is reported rather than NAN
;   23-03-2015 - ECMD (GRAZ), removed capability of working over multiple time intervals
;                             removed some additional checking of input
;                             e_range renamed e_band_idx
;   15-06-2015 - ECMD (Graz), calculation of total background and summing of counts over energy bands
;                             moved from here to stx_fsw_module_coarse_flare_locator::_execute
;   01-02-2016 - ECMD (Graz), cfl_counts, quadrant_counts now normalised together
;                             max quadrant_counts as a proxy for total flux included in observation vector
;                             stx_cfl_fsw_skyvec_table with cfl and quardrants normalised together used
;                             if the dot products have several pixels at the maxiumum value the average value is selected
;   10-01-2018 - ECMD (Graz), all calculations now perfomed using integer arithmetic
;                             normalisation no longer computed on board but contained in sky vector table
;                             normalisation factor
;                             small pixel counts resdistrubited between nearest large pixels
;   01-06-2018 - NH (fhnw),   add flar flag as in/out keyword
;   18-06-2020 - ECMD (Graz), changes to more easily run the routine outside the module
;                             - added default value for flare_flag (0)
;                             - added tab_filename as input keyword 
;
;-
function stx_fsw_ql_flare_locator, $
  cfl_counts_in, quad_counts, total_background, $
  flare_flag = flare_flag, $
  location_status_index = location_status_index, $
  shadow_flags = shadow_flags, $
  shadow_limit = shadow_limit, $
  previous_location =previous_location, $
  lower_limit_counts = lower_limit_counts, $
  upper_limit_counts = upper_limit_counts, $
  out_of_range_factor = out_of_range_factor, $
  tot_bk_factor = tot_bk_factor, $
  quad_bk_factor = quad_bk_factor, $
  cfl_bk_factor = cfl_bk_factor, $
  normalisation_factor = normalisation_factor, $
  tab_data = tab_data, $
  tab_filename = tab_filename, $ 
  sky_x = sky_x, $
  sky_y = sky_y, $
  crop = crop, $
  no_interpolation = no_interpolation, $
  floating_point = floating_point

  ;set the defaults for the configuration parameters if they are not passed in
  ;should match the values given in FSWcoarseFlareLocator.docx
  default, lower_limit_counts, 2L^15L
  default, upper_limit_counts, 2L^19L
  default, out_of_range_factor, 2
  default, tot_bk_factor, 10
  default, quad_bk_factor, 30
  default, cfl_bk_factor, 1
  default, normalisation_factor, [1l,32L,32L]
  default, no_interpolation, 1
  default, floating_point, 0
  default, crop, 0
  default, shadow_flags, [0,0]
  default, previous_location, [0,0]
  default, shadow_limit, [26]
  default, flare_flag, 0
  location_status_index = 2B
  default_location =  [0,0]

  ;if no table is passed then load the default
  if ~isa(tab_data) || ~isa(sky_x) || ~isa(sky_y) then begin

    if ~keyword_set(tab_filename) then tab_filename = floating_point ? 'stx_fsw_cfl_flt_skyvec_table.txt': 'stx_fsw_cfl_int_skyvec_table.txt'

    tab_data = stx_cfl_read_skyvec(loc_file( tab_filename, path = getenv('STX_CFL')), integer = ~floating_point , sky_x = sky_x, sky_y = sky_y)

  endif

 
  ;check all elements in reference table correspond to positions an equal distance apart as algorithm can only handle
  ;a constant sampling step size in x and y
  x_diff = sky_x[1:n_elements(sky_x)-1] - sky_x[0:n_elements(sky_x)-2]
  y_diff = sky_y[1:n_elements(sky_y)-1] - sky_y[0:n_elements(sky_y)-2]
  step_changex = where(x_diff ne x_diff[0])
  step_changey = where(y_diff ne y_diff[0])

  if step_changex[0] eq -1 then stepx = x_diff[0] else begin
    message, 'non-constant step size in skymap x-direction'
    return, -1
  endelse

  if step_changey[0] eq -1 then stepy = y_diff[0] else begin
    message,'non-constant step size in skymap y-direction'
    return, -1
  endelse

  n_res = n_elements(sky_x)

  if keyword_set(crop) then begin
    ; get tabulated sky vector array by taking the inner 65 x 65 elements of the sky vector reference table
    ; and format it to an array of the form [(n_res*n_res),12] so the dot products can be easily calculated
    tab_data_3d     = reform( tab_data, [n_res , n_res, 12] )
    fsw_tab_data_3d = tab_data_3d[ 1:n_res-2, 1:n_res-2, * ]
    fsw_tab_data    = reform( fsw_tab_data_3d, [((n_res-2)*(n_res-2)), 12] )
    n_res  -= 2

  endif else fsw_tab_data = tab_data




  if keyword_set(floating_point)  then begin

    cfl_counts_in    = float(cfl_counts_in)
    quad_counts      = float(quad_counts)
    total_background = float(total_background)

  endif

  total_background /= (32/8)

  ; get the maximum quadrant value for each point and add this vector to the lut array
  quad_max = max(fsw_tab_data[*,8:11], dim = 2)
  fsw_tab_data = [[fsw_tab_data] , [quad_max]]

  ;for clarity separate out the counts for each specific quadrant sum
  quadrant_p = quad_counts[0]
  quadrant_q = quad_counts[1]
  quadrant_r = quad_counts[2]
  quadrant_s = quad_counts[3]


  ;if counts are too low compared to the background no location will be found
  if 100*total_background gt tot_bk_factor*(quadrant_p + quadrant_q + quadrant_r + quadrant_s) then begin
    print, 'Aborting due to high background - No Flare Location'
    location_status_index = 0B
    shadow_flags = [0,0]
    new_flare_flag = flare_flag + ishft(location_status_index, 5)
    return, {pos : default_location, flare_flag : new_flare_flag, shadow_flags:shadow_flags}
  endif

  ;subtract background from observed counts
  quadrant_p -= quad_bk_factor*total_background 
  quadrant_q -= quad_bk_factor*total_background 
  quadrant_r -= quad_bk_factor*total_background 
  quadrant_s -= quad_bk_factor*total_background 
  
  quadrant_p = quadrant_p > 0 
  quadrant_q = quadrant_q > 0 
  quadrant_r = quadrant_r > 0 
  quadrant_s = quadrant_s > 0 


  ;determine if algorithm should proceed based on the quadrant counts
  ;test whether count rate is too high or low for an accurate position estimate
  if quadrant_p + quadrant_q + quadrant_r + quadrant_s lt lower_limit_counts then begin
    print, 'Aborting due to low flux - No Flare Location'
    location_status_index = 0b
    shadow_flags = [0,0]
    new_flare_flag = flare_flag + ishft(location_status_index, 5)
    return, {pos : default_location, flare_flag : new_flare_flag, shadow_flags:shadow_flags}
  endif

  if quadrant_p + quadrant_q + quadrant_r + quadrant_s gt upper_limit_counts then begin
    print, 'Aborting due to high flux - No Flare Location'
    location_status_index = 1b
    new_flare_flag = flare_flag + ishft(location_status_index, 5)
    return, {pos : previous_location, flare_flag : new_flare_flag, shadow_flags:shadow_flags}
  endif

  ;determine whether the flare location is out of range and if so specify direction
  out_of_range = ''
  pos =  keyword_set(floating_point) ? fltarr(2) : intarr(2)

  ;if flare is too far in a given direction it is given a value just outside the range used
  if (10*quadrant_p gt out_of_range_factor*quadrant_q) and (10*quadrant_r GT out_of_range_factor*quadrant_s) then begin
    out_of_range += 'negative-x '
    pos[0] =  min(sky_x)
  endif

  if (10*quadrant_p gt out_of_range_factor*quadrant_r) and (10*quadrant_q GT out_of_range_factor*quadrant_s) then begin
    out_of_range += 'negative-y '
    pos[1]  =  min(sky_y)
  endif

  if (10*quadrant_q gt out_of_range_factor*quadrant_p) and (10*quadrant_s GT out_of_range_factor*quadrant_r) then begin
    out_of_range += 'positive-x '
    pos[0] = max(sky_x)
  endif
  if (10*quadrant_r gt out_of_range_factor*quadrant_p) and (10*quadrant_s GT out_of_range_factor*quadrant_q) then begin
    out_of_range += 'positive-y '
    pos[1]  =  max(sky_y)
  endif

  if strlen(out_of_range) gt 0 then begin
    print, 'Flare out of range in ' + out_of_range + 'direction.'
    new_flare_flag = flare_flag + ishft(location_status_index, 5)
    return, {pos : pos, flare_flag : new_flare_flag, shadow_flags:shadow_flags}
  endif

  small_pixel_contribution = cfl_counts_in[8:11]/2
  cfl_counts = cfl_counts_in[0:7] + [small_pixel_contribution,small_pixel_contribution]

  cfl_counts -= total_background/cfl_bk_factor
  cfl_counts = cfl_counts > 0 


  ;reform vector of quadrant counts
  quadrant_counts = [quadrant_p, quadrant_q, quadrant_r, quadrant_s]

  ;create vector of counts normalised by total cfl and quadrant counts
  counts_vector = [cfl_counts/normalisation_factor[0], quadrant_counts/normalisation_factor[1], max(quadrant_counts)/normalisation_factor[2]]

  ;find maximum location by calculating set of dot products between the reference table and the data
  dot_products = fsw_tab_data#counts_vector

  dot_products = reform(dot_products, n_res, n_res) ; change dot_products to 65 x 65 matrix

  aa = where(dot_products eq max(dot_products), na) ; find maximum of dot_products
  if na gt 1 then begin
    maxi = aa[round(na/2)] 
  endif else begin
    maxi = aa ; if more than one pixel at maxiumum take average
  endelse
  jm = maxi mod n_res ;find where maximum is in x
  km = maxi/n_res ;find where maximum is in y

  x0 = stepx*(jm - (n_res-1)/2) ;convert to position in x
  y0 = stepy*(km - (n_res-1)/2) ;convert to position in y

  d00 = dot_products[jm, km]
  dp0 = dot_products[jm + 1 < (n_res-1)/2, km]
  dm0 = dot_products[jm - 1 >  0, km]
  d0p = dot_products[jm, km + 1 < (n_res-1)/2]
  d0m = dot_products[jm, km - 1 > 0 ]

  if (2*d00 eq dm0 + dp0) or (2*d00 eq d0m + d0p) $
    or (jm eq 0) or (jm eq n_res) or (km eq 0) or (km eq n_res) or keyword_set(no_interpolation) then begin
    x = x0
    y = y0
  endif else begin

    x = x0 + (stepx/2)*(dp0 - dm0)/(2*d00 - dm0 - dp0)
    y = y0 + (stepy/2)*(d0p - d0m)/(2*d00 - d0m - d0p)
  endelse

  if array_equal([x,y], previous_location) then location_status_index = 1b

  fx = abs(jm - (n_res-1)/2) gt shadow_limit ? 1 : 0
  if abs(jm - (n_res-1)/2) eq shadow_limit then fx = shadow_flags[0]
  if jm lt (n_res-1)/2 then fx = -fx

  fy = abs(km - (n_res-1)/2) gt shadow_limit ? 1 : 0
  if abs(km - (n_res-1)/2) eq shadow_limit then fy = shadow_flags[1]
  if km lt (n_res-1)/2 then fy = -fy

  shadow_flags = [fx,fy]
  print, "CFL(x,y):", x, y

  new_flare_flag = flare_flag + ishft(location_status_index, 5)
  return, {pos : [x,y], flare_flag : new_flare_flag, shadow_flags:shadow_flags}
end

