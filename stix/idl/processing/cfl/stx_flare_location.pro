;+
; :description:
;    This function returns the sky location offset of a flare from 
;    the STIX optical axis (in arcminutes), given the observed pixel 
;    counts in the STIX coarse flare locator (CFL) subcollimator and 
;    observed detector summed-quadrant counts after averaging across 
;    the Fourier channel subcollimators.
;
; :params:
;    pixel_data:  in, required, type="structure"
;                 full stx_pixel_data structure containing detected 
;                 counts as function of time, energy, subcollimator, 
;                 and pixel (as .data[ntime, nenergy, 32, 12]).
;
; :keywords:
;    subc_file:    in, optional, type="string", default="$STX_GRID/stx_subc_params.txt"
;                  full file path of subcollimator characteristics
;                  look-up file.
;
;    mask_file:    in, optional, type="string", default="$STX_CFL/stx_cfl_subc_mask.txt"
;                  full file path of CFL subcollimator mask file.
;
;    skyvec_file:  in, optional, type="string", default="$STX_CFL/stx_cfl_skyvec_table.txt"
;                  full file path of CFL sky vector look-up file.
;
;    search:       in, optional, type="int", default="1"
;                  flag to set fitting method for sub-pixel location
;                  of dot-product maximum value. Options are:
;                    2: 2D elliptical parabola fit to dynamically 
;                       determined rectangular sub-array surrounding 
;                       dot-product maximum value and containing 
;                       values above 99.95% of the dynamic range.
;                    1: Separate 1D parabola fits to dynamically 
;                       determined sub-arrays in sky X and sky Y 
;                       surrounding the dot-product maximum value and
;                       containing values above 99.95% of the dynamic 
;                       range.
;                    0: 2D circular parabola fit to 3x3 immediate 
;                       neighbour pixels centred on the dot-product 
;                       maximum value.
;
; :returns:
;    [ [sky_x, sky_y], time ] array containing flare source offset 
;    from STIX optical axis (in arcminutes) for all times.
;
; :errors:
;    If a flare location is not determined, this function returns 
;    the following error codes (in order of testing):
;       -10 = subcollimator look-up file not present,
;       -20 = incomplete subcollimator look-up file,
;       -11 = CFL subcollimator mask file not present,
;       -21 = empty CFL subcollimator mask file,
;       -31 = too many CFL subcollimator mask indices,
;       -12 = CFL sky vector look-up file not present,
;       -22 = no sky X or no Y sampling in CFL sky vector file,
;       -32 = incorrect number of vectors in CFL sky vector file.
;
; :history:
;    11-Jun-2013 - Shaun Bloomfield (TCD), created routine
;    21-Aug-2013 - Shaun Bloomfield (TCD), added fitting of 2D
;                  elliptical paraboloid using MPFIT2DFUN()
;    11-Sep-2013 - Shaun Bloomfield (TCD), now uses environment
;                  variables for look-up file default locations
;    25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator 
;                  reading routine stx_construct_subcollimator.pro
;    06-Nov-2013 - Shaun Bloomfield (TCD), modified for dimension
;                  ordering of new flat pixel_data structure input
;    27-Sep-2021 = ECMD (Graz), updated pixel data format      
;                               dot product values can be passed out
;                               background detector values no longer used for subtraction  
;-
function stx_flare_location, pixel_data, $
                             subc_file=subc_file, mask_file=mask_file, $
                             skyvec_file=skyvec_file, search=search, dp_vals = dp_vals,y_edge=y_edge, x_edge= x_edge, debug=debug, $
  sky_x = sky_x, sky_y = sky_y
  
  ;  Set optional keyword defaults
  subc_file = exist(subc_file) ? subc_file : loc_file( 'stx_subc_params.txt', path = getenv('STX_GRID') )
  mask_file = exist(mask_file) ? mask_file : loc_file( 'stx_cfl_subc_mask.txt', path = getenv('STX_CFL') )
  skyvec_file = exist(skyvec_file) ? skyvec_file : loc_file( 'stx_cfl_skyvec_table.txt', path = getenv('STX_CFL') )
  search = exist(search) ? round(search) > 0 < 2 : 1
