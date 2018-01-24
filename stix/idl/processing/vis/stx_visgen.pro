;+
; :DESCRIPTION:
;   This function calculates stix visibilities from a stix pixel data structure
;
; :CATEGORIES:
;    visibility calculation
;
; :PARAMS:
;    pixel_data : in, required, type="stx_pixel_data"
;                 the pixel data structure containing photon counts per time, energy,
;                 detector, and pixel
;    subc_str   : in, optional, type="stix sucollimator structure"
;                 the stix subcollimator structure with all the grid and detector
;                 configuration data; :KEYWORDS:
;    error      : returns a 1 if 12 element pixel data is passed
;    err_msg    : returns "Error: 12 element pixel data passed. Must use 4 element virtual pixels"
;    _extra     : keyword inheritance, passed to stx_vis
;
; :RETURNS:
;    an array of stx_visibility structures
;
; :EXAMPLES:
;    subc_str = stx_construct_subcollimator( )
;    ph_list = stx_sim_flare( pixel_data=pixel_data )
;    vis = stx_visgen( pixel_data, subc_str ) ;will use the default subc_str if not passed
;
; :HISTORY:
;     27-Jul-2012, Version 1 written by Ines Kienreich
;     17-Sep-2012, corrected for phase-shift. Now
;                  calculates uncalibrated visibilities first, then calibrates
;     04-Feb-2013, Shaun Bloomfield (TCD), modified to ensure
;                  that the visibility phase remains within
;                  -180 -> +180 degrees after phase shift
;     18-jun-2013, Using new definition stx_visibility() as an anonymous
;                  structure. Needs integration with the new
;                  stx_vis.pro separating the structure defaults from
;                  the data dependent values. Changed unnecessary doubles to float
;     16-Jul-2013, Marina Battaglia (TCD), modified to use cartesian representation
;                  of visibilities and +-45 degrees phase shift calibration. This removes
;                  the atan ambiguity
;     22-jul-2013, richard schwartz, broken into components. stx_vis() builds empty visibilities with correct u and v
;                  and this routine fills the pixel dependent terms (obsvis and totflux). Added restriction that
;                  pixel_data is the virtual pixels with only the 4 elements after internal pixel summation step
;     23-jul-2013, richard schwartz, added keyword inheritance. Delivers results identical
;                  to the former version.
;     25-Oct-2013, Shaun Bloomfield (TCD), example text changed to
;                  stx_construct_subcollimator
;-
function stx_visgen, pixel_data, subc_str, _extra = extra, error=error, err_msg=err_msg
  
  det_idx = where(subc_str.label ne 'cfl' and subc_str.label ne 'bkg')
  
  ; Compute some numbers we'll use later
  ; 45 degrees in people units
  vphase_shift = !PI / 4.0

  ; Express phase shift as complex number in cartesian representation
  vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))

  ; Prepare big visibility bag
  visibility_bag = replicate(stx_visibility(), n_elements(pixel_data) * 30)

  for i = 0L, n_elements(pixel_data)-1 do begin
    ; Prepare visibility structures
    visibilities = stx_construct_visibility(subc_str, extra=extra)

    if ppl_typeof(pixel_data,compareto="stx_visibility_bag" ) then begin
      viscomp = pixel_data.vis
      vis_tot = pixel_data.total_flux
    endif else begin

      ; extract pixel data for current time and energy, filter out background monitor and flare locator
      pxldata_extract =  pixel_data[i].counts[det_idx, *]

      ; calculate C - A, D - B, and total flux for each detector and save it to their proper array
      vis_cmina = reform( float( pxldata_extract[ *, 2 ] ) - float( pxldata_extract[ *, 0 ] ) )
      vis_dminb = reform( float( pxldata_extract[ *, 3 ] ) - float( pxldata_extract[ *, 1 ] ) )
      vis_tot   = reform( total( pxldata_extract[ *, * ], 2) )

      ; vis_cmina and vis_cminb are the real and imaginary part of the uncalibrated visibilities
      ; define uncalibrated visibilities
      viscomp = complex(vis_cmina, vis_dminb)
      
      ; calculate sigamp
      delta_re = sqrt( pxldata_extract[ *, 0 ] + pxldata_extract[ *, 2 ] )
      delta_im = sqrt( pxldata_extract[ *, 1 ] + pxldata_extract[ *, 3 ] )
      sigamp   = sqrt( 0.5d * ( delta_re[ * ]^2 + delta_im[ * ]^2))
    endelse

    ; now calibrate by correcting for phase-shift
    ;   vphase_shift = !PI / 4.0
    ;   express phase shift as complex number in cartesian representation
    ;   vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
    ;   vphase_shift is computed outside of the loop
    ; apply phase shift to uncalibrated visibilities
    C = viscomp * vphase_shift

    ; apply grid phase sense correction (obsvis)
    C = complex( real_part(C), -visibilities.phase_sense * imaginary(C) )

    visibilities = stx_construct_visibility( subc_str, $
      energy_range=pixel_data[i].energy_range, $
      time_range=pixel_data[i].time_range, $
      totflux=vis_tot, sigamp=sigamp, $
      obsvis=C, _extra=extra)

    visibility_bag[i*30:i*30+29] = visibilities
  endfor

  return, visibility_bag

  ;Compute some numbers we'll use later
  vphase_shift = !PI / 4.0  ;45 degrees in people units
  ;express phase shift as complex number in cartesian representation
  vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
  ;    IDL> print, vphase_shift
  ;    (     0.707107,     0.707107)  i.e. complex( sqrt(2.0), sqrt(2.0) )/2.0
  ;first we create an empty stx visibility set, then use that to
  ;build an empty cube.
  ;then we fill the obsvis fields based on the pixel_data
  ; extract dimensions from pixel data
  dim = size(pixel_data.data)
  tnums = dim[1]  ; time bins
  ebs = dim[2]  ; energy bins
  dts = dim[3]-2  ; number of detectors
  pxls = dim[4]  ; number of pixels
  error = 0
  err_msg = ''
  if pxls ne 4 then begin ;Error, must use 4 element virtual pixels where sums are already taken to reduce the 12 element real pixels
    error = 1
    err_msg = 'Error, must use 4 element virtual pixels where sums are already taken to reduce the 12 element real pixels'
    message, /info, err_msg
  endif
  stx_vis30 = stx_construct_visibility(subc_str, _extra=extra) ;empty visibilities for stix but with the correct isc, label, u, and v
  subc_str_f_idx = stx_vis30.isc-1
  nfc = 30
  cube = ( tnums * ebs ) eq 1 ? reform( stx_vis30, 1, 1, nfc ) : $
    reform( transpose( reproduce( stx_vis30, tnums * ebs ) ), tnums, ebs, nfc )
  ;cube = replicate(stx_visibility(), tnums, ebs, nfc)

  ; iterate over all time-energy bins
  for time_i = 0, tnums-1 do begin  ; time-loop
    for energy_i = 0, ebs-1 do begin  ; energy bins-loop
      ; extract empty visibilities for one time-energy bin (aka one visibility bag)
      vis = reform(cube[time_i, energy_i, *])

      ; convert energy index to real energy number
      e_range = stx_get_axis_value(pixel_data, energy_i, /energy, /struct)

      ; convert time index to real time number
      t_range = stx_get_axis_value(pixel_data, time_i, /time, /struct)

      vis.energy_range = [e_range.bin_start, e_range.bin_end]

      vis.time_range = reproduce(stx_construct_time(time_in=[t_range.bin_start, t_range.bin_end]),nfc)

      ; extract pixel data for current time and energy, filter out background monitor and flare locator
      pxldata_extract =  pixel_data.data[time_i, energy_i, subc_str_f_idx, *]

      ; calculate C - A, D - B, and total flux for each detector and save it to their proper array

      vis_cmina = reform( float( pxldata_extract[ 0, 0, *, 2 ] ) - float( pxldata_extract[ 0, 0, *, 0 ] ) )
      vis_dminb = reform( float( pxldata_extract[ 0, 0, *, 3 ] ) - float( pxldata_extract[ 0, 0, *, 1 ] ) )
      vis_tot   = reform( total( pxldata_extract[ 0, 0, *, * ], 4) )
      ; save visibility total flux
      vis.totflux = vis_tot

      ; vis_cmina and vis_cminb are the real and imaginary part of the uncalibrated visibilities
      ;define uncalibrated visibilities
      viscomp = complex( vis_cmina, vis_dminb)
      ; now calibrate by correcting for phase-shift
      ;      vphase_shift = !PI / 4.0
      ;      ;express phase shift as complex number in cartesian representation
      ;      vphase_shift = complex( cos( vphase_shift ), sin( vphase_shift ))
      ;      vphase_shift is computed outside of the loop
      ;apply phase shift to uncalibrated visibilities
      C = viscomp * vphase_shift
      ;apply grid phase sense correction
      C= complex( real_part(C), -vis.phase_sense * imaginary(C) )
      ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;      ; vis_cmina and vis_cminb are the real and imaginary part of the uncalibrated visibilities
      ;      ; now calibrate by correcting for phase-shift
      ;      vphase_shift = !PI / 4.d
      ;
      ;      ; using "atan" produced images mirrored along the x/y-pos axis
      ;      vphase_atan=atan( dcomplex(vis_cmina, vis_dminb), /phase )
      ;
      ;      ; use phase orientation of grids
      ;      vphase = vphase_atan + vphase_shift
      ;      ; ensure that phase remains within -180 -> +180
      ;      ; degrees after application of phase shift
      ;      vphase = ( (vphase+!pi) mod (2.d*!pi) ) - !pi
      ;      ; apply grid phase sense correction
      ;      vphase = -vis.phase_sense * vphase
      ;
      ;      vamp = sqrt(vis_cmina^2+vis_dminb^2) ;amplitude
      ;      C = complex( vamp * cos(vphase), vamp * sin(vphase))
      ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; save obsvis
      vis.obsvis = C

      ; calculate sigamp

      delta_re = sqrt( pxldata_extract[ 0, 0, *, 0 ] + pxldata_extract[ 0, 0, *, 2 ] )
      delta_im = sqrt( pxldata_extract[ 0, 0, *, 1 ] + pxldata_extract[ 0, 0, *, 3 ] )
      sigamp   = sqrt( 0.5 * ( delta_re[ * ]^2 + delta_im[ * ]^2))
      ; save sigamp
      vis.sigamp = sigamp

      ; save visibilities back to cube
      cube[time_i, energy_i, *] = vis
    endfor ;Finish energy loop
  endfor ;Finish time loop
  return, cube
end
