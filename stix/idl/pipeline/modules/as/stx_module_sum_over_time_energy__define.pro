;---------------------------------------------------------------------------
; Document name: stx_module_sum_over_time_energy__define.pro
; Created by:    nicky.hochmuth 02.05.2013
;---------------------------------------------------------------------------
;+
; PROJECT:          STIX
;
; NAME:             stx_module_sum_over_time_energy Object
;
; PURPOSE:          Wrapping the time energy rebinning for the pipeline
;
; CATEGORY:         STIX PIPELINE
;
; CALLING SEQUENCE: modul = stx_module_sum_over_time_energy()
;                   modul->execute(in, out, history, configuration=configuration)
;
; HISTORY:
;       05.02.2013 nicky.hochmuth initial (empty) release
;-


function stx_module_sum_over_time_energy::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin
         
    return, 1
  end
  return, ret
end


function stx_module_sum_over_time_energy::_execute, in, configuration
  compile_opt hidden
  
  iv = in.intervals
       
  n_pd = n_elements(in.intervals)     
  pixel_data = replicate(stx_pixel_data(),n_pd) 
  pixel_data.time_range[0] = in.intervals.start_time
  pixel_data.time_range[1] = in.intervals.end_time
  pixel_data.energy_range[0] = in.intervals.start_energy
  pixel_data.energy_range[1] = in.intervals.end_energy
  
  col = stx_time_energy_bin_collection(in.raw_pixel_data)
  
  
  
  for i=0L, n_pd-1 do begin
     ;print, pixel_data[i].energy_range
     to_merge_idx = col->select(time=pixel_data[i].time_range ,energy=pixel_data[i].energy_range , count_matches=count_matches, /idx, /strict)
     if count_matches gt 0 then begin
       
       pixel_data[i].counts = count_matches eq 1 ? in.raw_pixel_data[to_merge_idx].counts : total(in.raw_pixel_data[to_merge_idx].counts,3)
       
       ;col->remove, to_merge_idx
     end 
  endfor
  
  ;eval = [[pixel_data.energy_range],transpose(stx_time_diff(pixel_data.time_range[0,*],replicate((pixel_data.time_range[0])[0],n_pd))),transpose(iv.start_energy),transpose(iv.end_energy),transpose(stx_time_diff(iv.start_time,replicate(iv[0].start_time,n_pd))),transpose(iv.counts),transpose(total(total(pixel_data.counts,1),1))]
  ;print, eval
  ;print, eval[6,*] eq eval[7,*]
  
  destroy, col
  return, pixel_data
  
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
function stx_module_sum_over_time_energy::_verify_input, in
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
function stx_module_sum_over_time_energy::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_sum_over_time_energy::cleanup
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
pro stx_module_sum_over_time_energy__define
  compile_opt idl2, hidden
  
  void = { stx_module_sum_over_time_energy, $
           inherits ppl_module }
end