;  debug = keyword_set(debug)
  
  ;  Build subcollimator geometry structure from look-up file
  subc = stx_construct_subcollimator( subc_file )
  ;  Check that valid subcollimator structure exists
  if ~data_chk( subc, /struct ) then return, subc
  
  ;  Read in mask file indicating suitable subcollimators for the 
  ;  summing of large corner pixels
  mask = stx_cfl_read_mask( mask_file )
  ;  Check that valid mask image exists
  if ( n_elements( mask ) eq 1 ) then return, mask
  
  ;  Read in CFL look-up table of sky vectors [nvectors, npixels]
  ;    N.B. sky vectors are ordered as a 1D spatial array and 
  ;         sky_x and sky_y coordinates are given in arcminutes
  skyvec = stx_cfl_read_skyvec( skyvec_file, sky_x = sky_x, sky_y = sky_y)
  ;  Check that valid sky vector array exists
  if ( n_elements( skyvec ) eq 1 ) then return, skyvec
  ;  Determine number of sky X and Y solutions
  nx = n_elements( sky_x )
  ny = n_elements( sky_y )
  
  ;  Determine number of pixel_data inputs
  npd = (size(pixel_data))[1]
  
  ;  NOT CURRENTLY AVERAGING OVER ANYTHING
  ;  Average pixel counts over all energies and times (i.e., over all
  ;  pixel_data top-level indices, which appear as 3rd dimension for
  ;  pixel_data[*].counts[*, *]), only if number of pixel_data > 1
  ;  TODO: LIE, Maybe only check energies?
  ;        DSB, Will backgrounds be needed in specific energy bands?
;  pixels = ( npd gt 1 ) ? average( pixel_data.counts, 3 ) : pixel_data.counts
  pixels = pixel_data.counts
  
  ;  Determine number of points in time and number of pixels
  ; TODO: LIE, input uniq times externally? Quickfix
