;+
; :description:
;    Definiton of the quicklook (or livetime) accumulator structures
;
; :categories:
;    structure definition, accumulation
;
; :params:
;    ql_accumulator_type : in, optional, type='string', default='stx_fsw_ql_accumulator'
;      one of the accumulator types described in dbase/conf/qlook_accumulators.csv
;    time_bins : in, optional, type='dblarr()', default=0
;      an array of absolut times (time axis)
;    accumulated_ql_counts : in, optional, type='fltarr(a,b,c,d)', default='fltarr(1)'
;      a float array with the accumulated quicklook counts [energy, pixel, detector, time]
;      
; :keywords:
;    channel_bin_use : in, optional, type='intarr()', default=0
;      an int array of energies (energy axis); required for quicklook accumulators, optional for livetime accumulators
;    is_trigger_event : in, optional, type='boolean', default=0
;      if set to 1 it indicates that the type to create is a livetime accumulator, or a quicklook accumulator otherwise
;      
; :returns:
;    stx_fsw_ql_XXX or stx_fsw_ql_XXX_lt structure
;
; :history:
;    22-May-2014 - Laszlo I. Etesi (FHNW), initial release (based on work by Richard Schwartz)
;-
function stx_fsw_ql_accumulator, ql_accumulator_type=ql_accumulator_type, time_bins=time_bins, accumulated_ql_counts=accumulated_ql_counts, channel_bin_use=channel_bin_use, is_trigger_event=is_trigger_event, detector_mask=detector_mask, pixel_mask=pixel_mask
  default, is_trigger_event, 0
  default, time_bins, 0
  default, ql_accumulator_type, 'stx_fsw_ql_accumulator'
  default, channel_bin_use, 0
  default, accumulated_ql_counts, fltarr(1)
  default, detector_mask, 2L^32 - 1
  default, pixel_mask, 2L^12 - 1
  
  return, is_trigger_event ? $
    { $
      type                : ql_accumulator_type, $
      time_axis           : stx_construct_time_axis(time_bins), $
      accumulated_counts  : accumulated_ql_counts, $
      detector_mask       : detector_mask $
    } $
    : $
    { $
      type                : ql_accumulator_type, $
      time_axis           : stx_construct_time_axis(time_bins), $
      energy_axis         : stx_construct_energy_axis(select=channel_bin_use), $
      accumulated_counts  : accumulated_ql_counts, $
      detector_mask       : detector_mask, $
      pixel_mask          : pixel_mask $
    }
end