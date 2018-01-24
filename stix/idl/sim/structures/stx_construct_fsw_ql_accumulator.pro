;+
; :description:
;    This procedure create a quicklook (or livetime) accumulator structure of
;    type stx_fsw_ql_XXX or stx_fsw_ql_XXX_lt (for livetime).
;
; :categories:
;    construction, accumulation
;
; :params:
;    ql_accumulator_type : in, required, type='string'
;      one of the accumulator types described in dbase/conf/qlook_accumulators.csv
;    time_bins : in, required, type='dblarr()'
;      an array of absolut times (time axis)
;    accumulated_ql_counts : in, required, type='fltarr(a,b,c,d)'
;      a float array with the accumulated quicklook counts [energy, pixel, detector, time]
;      
; :keywords:
;    channel_bin_use : in, optional, type='intarr()', default='undefined'
;      an int array of energies (energy axis); required for quicklook accumulators, optional for livetime accumulators
;    is_trigger_event : in, optional, type='boolean', default=0
;      if set to 1 it indicates that the type to create is a livetime accumulator, or a quicklook accumulator otherwise
;   
;    detector_mask : in, optional, type='ULONG', default=2L^32 - 1
;      a bit mask whitch detectors are enabled
;      
;    pixel_mask : in, optional, type='ULONG', default=2L^12 - 1
;      a bit mask whitch pixels are enabled
;
;      
; :returns:
;    stx_fsw_ql_XXX or stx_fsw_ql_XXX_lt structure
;
; :history:
;    22-May-2014 - Laszlo I. Etesi (FHNW), initial release
;-
function stx_construct_fsw_ql_accumulator, ql_accumulator_type, time_bins, accumulated_ql_counts, channel_bin_use=channel_bin_use, is_trigger_event=is_trigger_event, detector_mask=detector_mask, pixel_mask=pixel_mask
  default, is_trigger_event, 0
  
  return, ql_accumulator = stx_fsw_ql_accumulator( $
    ql_accumulator_type   = ql_accumulator_type, $
    time_bins             = time_bins, $
    accumulated_ql_counts = accumulated_ql_counts, $
    channel_bin_use       = channel_bin_use, $
    is_trigger_event      = is_trigger_event, $
    detector_mask         = detector_mask, $
    pixel_mask            = pixel_mask)
end