;  nt = 1 ;(size( pixels ))[1]
  npix = (size( pixels ))[2]
  
  ;  Determine BKG subcollimator element location
  bkg_loc = where( stregex( subc.label, 'bkg', /boolean, /fold ) )
  ;  Calculate subcollimator pixels
  bkg_info = stx_background_monitor( reform( pixels[bkg_loc, *, *] ), subc_str = subc )
  
  ;  Determine CFL subcollimator element location
  cfl_loc = where( stregex( subc.label, 'cfl', /boolean, /fold ) )
  ;  Extract CFL pixels
  cfl_pix = reform( pixels[cfl_loc, *] )

  ;  Average each pixel over masked subcollimators
  masked_pix = average( pixels[mask, *], 1 )
  
  ;  Sum pairs of large pixels in each detector quadrant 
  ;  [top left, top right, bottom left, bottom right]
  quad_pix = [ masked_pix[0, *] + masked_pix[1, *], $
               masked_pix[2, *] + masked_pix[3, *], $
               masked_pix[4, *] + masked_pix[5, *], $
               masked_pix[6, *] + masked_pix[7, *] ]
  
  ;  Create output [ [sky_x, sky_y], n_time*n_energy ] sub-pixel
  ;  index and sky location coordinate arrays
  sky_sub_pix = fltarr( 2, npd )
  sky_locs = fltarr( 2, npd )
  ;  Create output [ n_time*n_energy ] sky-edge location flag array
  sky_edge = bytarr( npd )
  
  ;  Loop over all points in n_time*n_energy
  for i=0l, npd-1 do begin
     
     ;  Construct observation vector from the CFL large pixels 
     ;  (normalized by their quadratic sum) and the average Fourier 
     ;  subcollimator summed-pixel quadrants (normalized by their 
     ;  quadratic sum)
     obsvec = [ reform( cfl_pix[0:7, i] / sqrt( total( cfl_pix[0:7, i]^2. ) ) ), $
                reform( quad_pix[*, i]  / sqrt( total( quad_pix[*, i]^2.  ) ) ) ]
     ;  Perform dot-product calculation for all sky locations
     dp_vals = skyvec[*, 0:11] # obsvec
     ;  Reorder 1D spatial array of sky vector sampling to 2D
     dp_vals = reform( dp_vals, nx, ny )
     ;  Determine coarse location(s) of maximum dot-product value
     max_loc = where( dp_vals eq max( dp_vals, max_val ), nmax )
     ;  Determine X and Y element positions of maximum location(s)
     max_ind = array_indices( dp_vals, max_loc )
     
     ;  Handle multiple sky locations with same maximum value
     if ( nmax gt 1 ) then begin
        ;  Find mid-point X and mid-point Y location of dot-product 
        ;  maximum locations
        av_max_ind = median( max_ind, dimension = 2, /even )
        
        ;  Extract X profile through mid-point Y location of maximum
        if ( ( av_max_ind[1] mod 1 ) eq 0 ) then x_prof = reform( dp_vals[ *, av_max_ind[1] ] ) else $
           x_prof = average( dp_vals[ *, floor( av_max_ind[1] ):ceil( av_max_ind[1] ) ], 2 )
        ;  Extract Y profile through mid-point X location of maximum
        if ( ( av_max_ind[0] mod 1 ) eq 0 ) then y_prof = reform( dp_vals[ av_max_ind[0], * ] ) else $
           y_prof = average( dp_vals[ floor( av_max_ind[0] ):ceil( av_max_ind[0] ), * ], 1 )
        
        ;  Overwrite X and Y element positions of maximum locations
        max_ind = av_max_ind
        
     endif else begin
        ;  Extract X profile through mid-point Y location of maximum
        x_prof = reform( dp_vals[ *, max_ind[1] ] )
        ;  Extract Y profile through mid-point X location of maximum
        y_prof = reform( dp_vals[ max_ind[0], * ] )
     endelse
     
     ;  Test for dot-product maximum at sky vector location edges
     ;  and half-integer offsets from edges (due to average of two 
     ;  edge-neighbouring rows/columns containing maximum values) 
     if ( max_ind[0] le 0.5 ) or ( max_ind[0] ge (nx-1.5) ) or $
        ( max_ind[1] le 0.5 ) or ( max_ind[1] ge (ny-1.5) ) then begin
        ;  Record sky location in output array
        sky_sub_pix[i] = max_ind
        ;  Record that sky location is at edge of sky vector sampling
        sky_edge[i] = 1b
     endif else begin
        
        ;  Create binary "true" array of positions with a value 
        ;  in the top 0.05% of the profile's dynamic range
        x_bin = ( x_prof - min(x_prof) ) ge 0.9995*max( ( x_prof - min(x_prof) ) )
        y_bin = ( y_prof - min(y_prof) ) ge 0.9995*max( ( y_prof - min(y_prof) ) )
        ;  Find the lower and upper edges of each contiguous block 
        ;  of binary "true" values
        x_sten = [ [ where( ([0, x_bin, 0] - shift( [0, x_bin, 0], 1 ))[1:nx  ] eq  1, n_x_st ) ], $
                   [ where( ([0, x_bin, 0] - shift( [0, x_bin, 0], 1 ))[2:nx+1] eq -1, n_x_en ) ] ]
        y_sten = [ [ where( ([0, y_bin, 0] - shift( [0, y_bin, 0], 1 ))[1:ny  ] eq  1, n_y_st ) ], $
                   [ where( ([0, y_bin, 0] - shift( [0, y_bin, 0], 1 ))[2:ny+1] eq -1, n_y_en ) ] ]
        ;  Determine which contiguous block of binary "true" values 
        ;  contains the location of the maximum value between the 
        ;  lower and upper edges
        x_sten_loc = where( max_ind[0] ge x_sten[*, 0] and max_ind[0] le x_sten[*, 1], n_x_sten_loc )
        y_sten_loc = where( max_ind[1] ge y_sten[*, 0] and max_ind[1] le y_sten[*, 1], n_y_sten_loc )
        ;  Extract only the maximum-containing contiguous block 
        ;  lower and upper edges
        x_edge = reform( x_sten[ x_sten_loc, * ] )
        y_edge = reform( y_sten[ y_sten_loc, * ] )
        ;  Make sure location of maximum is not at an X or Y edge
        if ( floor( max_ind[0] ) eq x_edge[0] ) then x_edge[0] -= 1
        if (  ceil( max_ind[0] ) eq x_edge[1] ) then x_edge[1] += 1
        if ( floor( max_ind[1] ) eq y_edge[0] ) then y_edge[0] -= 1
        if (  ceil( max_ind[1] ) eq y_edge[1] ) then y_edge[1] += 1
        
