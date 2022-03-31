;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_spectrogram_livetime
;
; :description:
; 
;    This function calulates the fractional livetime using the counted triggers from the input stx_fsw_sd_spectrogram. The counts and count errors corrected for 
;    this livetime can also be returned. 
;
; :categories:
;    spectroscopy
;
; :params:
;    spectrogram : in, required, type="stx_fsw_sd_spectrogram structure"
;            The spectrogram of data to correct for livetime containing the counted triggers for each time bin.
;
; :keywords:
; 
;    corrected_counts : out, type="float"
;               An array of counts corrected for livetime
;               
;    corrected_error : out, type="float"
;               An array of count errors corrected for livetime
;
;    level : in, type="int"
;    the data compation level currently level 1 (Compressed pixel data) and level 4 (spectrogram data) are supported
;
;
; :returns:
;    livetime_fraction : the live time freaction for each time bin  
;
;
; :history:
;    24-Feb-2021 - ECMD (Graz), initial release
;    22-Feb-2022 - ECMD (Graz), documented, added livetime error estimation 
;
;-
function stx_spectrogram_livetime,  spectrogram, corrected_counts =corrected_counts, corrected_error= corrected_error, level = level
  ;convert the triggers to livetime

default, level, 1

  ntimes = n_elements(spectrogram.time_axis.time_start)
  nenergies = (spectrogram.counts.dim)[0]
  det_used = where(spectrogram.detector_mask eq 1, ndet) + 1 ; stx_livetime_fraction expects detector number in the range 1 - 32 


  case level of
    1: begin
      dim_counts = [nenergies, ndet, ntimes]
      triggergram = stx_triggergram(transpose( spectrogram.trigger ),  spectrogram.time_axis)
      livetime_fraction = stx_livetime_fraction(triggergram, det_used)
      livetime_fraction = transpose( rebin(reform(livetime_fraction, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])

      triggergram_lower = stx_triggergram(transpose( spectrogram.trigger - spectrogram.trigger_err > 0),  spectrogram.time_axis)
      livetime_fraction_lower = stx_livetime_fraction(triggergram_lower, det_used)
      livetime_fraction_lower = transpose( rebin(reform(livetime_fraction_lower, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])
     
      triggergram_upper = stx_triggergram(transpose( spectrogram.trigger + spectrogram.trigger_err),  spectrogram.time_axis)
      livetime_fraction_upper = stx_livetime_fraction(triggergram_upper, det_used)
      livetime_fraction_upper = transpose( rebin(reform(livetime_fraction_upper, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])
      

    end
    4:begin
      dim_counts = [nenergies, ntimes]
      trig =  (fltarr(16)+1./16.)##transpose(spectrogram.trigger)
      triggergram = stx_triggergram(transpose(trig),  spectrogram.time_axis)
      livetime_fraction = stx_livetime_fraction(triggergram, det_used)
      livetime_fraction = transpose( rebin(reform(livetime_fraction[0,*]),[dim_counts[1],dim_counts[0]]))
      
      trig_lower  =  (fltarr(16)+1./16.)##transpose(spectrogram.trigger - spectrogram.trigger_err > 0)
      triggergram_lower = stx_triggergram(transpose(trig_lower),  spectrogram.time_axis)
      livetime_fraction_lower = stx_livetime_fraction(triggergram_lower, det_used)
      livetime_fraction_lower = transpose( rebin(reform(livetime_fraction_lower[0,*]),[dim_counts[1],dim_counts[0]]))

      trig_upper  =  (fltarr(16)+1./16.)##transpose(spectrogram.trigger + spectrogram.trigger_err)
      triggergram_upper = stx_triggergram(transpose(trig_upper),  spectrogram.time_axis)
      livetime_fraction_upper = stx_livetime_fraction(triggergram_upper, det_used)
      livetime_fraction_upper = transpose( rebin(reform(livetime_fraction_upper[0,*]),[dim_counts[1],dim_counts[0]]))


    end

    else: message, 'Currently supported compaction levels are 1 (pixel data) and 4 (spectrogram)'
  endcase

  corrected_counts =  spectrogram.counts/livetime_fraction
  
  corrected_counts_upper =  spectrogram.counts/livetime_fraction_upper
  corrected_counts_lower =  spectrogram.counts/livetime_fraction_lower
  error_from_livetime = (corrected_counts_upper - corrected_counts_lower)/2.

  corrected_error = sqrt( (spectrogram.error/livetime_fraction)^2. + error_from_livetime^2.)
 
  return, livetime_fraction

end