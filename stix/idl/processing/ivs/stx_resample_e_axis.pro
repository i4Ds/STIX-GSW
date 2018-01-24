;---------------------------------------------------------------------------
; Document name: stx_resample_e_axis.pro
; Created by:    Nicky Hochmuth, 2012/02/03
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; PURPOSE:
;       resamples the energy axis of a given spectrogram 
;
; CATEGORY:
;       STIX axis definitions
;
; CALLING SEQUENCE:
;       new_spectrogram = stx_resample_e_axis(spectrogram, new_e_axis)
;
; HISTORY:
;       2012/02/28, nicky.hochmuth@fhnw.ch, initial release
;
;-

;+
; :description:
;       resamples the energy axis of a given spectrogram by merging several adjacent energy bins
;       no interpolation is applyed the new e_axis should by congruent to the old one and must have less energy bins
;
; :params:
;   spectrogram: the spextrogram to resample 
;   new_e_axis: the new e axis definition
;-
function stx_resample_e_axis, spectrogram, new_e_axis
 
  ; Do some parameter checking
  ppl_require, in=spectrogram, type='stx_spectrogram'
  ppl_require, in=new_e_axis, type='stx_energy_axis'
  
  
  spg_data = make_array(n_elements(new_e_axis.mean),n_elements(spectrogram.t_axis.time_start),/DOUBLE)
  
  for e=0, n_elements(new_e_axis.mean)-1 do begin
    ;e_start = where(spectrogram.e_axis.low eq new_e_axis.low[e] ,error_test_start)
    ;e_end = where(spectrogram.e_axis.high[*] eq new_e_axis.high[e] ,error_test_end)
    ;if (~ (error_test_start or error_test_end) eq 1)  then message, "Parameter 'new_e_axis' must be a congruent energy_axis according to the old one"
     
    e_start = new_e_axis.LOW_FSW_IDX[e]
    e_end   = new_e_axis.HIGH_FSW_IDX[e]
    if e_start lt e_end then spg_data[e,*]=total(spectrogram.data[e_start:e_end,*], 1) $
    else  spg_data[e, *]=spectrogram.data[e_start, *]
    
  end
  
  
  ;could be skiped later on  
  ltime = spg_data
  ltime[*]=1
  
   if ~ total(spg_data) eq total(spectrogram.data) then message, "Merging has encountered a problem the final total counts differs ..."
  
  return, stx_spectrogram(spg_data, spectrogram.t_axis, new_e_axis,ltime , attenuator_state=spectrogram.attenuator_state)
 
end