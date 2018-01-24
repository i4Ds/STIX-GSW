;+
; :file_comments:
;    This function is part of the FLIGHT SOFTWARE (FSW) package and
;    will crop a given archive buffer according a start and end time
;
; :categories:
;    flight software
;
; :examples:
;       croped = stx_fsw_crop_archive_buffer(archive_buffer, ab_start_time, flare_start_time, flare_end_time)
; :history:
;    03-Mai-2015 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :description:
;    This internal routine crops a given archive buffer according to a start and end time
;    the start and end time are not strict that means the result time interval might be enlarged 
;    
; :params:
; 
;    archive_buffer :   in, required, type="stx_archive_buffer"
;                       an array of archive buffer entries
;
;    ab_start_time :    in, required, type="stx_time", default=stx_time()
;                       the total time reference for the relative timing
;
;    flare_start_time : in, required, type="stx_time", default=stx_time()
;                       where to start the crop
;
;    flare_end_time :   in, required, type="stx_time", default=stx_time()+maximum time enty
;                       where to end the crop
;
;
; :returns:
;   a croped copy of the given archive buffer
;
;-

;+
  ; :DESCRIPTION:
  ;    Describe the procedure.
  ;
  ; :PARAMS:
  ;    archive_buffer
  ;    ab_start_time
  ;    flare_start_time
  ;    flare_end_time
  ;
  ;
  ;
  ; :AUTHOR: nicky
  ;-
function stx_fsw_crop_archive_buffer, archive_buffer, ab_start_time, flare_start_time, flare_end_time
  
  default, ab_start_time, stx_time()
  default, flare_start_time, ab_start_time
  default, flare_end_time, archive_buffer.time_axis.TIME_END[-1]
  
  rel_start_time = stx_time_diff(flare_start_time,ab_start_time)
  rel_end_time = stx_time_diff(flare_end_time,ab_start_time)
  
  ;crop the archive buffer to the single event
  flare_ab_idx = where(( archive_buffer.archive_buffer.relative_time_range[0,*] ge rel_start_time OR archive_buffer.archive_buffer.relative_time_range[1,*] gt rel_start_time) $ 
    AND (archive_buffer.archive_buffer.relative_time_range[1,*] lt rel_end_time OR archive_buffer.archive_buffer.relative_time_range[0,*] lt rel_end_time), count_ab)
  
  flare_ab =  count_ab gt 0 ? archive_buffer.archive_buffer[flare_ab_idx] : []
  
  return, flare_ab

end


;times.flare_times[flare_idx,1],*self.start_time
;
;where((iv.time_start ge time_span[0] OR iv.time_end ge time_span[0]) $
;  AND (iv.time_end le time_span[1] OR iv.time_start le time_span[1])