;+
; :FILE_COMMENTS:
;    This module is part of the FLIGHT SOFTWARE (FSW) package and
;    will compact the quicklook spectra into telemetrie data (not format) 
;
; :CATEGORIES:
;    flight software, data compaction
;
; :EXAMPLES:
;       fs = stx_fsw_module_reduce_ql_spectra()
; :HISTORY:
;    06-Oct-2016 - Nicky Hochmuth (FHNW), initial release
;    06-Mar-2017 - Laszlo I. Etesi (FHNW), added second spectra data formatting scheme

;-

;+
; :DESCRIPTION:
;    This internal routine transformes the full set of quicklook spectra into a subset for telemetry
;   
; :PARAMS:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_source_structure object
;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :RETURNS:
;   this function returns a "stx_fsw_m_ql_spectra" structure with a set of samples 
;
;-
function stx_fsw_module_reduce_ql_spectra::_execute, in, configuration
  compile_opt hidden

  conf = *configuration->get(module=self.module)
  
  duration = in.spectra.time_axis.duration[0]
  
 
  
  ;if the last entry has not a duration of 32 seconds throw it away
  max_t = n_elements(in.spectra.time_axis.duration)
  if in.spectra.time_axis.duration[-1] ne in.spectra.time_axis.duration[0] then max_t-- 
  
  case (conf.schema) of
    0b: begin
      samples = replicate({$
        detector_index : 0b, $
        counts : ulonarr(32), $
        trigger : ulong(0), $
        delta_time : fix(0) $
      }, max_t)
      
      detectors = where(conf.detector_mask eq 1b, count_detectors)
      if count_detectors eq 0 then break
      
      for t=0L, max_t-1 do begin
        det = detectors[t mod count_detectors]
        samples[t].detector_index = det
        samples[t].counts = in.spectra.ACCUMULATED_COUNTS[*,det,t]
        samples[t].trigger = in.spectra_lt.ACCUMULATED_COUNTS[det,t]
        samples[t].delta_time = duration
        
        
      endfor 
      break         
    end
    1b: begin
      detectors = where(conf.detector_mask eq 1b, count_detectors)
      if count_detectors eq 0 then break
      
      samples = replicate({$
        detector_index : 0b, $
        counts : ulonarr(32), $
        trigger : ulong(0), $
        delta_time : fix(0) $
      }, max_t * count_detectors)
      
      for t=0L, max_t-1 do begin
        for d=0L, count_detectors-1 do begin
          det = detectors[d]
          samples[t*count_detectors+d].detector_index = det
          samples[t*count_detectors+d].counts = in.spectra.accumulated_counts[*,det,t]
          samples[t*count_detectors+d].trigger = in.spectra_lt.accumulated_counts[stx_ltpair_assignment(det+1)-1,t]
          samples[t*count_detectors+d].delta_time =  ((t+1) * duration) - duration
        endfor
      endfor
      break
    end
  endcase
  
  
 data = {$
  type             : "stx_fsw_m_ql_spectra", $
  ;just take the first pixelmask and presume as constant for the entire block (the pixel mask can only chang by a TC)
  pixel_mask       : in.spectra.pixel_mask[0], $
  samples          : samples, $
  integration_time : duration, $
  start_time       : in.spectra.time_axis.time_start[0] $
 } 
  
 return, data

end


;+
; :DESCRIPTION:
;    Constructor
;
; :INHERITS:
;    hsp_module
;
; :HIDDEN:
;-
pro stx_fsw_module_reduce_ql_spectra__define
  compile_opt idl2, hidden

  void = { stx_fsw_module_reduce_ql_spectra, $
    inherits ppl_module }
end
