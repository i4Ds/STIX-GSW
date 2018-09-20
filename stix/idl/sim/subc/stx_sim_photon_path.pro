;+
; :description:
;    This function simulates the path that photons take through the
;    STIX instrument using given incident locations on the STIX front
;    face and photon trajectories.
;
; :params:
;    ph_str:    in, required, type="structure"
;               n-element array of photon information structures. Each
;               structure element contains the incident photon X and Y
;               arcsec location in the Sun-facing plane-of-sky (X_LOC,
;               Y_LOC), the photon path tilt angle in degrees from the
;               STIX optical axis (THETA), the photon path position
;               angle in degrees with positive measured CCW from Solar
;               West in the Sun-facing view plane-of-sky (OMEGA), the
;               photon X location on the STIX front face with positive
;               measured to detector right when viewing from the Sun,
;               (X_POS) and the photon Y locations on the STIX front
;               face with positive measured to detector up when
;               viewing from the Sun (Y_POS).
;
;    subc_str:  in, required, type="structure" 
;               subcollimator geometry structure.
;
;    src_str:   in, required, type="structure" 
;               source structure detailing location/characteristics
;               of photon source.
;
;    bkg_flux:  in, required, type="long" 
;               32-element array of simulated background photon
;               fluxes in cm^-2. These are not the total number of 
;               background photons simulated as being "recorded" in
;               each STIX subcollimator detector, which is instead 
;               0.88 x 0.92 x bkg_flux[i] (i.e., each detector has 
;               dimensions of 8.8 mm by 9.2 mm).
;
;    bkg_duration:  in, required, type="long" 
;                   duration in seconds to simulate background photon
;                   flux.
;
; :keywords:
;    f2r_sep:  in, optional, type="float", default="550"
;              separation distance in mm between the front and rear
;              grid planes measured along the STIX optical axis.
;
;    r2d_sep:  in, optional, type="float", default="47"
;              separation distance in mm between the rear grid and
;              detector planes measured along the STIX optical axis.
;
;    ph_loc:   out, optional, type="float", default="empty/false"
;              [n, 2, 3] array containing the locations for n photons
;              (1st dimension) in coordinates of [X, Y] relative to
;              STIX optical axis (2nd dimension), at the [front grid,
;              rear grid, detector] planes (3rd dimension) that are
;              actually recorded.
;
;    debug:    in, optional, type="bool", default="empty/false"
;              if set, the function returns an error code when no
;              photons are transmitted by the front/rear grids or
;              recorded by the detectors.
;
; :returns:
;    If photons are transmitted through the STIX grids and fall on any
;    detector, this function returns the photon counts recorded in
;    each pixel and subcollimator. L.E: Returned photons are grouped by
;    detector index.
;
; :errors:
;    If no photons are recorded, this function returns the following
;    error codes (in order of testing):
;      -2 = photons do not fall on both an active rear grid area and
;           an active detector area,
;      -3 = photons are not transmitted through the front grid plane,
;      -4 = photons are not transmitted through rear grid plane.
;
; :history:
;    21-Aug-2012 - Shaun Bloomfield (TCD), created routine
;    20-Nov-2012 - Shaun Bloomfield (TCD), implemented final angle
;                  conventions
;    14-Jan-2013 - Shaun Bloomfield (TCD), new keyword default logic
;    30-Apr-2013 - Shaun Bloomfield (TCD), added background flux and
;                  vectorized photon handling
;    25-Oct-2013 - Shaun Bloomfield (TCD), incorporated modified
;                  subcollimator structure tagnames
;    28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;    30-Jul-2014 - Shaun & Laszlo, removed background from routine
;    13-Aug-2014 - Laszlo I. Etesi (FHNW), added warning to
;                  documentation "returns" tag
;    28-Oct-2014 - Shaun & Laszlo, fixed bug in handling of single
;                  count case
;    21-Oct-2014 - Laszlo I. Etesi (FHNW), small bugfix for single 
;                  photon case
;    13-Nov-2014 - Shaun Bloomfield (TCD), modified to trace photon 
;                  paths backwards to the rear and front grids from 
;                  the positions now distributed on the detectors
;    27-Nov-2014 - Shaun Bloomfield (TCD), efficiency speed-up from
;                  changing WHERE to HISTOGRAM with REVERSE_INDICIES
;    29-Nov-2014 - Shaun Bloomfield (TCD), efficiency speed-up from
;                  testing the source structure offset angle against
;                  front/rear grid edge angles from detector edges
;                  (added source structure as input to this routine)
;    01-Dec-2014 - Shaun Bloomfield (TCD), efficiency speed-up from
;                  implementing HISTOGRAM with REVERSE_INDICIES for
;                  idealized-grid pixel binning
;     19-feb-2016 - Rschwartz70@gmail.com, we keep the positional arrays
;                   in a simple direct format to facilitate the computations instead
;                   of storing them in a multi-d array. As we don't need to use
;                   this outside of this routine there is no need and it does 
;                   take a lot of extra time
;     20-Sep-2016 - Nicky Hochmuth (FHNW), 
;                   added accumulation of pixel data again
;    
; :todo:
;    30-Jul-2014 - Shaun & Laszlo, * replace legacy return format with ph_str
;                                  * add attenuator path (attenuator_flag)
;-
function stx_sim_photon_path, ph_str, subc_str, src_str, $;bkg_flux, bkg_duration, $
                              f2r_sep=f2r_sep, r2d_sep=r2d_sep, $
                              ph_loc=ph_loc, debug=debug, _extra=_extra
  ;clock = tic('unit_cor')
  ;  Set up STIX instrument geometry
  ;  Axial front grid plane to rear grid plane separation (in mm)
  f2r_sep = exist( f2r_sep ) ? f2r_sep : 550.
  ;  Axial rear grid plane to detector plane separation (in mm)
  r2d_sep = exist( r2d_sep ) ? r2d_sep :  47.
  
  ;  Set optional keyword defaults
  debug = keyword_set(debug)
  
  ;  Create output array for detected photon numbers in 12 detector 
  ;  pixels of 32 subcollimators (30 Fourier channels, 1 coarse flare 
  ;  locator, and 1 flux monitor)
  det_subc = ulonarr(32, 12)
  
  ;  Determine photon directional corrections in [X & Y] coordinates 
  ;  for unit path length along optical axis from photon path tilt 
  ;  from optical axis (theta) and position angle of the source on 
  ;  the STIX front face when viewed from the Sun (omega, measured 
  ;  clockwise from STIX positive y-axis)
  ;    N.B. omega represents the position angle that the photons
  ;         have come from, so describes the position angle back 
  ;         along photon travel path
  unit_cor =    [ [ tan( ph_str.theta*!dtor ) * sin( ph_str.omega*!dtor ) ], $
               [ tan( ph_str.theta*!dtor ) * cos( ph_str.omega*!dtor ) ] ]
  
  ;We're going to use these positions so pull them out to get ready to use
  ;them already extracted. This proves to be the most efficient way instead of
  ;loading them into a 3d array only to pull them out again. Not a great way to pull them
  ;out to examine them, but far better for using them internally when there are lots of
  ;independent values
  y_pos   = ph_str.y_pos
  f_sep   = (f2r_sep+r2d_sep) * unit_cor
  r_sep   = r2d_sep*unit_cor
  y_pos_f = y_pos + f_sep[*,1]
  y_pos_r = y_pos + r_sep[*,1]
  x_pos = ph_str.x_pos
  x_pos_f = x_pos + f_sep[*,0]
  x_pos_r = x_pos + r_sep[*,0]
  
  

  ;toc,;clock
  ;clock = tic('build subc')
  ;  Calculate nominal offsets between the active area edges of
  ;  a subcollimator detector and the front grid and rear grid
  subc_offset_x = [ subc_str[0].front.edge.right, subc_str[0].rear.edge.right ] - subc_str[0].det.edge.right
  subc_offset_y = [ subc_str[0].front.edge.top,   subc_str[0].rear.edge.top   ] - subc_str[0].det.edge.top
  ;  Calculate angles (in arcsec) that nominal offsets correspond to
  subc_angle_x = ( atan( subc_offset_x / [ (f2r_sep+r2d_sep), r2d_sep ] ) / !dtor ) * 3600.
  subc_angle_y = ( atan( subc_offset_y / [ (f2r_sep+r2d_sep), r2d_sep ] ) / !dtor ) * 3600.
  ;toc,;clock
  ;  Check if source angle offset from STIX optical axis is within
  ;  the angles subtended by the edge of the detector and the edge
  ;  of the front grid active area
  ;clock = tic('assign subc_f_n')
  subc_f_n = fltarr(n_elements(ph_str[*].subc_d_n))
  subc_r_n = fltarr(n_elements(ph_str[*].subc_d_n))
  
  if ( ( abs(src_str.xcen) lt ( subc_angle_x[0] ) ) and $
       ( abs(src_str.ycen) lt ( subc_angle_y[0] ) ) ) then begin
         ;  If so, duplicate subcollimator detector numbers for both
         ;  the front grid and rear grid (as the rear grids subtend 
         ;  larger angles
         subc_f_n = ph_str[*].subc_d_n
         subc_r_n = ph_str[*].subc_d_n
         ;  Flag that subcollimator rear grid numbers have been set
         rear_done = 1
  ;  End duplicating of subcollimator numbers
  endif else begin
    ;  Flag that subcollimator rear grid numbers have not been set
    rear_done = 0
    ;  Otherwise, check photon locations against active area edges
    ;  of the front grids
    ;  Loop over all 32 subcollimators
    ;[ [ [ [ [ph_str.x_pox_pos = ph_str.x_pos
    
    for i=1, 32 do $
      ;  Assign subcollimator number to photons at front grid plane
      ;    N.B. subcollimator numbers range from 1-32, so values of 0 
      ;         indicate not falling within an active front grid area
      ;  
      
      subc_f_n += ( ( x_pos_f gt subc_str[i-1].front.edge.left   ) and $
                              ( x_pos_f lt subc_str[i-1].front.edge.right  ) and $
                              ( y_pos_f gt subc_str[i-1].front.edge.bottom ) and $
                              ( y_pos_f lt subc_str[i-1].front.edge.top    ) ) * i
                              
  ;  End checking of subcollimator active areas
  endelse
  
  foverlap =  where(subc_f_n ne ph_str.subc_d_n,/null)
  subc_f_n[foverlap] = 0
  
  ;toc,;clock
  ;clock = tic('assign subc_r_n')
  ;  Check if photons already known to fall inside their generated
  ;  subcollimator number (i.e., assigned by front grid angle test)
  if ~rear_done then $
    ;  Check if source angle offset from STIX optical axis is within
    ;  the angles subtended by the edge of the detector and the edge
    ;  of the rear grid active area
    if ( ( abs(src_str.xcen) lt ( subc_angle_x[1] ) ) and $
         ( abs(src_str.ycen) lt ( subc_angle_y[1] ) ) ) then begin
           ;  If so, duplicate subcollimator detector numbers for the
           ;  rear grid
           subc_r_n = ph_str[*].subc_d_n
    ;  End duplicating of subcollimator numbers
    endif else begin
      ;  Otherwise, check photon locations against active area edges
      ;  of the rear grids
      ;  Loop over all 32 subcollimators
      for i=1, 32 do $
        ;  Assign subcollimator number to photons at rear grid plane
        ;    N.B. subcollimator numbers range from 1-32, so values of 0 
        ;         indicate not falling within an active rear grid area
        subc_r_n += ( ( x_pos_r gt subc_str[i-1].rear.edge.left   ) and $
                                ( x_pos_r lt subc_str[i-1].rear.edge.right  ) and $
                                ( y_pos_r gt subc_str[i-1].rear.edge.bottom ) and $
                                ( y_pos_r lt subc_str[i-1].rear.edge.top    ) ) * i
                                endelse
  ;toc,;clock
  ;  Set angle-modified grid thickness (in mm)
  ;  TODO: make grid thickness into parameter read from look-up file
  grid_thick = 0.4 / cos( ph_str.theta *!dtor)
  
  roverlap =  where(subc_r_n ne ph_str.subc_d_n, /null)
  subc_r_n[roverlap] = 0
  
  ;  Initiate material path lengths for front and rear grid planes 
  ;  to default assumption of passing through slat/non-active area
  f_path_length = grid_thick
  r_path_length = grid_thick
  
;  ;  Determine photons that fall an active detector area
;  ph_keep = where( ( ph_str[*].subc_d_n ne 0 ), n_keep )
;  
;  ;  Retain only potentially detected photons and locations
;  if ( n_keep ne 0 ) then begin
;     ph_str = ph_str[ph_keep]
;     ph_loc = ph_loc[ph_keep, *, *]
;  endif else $
;     ;  Return error on debug if no photons are potentially
;     ;  transmitted and detected
;     if ( debug ) then $
;        return, -2 else begin
;           ;  Set photon structure to empty
;           ph_str = 0
;           ;  Otherwise return an empty pixel/subcollimator output array
;           return, det_subc * 0
;        endelse
  ;clock = tic('front grid trans')
  ;  FRONT GRID TRANSMISSION
  ;  Bin photon front grid subcollimator numbers
  ;    0 is outside all subcollimator front grid active areas
  hist_f = histogram( subc_f_n, min=0, max=32, bin=1, reverse_indices=ri )
  ;  Loop over all 32 subcollimators
  for i=1, 32 do begin
     ;  If photons fall on the selected front grid number
     zi = reverseindices( ri, i ) ;switching to reverseindices call, ras, 9-dec-2015
     if ( hist_f[i] ne 0 ) then $
        ;  Determine photon path lengths through the front grid plane
        f_path_length[ zi ] = $
            stx_sim_grid_tran( x_pos_f[zi], y_pos_f[zi], $
                               grid_thick[zi], subc_str[i-1], _extra = _extra )
                               endfor
  ;toc,;clock
  ;clock = tic( 'rear grid trans')
  ;  REAR GRID TRANSMISSION
  ;  Bin photon rear grid subcollimator numbers
  ;    0 is outside all subcollimator rear grid active areas
  hist_r = histogram( subc_r_n, min=0, max=32, bin=1, reverse_indices=ri )
  ;  Loop over all 32 subcollimators
  for i=1, 32 do begin
     ;  If photons fall on the selected rear grid
     zi = reverseindices( ri, i )
     if ( hist_r[i] ne 0 ) then $
        ;  Determine photon path lengths through the rear grid
        r_path_length[zi] = $
            stx_sim_grid_tran( x_pos_r[zi] ,  y_pos_r[zi], $
                               grid_thick[zi], subc_str[i-1], /rear, _extra = _extra )
   endfor
   ;Use the summed path because that is the efficient way to compute probability
   ph_str.fplusr_path_length = f_path_length + r_path_length
   
   ;toc,;clock
;  ;  TO DO - MOVE TO OUTSIDE ALL SOURCES BEING GENERATED, AS ONLY TO
;  ;          BE CALCULATED ONCE UNIFORMLY OVER WHOLE TIME INTERVAL
;  ;  BACKGROUND PHOTON GENERATION
;  ;  Determine number of background photons in each subcollimator
;  ;  ( duration [s] * background flux [photons/cm^2/s] * area [cm^2] )
;  nbkg_subc = ceil( 1 * bkg_flux * subc_str.det.area, /l64 )
;  ;  Determine total number of background photons
;  nbkg_tot = total( nbkg_subc, /preserve_type )
;  ;  Determine cumulative number of background photons over all
;  ;  subcollimators
;  ;  N.B. padded with 0 before first subcollimator and starting
;  ;       element position in expanded photon array added as this
;  ;       will be used to define element position boundaries for
;  ;       background photons in each subcollimator
;  nbkg_subc_cumul = n_keep + [ 0, [total( nbkg_subc, /cumulative, /preserve_type )] ]
;  ;  Expand source photon structure to accommodate background photons
;  ph_str = [ temporary(ph_str), replicate( stx_sim_photon_structure(), nbkg_tot ) ]
;  ;  Expand source photon X/Y location front/rear/detector plane array
;  ;  to accommodate background photons (will only use X/Y location for
;  ;  detector plane)
;  ph_loc = transpose( [ [ [ transpose( temporary(ph_loc) ) ] ], [ [ fltarr(3, 2, nbkg_tot) ] ] ] )
;  ;  Set background photon sources to 0 to indicate background origin
;  ph_str[n_keep:*].source = 0
;  ;  Begin loop over all 32 subcollimators
;  for i=1, 32 do begin
;     ;  Set detector subcollimator numbers (1->32) in batches of size
;     ;  nbkg_subc[i]
;     ;  i.e., photon counters starting at nbkg_subc_cumul[i-1] and
;     ;        ending at nbkg_subc_cumul[i]-1
;     ph_str[ nbkg_subc_cumul[i-1]:nbkg_subc_cumul[i]-1 ].subc_d_n = i
;     ;  Randomize subcollimator background photon locations (in 
;     ;  mm relative to the STIX optical axis) and append to previous
;     ;  background photon locations
;     ph_loc[ nbkg_subc_cumul[i-1]:nbkg_subc_cumul[i]-1, *, 2 ] = $
;        [ [ ( ( ( randomu(seed1, nbkg_subc[i-1]) - 0.5 ) * subc_str[i-1].det.xsize ) + subc_str[i-1].det.x_cen ) ], $
;          [ ( ( ( randomu(seed2, nbkg_subc[i-1]) - 0.5 ) * subc_str[i-1].det.ysize ) + subc_str[i-1].det.y_cen ) ] ]
;  ;  End loop over all 32 subcollimators
;  endfor
;  
  ;clock = tic('detector recording')
  ;  DETECTOR RECORDING
  ;  Bin photon detector subcollimator numbers
  ;    0 is outside all subcollimator detector active areas
  hist_d = histogram( ph_str[*].subc_d_n, min=0, max=32, bin=1, reverse_indices=ri )
  ;  Loop over all 32 subcollimators
  pixel_n = ph_str.pixel_n
  for i=1, 32 do begin
     ;  If photons fall on the selected detector
     zi = reverseindices( ri, i )
     if ( hist_d[i] ne 0 ) then $    
        ;  Determine pixel indices for the selected subcollimator
       pixel_n[zi] = stx_sim_det_pix( x_pos[zi],  y_pos[zi], subc_str[i-1].det.pixel.edge )
       
      ; plot_det_counts,  x_pos[zi],  y_pos[zi], subc_str, i 
       
       ;out = stx_sim_det_pix_old( [[x_pos[zi]],[y_pos[zi]]], subc_str[i-1])
                             endfor
    ph_str.pixel_n = pixel_n
    ;toc,;clock
    
  ;TODO: N.H. why is it dissabled?
  if 1 then begin ;Branch no longer used
  ;clock = tic('photons through slits')
  ;  IDEAL GRID PIXEL BINNING
  ;  Determine photons that fall on slit gaps in both the front and
  ;  rear grid planes
  ph_use = where( f_path_length eq 0 and $
                  r_path_length eq 0, n_use )
  ;  If photons fall on slits of both grids
  if ( n_use ne 0 ) then begin
     ;  Bin photon detector subcollimator numbers
     ;    0 is outside all subcollimator detector active areas
     hist_dp = histogram( ph_str.subc_d_n[ph_use], min=0, max=32, bin=1, reverse_indices=ri )
     ;  Loop over all 32 subcollimators
     for i=1, 32 do begin
        ;  If photons fall on the selected detector
        zi = reverseindices( ri, i )
        if ( hist_dp[i] ne 0 ) then $
           ;  Bin photon numbers in terms of integer pixel indices
           det_subc[i-1, *] = histogram( [ph_str.pixel_n[ ph_use[ ri[ ri[i]:ri[i+1]-1 ] ] ]], min=0, max=11, bin=1 )
           
          ; plot_det_counts,  x_pos[ph_use[ ri[ ri[i]:ri[i+1]-1 ] ] ],  y_pos[ph_use[ ri[ ri[i]:ri[i+1]-1 ] ] ], subc_str, i

           endfor
  endif
  ;toc,;clock
  endif else det_subc[*] = 0 ;value no longer used, RAS, 11-dec-2015
  
  ;help, clock
  ;  Pass out binned detector [subcollimator, pixel] array for
  ;  simulated flare source and background photons
  
  
  ;added by n.h. to get the accumulated pixel data again
  ;it was dissabled by R.S.
  ph_use = where( f_path_length eq 0 and r_path_length eq 0, n_use)
  if n_use gt 0 then det_subc[ph_str.subc_d_n[ph_use] - 1, ph_str.pixel_n[ph_use]] ++
  
  return, det_subc
  
end
