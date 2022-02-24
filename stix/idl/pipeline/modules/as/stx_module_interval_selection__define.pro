;---------------------------------------------------------------------------
; Document name: stx_module_interval_selection__define.pro
; Created by:    nicky.hochmuth 02.05.2013
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_interval_selection Object
;
; PURPOSE:          Wrapping the interval selection for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_interval_selection()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       05.02.2013 nicky.hochmuth initial (empty) release
;       17.06.2015 ECMD (Graz), now consistent with new ordering of the spectrogram 
;                  with energy being the first dimension and time being the last.
;-


function stx_module_interval_selection::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin    
    return, 1
  end
  return, ret
end


function stx_module_interval_selection::_execute, raw_pixel, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  ;get the default eneryg axes
  energy_axis = stx_construct_energy_axis();
  
  ;create time axes
  time_edges = stx_time2any(raw_pixel.time_range)
  time_edges = reform(time_edges,n_elements(time_edges))
  time_edges = time_edges[uniq(time_edges,sort(time_edges))]
    
  time_axis = stx_construct_time_axis(time_edges)
 
  n_e = n_elements(energy_axis.high)
  n_t = n_elements(time_axis.duration)
  
  attenuator_state = bytarr(n_t)
  
  counts = ulon64arr(n_e,n_t)
  
  ;accumulate all pixel data into the count matrix
  for i=0L, n_elements(raw_pixel)-1  do begin
    
    t_idx = where(stx_time_eq(time_axis.time_start,raw_pixel[i].time_range[0]) AND stx_time_eq(time_axis.time_end,raw_pixel[i].time_range[1]), valid_t) 
    e_idx = where(energy_axis.low eq raw_pixel[i].energy_range[0] AND energy_axis.high eq raw_pixel[i].energy_range[1], valid_e)
    
    if valid_e eq 1 && valid_t eq 1 then begin
      counts[e_idx,t_idx] += total(raw_pixel[i].counts,/preserve_type)
      attenuator_state[t_idx] = raw_pixel[i].rcr
    endif else begin
      ;stop
    endelse
    
    
  end
  
  ;TODO handel livetime properly
  ltime = fltarr(n_e,n_t)
  
  spectrogram = stx_spectrogram(counts, time_axis, energy_axis, ltime, attenuator_state=attenuator_state)
    
  return, stx_ivs(spectrogram, plotting=conf.plotting);
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_interval_selection::_verify_input, in
  compile_opt hidden
  
  if ~self->ppl_module::_verify_input(in) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    This internal routine verifies the validity of the configuration
;    parameter
;
; :params:
;    configuration is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'configuration' is valid, false otherwise
;-
function stx_module_interval_selection::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_interval_selection::cleanup
  self->ppl_module::cleanup
end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_module_interval_selection__define
  compile_opt idl2, hidden
  
  void = { stx_module_interval_selection, $
           inherits ppl_module }
end
