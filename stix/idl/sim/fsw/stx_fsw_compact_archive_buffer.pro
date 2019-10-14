;+
; :file_comments:
;    This function is part of the FLIGHT SOFTWARE (FSW) package and
;    will accumulate a given archive buffer into a 2d and/or 4d spectrogram
;
; :categories:
;    flight software
;
; :examples:
;       counts = stx_fsw_compact_archive_buffer(archive_buffer)
; :history:
;    02-Sep-2015 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :description:
;    This internal routine accumulates a given archive buffer into a 2d and/or 4d spectrogram;
; :params:
;
;    stx_fsw_archive_buffer :   in, required, type="stx_archive_buffer"
;                       an array of archive buffer entries
;                       
; :keywords:
;    start_time :       in, optional, type="stx_time", default=stx_time()
;                       the total time reference for the relative timing in the archive buffer
;
;    total_counts :     out, optional, type="ulong64[energy,time]"
;                       a 2D count spectrogram [energy,time] summed over detector and pixel
;
;    time_axis :        out, optional, type="stx_time_axis"
;                       an time axis associated with the time dimension
;
;    time_edges :       out, optional, type="double array"
;                       the time axis edges associated with the time dimension
;
;    detector_mask :    in, optional, type="byte array", default=[0:32]=1
;                       a mask witch detectors to exclude from the accumulation
;                       counts from disabled detectors are set to 0 
;                       and only applayed to the DISABLED_DETECTORS_PIXEL_COUNTS and DISABLED_DETECTORS_TOTAL_COUNTS out keywords
;                       
;    disabled_detectors_pixel_counts :     out, optional, type="ulong[energy,pixel,detector,time]"
;                       a 4D count spectrogram [energy,pixel,detector,time] summed over all archive buffer entries
;                       counts from disabled detectors are set to 0 
;                       
;    disabled_detectors_total_counts :     out, optional, type="ulong64[energy,time]"
;                       a 2D count spectrogram [energy,time] summed over detector and pixel
;                       counts from disabled detectors are set to 0 
; :returns:
;   a 4d count spectrogram [energy,pixel,detector,time]
;
;-
function stx_fsw_compact_archive_buffer , stx_fsw_archive_buffer, $
  start_time=start_time, $
  total_counts = total_counts, $
  detector_mask = detector_mask, $
  time_axis = time_axis, $
  time_edges = time_edges, $
  disabled_detectors_pixel_counts = disabled_detectors_pixel_counts, $
  disabled_detectors_total_counts = disabled_detectors_total_counts, $
  add_timebin_dummy=add_timebin_dummy
  
  default, add_timebin_dummy, 1
  default, detector_mask, make_array(32,value=1b, /BYTE)
  default, n_e, 32 ;energy
  default, n_d, 32 ;detectors 
  default, n_p, 12 ;pixel
  
  time_axis = stx_fsw_get_timex_axis_from_archive_buffer(stx_fsw_archive_buffer, start_time=start_time, time_edges_out=time_edges, add_timebin_dummy=add_timebin_dummy)
  
  n_t = n_elements(time_axis.duration)

  pixel_counts = ulonarr(n_e,n_p,n_d,n_t)


  t_idx = value_locate(time_edges, stx_fsw_archive_buffer.RELATIVE_TIME_RANGE[0,*])

  ;todo: detector_index-1?
  for i=ulong64(0), N_ELEMENTS(stx_fsw_archive_buffer)-1 do begin
    pixel_counts[stx_fsw_archive_buffer[i].energy_science_channel, $
    stx_fsw_archive_buffer[i].PIXEL_INDEX, $
    stx_fsw_archive_buffer[i].DETECTOR_INDEX-1, $
    t_idx[i]] += stx_fsw_archive_buffer[i].COUNTS
  endfor
    
  
  
  if ARG_PRESENT(total_counts) then begin
    total_counts = total(total(pixel_counts,2,/integer),2,/integer)
  endif
  
  if ARG_PRESENT(disabled_detectors_pixel_counts) || ARG_PRESENT(disabled_detectors_total_counts) then begin

    ;set all count values for not included detectors to 0
    disabled_detectors_pixel_counts = pixel_counts
    void = stx_mask2bits(~detector_mask, script = disabled_detector_scripts)
    disabled_detectors_pixel_counts[*,*,disabled_detector_scripts,*] = 0
  endif
  
  if ARG_PRESENT(disabled_detectors_total_counts) then begin
    disabled_detectors_total_counts = total(total(disabled_detectors_pixel_counts,2,/integer),2,/integer)
  endif
  
  return, pixel_counts
  
end