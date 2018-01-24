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
;
;
;
;  :returns:
;   pos:         2 element array giving the [x,y] position of the peak in arcminutes
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
;
;-
function stx_fsw_ql_flare_locator, $
    cfl_counts, quad_counts, total_background, $
    lower_limit_counts = lower_limit_counts, $
    upper_limit_counts = upper_limit_counts, $
    out_of_range_factor = out_of_range_factor, $
    tot_bk_factor = tot_bk_factor, $
    quad_bk_factor = quad_bk_factor, $
    cfl_bk_factor = cfl_bk_factor, $
    normalisation_factor = normalisation_factor, $
    tab_data = tab_data, $
    sky_x = sky_x, $
    sky_y = sky_y
    
  ;set the defaults for the configuration parameters if they are not passed in
  ;should match the values given in FSWcoarseFlareLocator.docx
  default, lower_limit_counts, 2.^15.
  default, upper_limit_counts, 2.^19.
  default, out_of_range_factor, 2.0
  default, tot_bk_factor, 0.1
  default, quad_bk_factor, 30.
  default, cfl_bk_factor, 1.
  default, normalisation_factor, [0.25,0.25,0.25,0.25,1.] 
  ;if no table is passed then load the default  
  if ~isa(tab_data) || ~isa(sky_x) || ~isa(sky_y) then begin
    tab_data = stx_cfl_read_skyvec(loc_file( 'stx_fsw_cfl_skyvec_table.txt', path = getenv('STX_CFL') ), sky_x = sky_x, sky_y = sky_y)
  endif
  
  
  ;check all elements in reference table correspond to positions an equal distance apart as algorithm can only handle
  ;a constant sampling step size in x and y
  x = sky_x[1:n_elements(sky_x)-1] - sky_x[0:n_elements(sky_x)-2]
  y = sky_y[1:n_elements(sky_y)-1] - sky_y[0:n_elements(sky_y)-2]
  step_changex = where(x ne x[0])
  step_changey = where(y ne y[0])
  
  if step_changex[0] eq -1 then stepx = x[0] else begin
    message, 'non-constant step size in skymap x-direction'
    return, -1
  endelse
  
  if step_changey[0] eq -1 then stepy = y[0] else begin
    message,'non-constant step size in skymap y-direction'
    return, -1
  endelse
  
  ; get tabulated sky vector array by taking the inner 65 x 65 elements of the sky vector reference table
  ; and format it to an array of the form [4225,12] so the dot products can be easily calculated
  tab_data_3d     = reform( tab_data, [67, 67, 12] )
  fsw_tab_data_3d = tab_data_3d[ 1:65, 1:65, * ]
  fsw_tab_data    = reform( fsw_tab_data_3d, [(65*65), 12] )
  
  ; get the maximum quadrant value for each point and add this vector to the lut array
  quad_max = max(fsw_tab_data[*,8:11], dim = 2) 
  fsw_tab_data = [[fsw_tab_data] , [quad_max]]
  
  ;for clarity separate out the counts for each specific quadrant sum
  quadrant_p = quad_counts[0]
  quadrant_q = quad_counts[1]
  quadrant_r = quad_counts[2]
  quadrant_s = quad_counts[3]
  
  ;determine if algorithm should proceed based on the quadrant counts
  ;test whether count rate is too high or low for an accurate position estimate
  if quadrant_p + quadrant_q + quadrant_r + quadrant_s lt lower_limit_counts then begin
    print, 'Aborting due to low flux - No Flare Location'
    return, [!values.f_nan,!values.f_nan]
  endif
  
  if quadrant_p + quadrant_q + quadrant_r + quadrant_s gt upper_limit_counts then begin
    print, 'Aborting due to high flux - No Flare Location'
    return, [!values.f_nan,!values.f_nan]
  endif
  
  ;determine whether the flare location is out of range and if so specify direction
  out_of_range = ''
  pos = fltarr(2)
  ;if flare is too far in a given direction it is given a value just outside the range used
  if (quadrant_p gt out_of_range_factor*quadrant_q) and (quadrant_r GT out_of_range_factor*quadrant_s) then $
    out_of_range += 'negative-x ' & pos[0] += min(sky_x)
  if (quadrant_p gt out_of_range_factor*quadrant_r) and (quadrant_q GT out_of_range_factor*quadrant_s) then $
    out_of_range += 'negative-y ' & pos[1] += min(sky_y)
  if (quadrant_q gt out_of_range_factor*quadrant_p) and (quadrant_s GT out_of_range_factor*quadrant_r) then $
    out_of_range += 'positive-x ' &  pos[0] += max(sky_x)
  if (quadrant_r gt out_of_range_factor*quadrant_p) and (quadrant_s GT out_of_range_factor*quadrant_q) then $
    out_of_range += 'positive-y ' & pos[1] += max(sky_y)
    
  if strlen(out_of_range) gt 0 then begin
    print, 'Flare out of range in ' + out_of_range + 'direction.'
    return, pos
  endif
  
  ;if counts are too low compared to the background no location will be found
  if total_background gt tot_bk_factor*total(cfl_counts) then begin
    print, 'Aborting due to high background - No Flare Location'
    return, [!values.f_nan,!values.f_nan]
  endif
  
  
  ;subtract background from observed counts
  quadrant_p -= quad_bk_factor*total_background
  quadrant_q -= quad_bk_factor*total_background
  quadrant_r -= quad_bk_factor*total_background
  quadrant_s -= quad_bk_factor*total_background
  cfl_counts -= cfl_bk_factor*total_background
  
  ;reform vector of quadrant counts
  quadrant_counts = [quadrant_p, quadrant_q, quadrant_r, quadrant_s]
  
  ;create vector of counts normalised by total cfl and quadrant counts
  counts_vector = [cfl_counts, quadrant_counts*normalisation_factor[0:3], normalisation_factor[4]*max(quadrant_counts)]
  counts_vector /=  sqrt( total( counts_vector^2. ) ) 
  
  ;find maximum location by calculating set of dot products between the reference table and the data
  dot_products = fsw_tab_data#counts_vector
  
  dot_products = reform(dot_products, 65, 65) ; change dot_products to 65 x 65 matrix
  
  aa = where(dot_products eq max(dot_products), na) ; find maximum of dot_products
  if na gt 1 then maxi = aa[round(na/2.)] else maxi = aa ; if more than one pixel at maxiumum take average
  jm = maxi mod 65 ;find where maximum is in x
  km = maxi/65 ;find where maximum is in y
  
  x = stepx*(jm - 32) ;convert to position in x
  y = stepy*(km - 32) ;convert to position in y
  
    return, [x,y]
end

