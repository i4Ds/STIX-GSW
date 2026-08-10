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
;    23-Mar-2026 - Massa P. (FHNW), made it compatible with live time uncertainty propagation
;    07-May-2026 - Massa P. (FHNW), fixed bug. In the previous version, counts were normalized by livetime fraction instead of livetime.
;                                   Now, both the livetime and the livetime fraction (and corresponding uncertainties) are returned 
;-
function stx_spectrogram_livetime,  spectrogram, corrected_counts =corrected_counts, corrected_error= corrected_error, level = level
  ;convert the triggers to livetime

default, level, 1

  ntimes = n_elements(spectrogram.time_axis.time_start)
  nenergies = (spectrogram.counts.dim)[0]
  det_used = where(spectrogram.detector_mask eq 1, ndet) + 1 ; stx_livetime_fraction expects detector number in the range 1 - 32 

  time_bin_duration = transpose(cmreplicate(spectrogram.time_axis.duration, nenergies))
  
  case level of
    1: begin
      dim_counts = [nenergies, ndet, ntimes]
      triggergram = stx_triggergram(transpose( spectrogram.trigger ), transpose( spectrogram.trigger_err ),  spectrogram.time_axis)
      livetime_fraction_data = stx_livetime_fraction(triggergram, det_used)
      livetime_fraction = transpose( rebin(reform(livetime_fraction_data.livetime_fraction, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])
      livetime_fraction_err = transpose( rebin(reform(livetime_fraction_data.livetime_fraction_err, ndet, ntimes),[dim_counts[1:2],dim_counts[0]]),[2,0,1])

    end
    4:begin
      dim_counts = [nenergies, ntimes]
      trig =  (fltarr(16)+1./16.)##transpose(spectrogram.trigger)
      trig_err = (fltarr(16)+1./16.)##transpose(spectrogram.trigger_err)
      triggergram = stx_triggergram(transpose(trig), transpose(trig_err), spectrogram.time_axis)
      livetime_fraction_data = stx_livetime_fraction(triggergram, det_used)
      livetime_fraction = transpose( rebin(reform(livetime_fraction_data.livetime_fraction[0,*]),[dim_counts[1],dim_counts[0]]))
      livetime_fraction_err = transpose( rebin(reform(livetime_fraction_data.livetime_fraction_err[0,*]),[dim_counts[1],dim_counts[0]]))

    end

    else: message, 'Currently supported compaction levels are 1 (pixel data) and 4 (spectrogram)'
  endcase
  
  livetime = time_bin_duration * livetime_fraction
  livetime_err = time_bin_duration * livetime_fraction_err

  corrected_counts =  f_div(spectrogram.counts,livetime)

  corrected_error = abs(corrected_counts) * sqrt( f_div(spectrogram.error,spectrogram.counts)^2. + $
    f_div(livetime_err,livetime)^2. )
 
  return, {livetime: livetime, $
          livetime_err: livetime_err, $
          livetime_fraction:livetime_fraction, $
          livetime_fraction_err: livetime_fraction_err}

end