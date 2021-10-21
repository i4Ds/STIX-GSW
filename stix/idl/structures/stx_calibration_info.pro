;+
; :description:
;  stx_calibration_info structure definition 
;
; :categories:
;
; :history:
;    21-Jul-2020 - ECMD (Graz), initial release
;
;-
function stx_calibration_info

str = {type:'stx_calibration_info' ,filename: '', start_time: stx_time(), end_time:stx_time(), duration:0l, quiet_time_raw:0l,quiet_time:0., $
  live_time_raw:0ul,live_time:0.,average_temp_raw:0l,average_temp:0., pixel_mask: bytarr(12),detector_mask :bytarr(32),subspectrum_mask : bytarr(8) ,$
  nbr_spec_poins:intarr(8), nbr_sum_channels:intarr(8),lowest_channel:intarr(8)  }
  
  return, str
  end