;        if (debug) then stop
;        
;        x_edge = [ floor( max_ind[0] ) - 1, ceil( max_ind[0] ) + 1 ]
;        y_edge = [ floor( max_ind[1] ) - 1, ceil( max_ind[1] ) + 1 ]
        
;        ;  Make sure at least three points should be included between 
;        ;  and at the lower and upper edges
;        if ( ( x_edge[1] - x_edge[0] ) le 1 ) then x_edge += [ -1, 1 ]
;        if ( ( y_edge[1] - y_edge[0] ) le 1 ) then y_edge += [ -1, 1 ]
        ;  Prevent edge indices running off edge of the sky sampling
        x_edge = x_edge > 0 < (nx-1)
        y_edge = y_edge > 0 < (ny-1)

        ;  Test for different fitting methods to determine sub-pixel 
        ;  location of dot-product maximum value
        case search of
           ;  2D elliptical parabola fit to dynamically determined 
           ;  rectangular sub-array surrounding dot-product maximum 
           ;  value and containing values in the top 0.05% of the 
           ;  dynamic range
           2 : begin
              ;  Extract sub-array of dot-product values surrounding 
              ;  the maximum dot-product value and containing values 
              ;  in the top 0.05% of the dynamic range
              dp_sub = dp_vals[ x_edge[0]:x_edge[1], y_edge[0]:y_edge[1] ]
              sz_sub = size( dp_sub )
              
              ;  Perform 2D parabola fit on dynamically determined 
              ;  rectangular sub-array around the true (or averaged) 
              ;  pixel location of the dot-product maximum value
              ;    N.B. parabola equation is I = a + b( (z-z_0)^2 ) 
              ;         fit coefficients correspond to z_0 measured 
              ;         relative to the profile sub-array lower edge
              pinfo = replicate( { value:0.d, fixed:0, limited:[0, 0], limits:[0.d, 0.d] }, 5 )
              pinfo[*].value = [2.d, sz_sub[1]/2.d, -1.d, sz_sub[2]/2., -1.d]
              pinfo[2].limited[1] = 1
              pinfo[2].limits[1] = 0.d
              pinfo[4].limited[1] = 1
              pinfo[4].limits[1] = 0.d
              prof_coef = mpfit2dfun( 'stx_cfl_2d_para', indgen( sz_sub[1] ), indgen( sz_sub[2] ), dp_sub, $
                                      1, [2.d, sz_sub[1]/2.d, -1.d, sz_sub[2]/2., -1.d], parinfo = pinfo, $
                                      /quiet, dof = dof, bestnorm = chi2, covar = covar, perror = perror )
              
              ;  Create sky X and Y sub-pixel location array with 
              ;  location of fitted 2D parabola centroid (including 
              ;  appropriate shifts to account for the location of 
              ;  the lower X and Y edges of rectangular sub-array)
              sky_sub_pix = [ x_edge[0] + prof_coef[1], $
                              y_edge[0] + prof_coef[3] ]
              
           end
           ;  Separate 1D parabola fits to dynamically determined 
           ;  sub-arrays in X and Y surrounding the dot-product 
           ;  maximum value and containing values in the top 0.05%
           ;  of the dynamic range
           1 : begin
              ;  Extract sub-array of dot-product values surrounding 
              ;  the maximum dot-product value and containing values 
              ;  in the top 0.05% of the dynamic range
              x_prof_sub = x_prof[ x_edge[0]:x_edge[1] ]
              y_prof_sub = y_prof[ y_edge[0]:y_edge[1] ]
              ;  Separately fit parabolas to X and Y sub-arrays
              ;    N.B. parabola equation is I = a + b( (z-z_0)^2 ) 
              ;         fit coefficients correspond to z_0 measured 
              ;         relative to the profile sub-array lower edge
              expr = 'P[0] + ( P[1] * ( ( X - P[2] )^2. ) )'
              x_pinfo = replicate( { value:0.d, fixed:0, limited:[0, 0], limits:[0.d, 0.d] }, 3 )
              x_pinfo[*].value = [2.d, -0.1d, 1.d]
              x_pinfo[1].limited[1] = 1
              x_pinfo[1].limits[1] = 0.d
              y_pinfo = x_pinfo
              x_prof_coef = mpfitexpr( expr, indgen( n_elements(x_prof_sub) ), x_prof_sub, 1, $
                                       [2.d, -0.1d, 1.d], parinfo = x_pinfo, /quiet, dof = x_dof, $
                                       bestnorm = x_chi2, covar = x_covar, perror = x_perror )
              y_prof_coef = mpfitexpr( expr, indgen( n_elements(y_prof_sub) ), y_prof_sub, 1, $
                                       [2.d, -0.1d, 1.d], parinfo = y_pinfo, /quiet, dof = y_dof, $
                                       bestnorm = y_chi2, covar = y_covar, perror = y_perror )
