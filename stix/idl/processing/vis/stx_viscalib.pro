;+
; :description:
;   This function calibrates uncalibrated visibilities
;
; :categories:
;    visibility calculation
;
; :params:
;    visin : visibility cube from stx_visgen
;    
; :keywords:
;    
; :returns:
;    an array of calibrated stx_visibility structures
;
; :examples:
;    subc_str = stx_construct_subcollimator( )
;    ph_list  = stx_sim_flare( pixel_data=pixel_data )
;    vis      = stx_visgen( pixel_data, subc_str )
;    viscal   = stx_viscalib( vis )
;
; :history:
;     27-Jul-2012, written by Marina Battaglia (FHNW)
;     25-Oct-2013, Shaun Bloomfield (TCD), example text changed to
;                  stx_construct_subcollimator
;-
function stx_viscalib, cube
      ;extract the uncalibrated visibilities
      visuncal=cube.obsvis
      
      
      ;amplitude calibration factor for idealized case, large pixels:
      G1=2    ; account for slit/slat ratio
      G2=sqrt(2d)
      
      ;apply amplitude calibration factor
      viscal=G1*G2*visuncal
      ;viscal = visuncal
      ;replaces the uncalibrated visibilities by the calibrated
      cube.obsvis=viscal
      
      
  return, cube
end
