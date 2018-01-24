;+
; :file_comments:
;    This function is part of the FLIGHT SOFTWARE (FSW) package and
;    will crop a given rcr signal according a start and end time
;
; :categories:
;    flight software
;
; :examples:
;       croped = stx_fsw_crop_rcr(rcr, start_time, end_time)
; :history:
;    15-Jul-2015 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :description:
;    This internal routine crops a given rcr sequence according to a start and end time 
;    
; :params:
; 
;    rcr :              in, required, type="stx_fsw_result_rate_control"
;                       this is a rate controle data sequence with attached time axis
;                       
;    start_time :       in, required, type="stx_time", default=start of the rcr data sequence
;                       the start time to crop 
;
;    end_time :         in, required, type="stx_time", default=end of the rcr data sequence
;                       the end time to crop
;
;
; :returns:
;   a croped copy of the given rcr sequence
;   data and time axis are croped
;
;-

function stx_fsw_crop_rcr, rcr, start_time, end_time
  
  ppl_require, in=rcr, type='stx_fsw_m_rate_control_regime' 
  default, start_time, rcr.time_axis.time_start[0]
  default, end_time, rcr.time_axis.time_end[-1]
  
  ppl_require, in=start_time, type='stx_time'
  ppl_require, in=end_time, type='stx_time'
  
  
  rcr_flare_idx = where(stx_time_ge(rcr.time_axis.Time_Start, start_time) AND stx_time_le(rcr.time_axis.Time_End, end_time), rcr_flare_count)
  
  assert_true, rcr_flare_count gt 0
  
  ;create a copy
  rcr_crop = rcr
  
  ;crop the data
  rcr_crop = ppl_replace_tag(rcr_crop, "rcr", rcr_crop.rcr[rcr_flare_idx])
  rcr_crop = ppl_replace_tag(rcr_crop, "skip_rcr", rcr_crop.skip_rcr[rcr_flare_idx])
  rcr_crop = ppl_replace_tag(rcr_crop, "time_axis", stx_construct_time_axis(time_axis=rcr_crop.time_axis, idx=rcr_flare_idx))
  
  return, rcr_crop
  
end


;rcr_flare = single_event $
;  ? where(stx_time_ge(rcr_data.time_axis.Time_Start, start_time) AND stx_time_le(rcr_data.time_axis.Time_Start, end_time), rcr_flare_count) $
;  : where(stx_time_ge(rcr_data.time_axis.Time_Start, start_time) AND stx_time_lt(rcr_data.time_axis.Time_Start, end_time), rcr_flare_count)
;
;assert_true, rcr_flare_count gt 0