;              xlocerr[i, j] = x_perror[2]
;              ylocerr[i, j] = y_perror[2]
;              xlocerr_red[i, j] = x_perror[2]*sqrt(x_chi2/x_dof)
;              ylocerr_red[i, j] = y_perror[2]*sqrt(y_chi2/y_dof)
              
              ;  Create sky X and Y sub-pixel location array with 
              ;  location of X and Y parabola centroids (including 
              ;  appropriate shifts to account for the location of 
              ;  the lower edges of X and Y profile sub-arrays)
              sky_sub_pix = [ x_edge[0] + x_prof_coef[2], $
                              y_edge[0] + y_prof_coef[2] ]
           end
           ;  2D circular parabola fit to 3x3 immediate neighbour 
           ;  pixels centred on the dot-product maximum value
           0 : begin
              ;  Determine sub-pixel shift of 2D circular parabola 
              ;  from the location of the dot-product maximum value
              fit_shifts = parapeak( dp_vals[ floor( max_ind[0] )-1:floor( max_ind[0] )+1, $
                                              floor( max_ind[1] )-1:floor( max_ind[1] )+1 ] )
              ;  Create sky X and Y sub-pixel location array and fill
              ;  with location of circular parabola centroid in X and
              ;  Y (with appropriate shift applied to account for the
              ;  location of the dot-product maximum value) 
              sky_sub_pix = max_ind + fit_shifts[0:1]
           end
        endcase
        ;  Linearly interpolate sky location X and Y coordinates
        ;  (in arcminutes) to the sub-pixel parabolic fit maximum
        sky_locs[*, i] = [ interpolate( sky_x, sky_sub_pix[0] ), $
                           interpolate( sky_y, sky_sub_pix[1] ) ]
        
     endelse
     
;     if (debug) then stop
     
  ;  End loop over n_time*n_energy
  endfor
  
  ;  Pass out [ [sky_x, sky_y], n_time*n_energy ] array (in arcminutes)
  return, sky_locs
  
end
