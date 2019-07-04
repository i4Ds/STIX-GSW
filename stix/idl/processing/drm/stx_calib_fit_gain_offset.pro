;+
; :Description:
;    This function obtains the gain and offset for the fit to the calibration
;    spectra based on the adc (1024 version) and the line energies in the fit.
;    This works on all 384 spectra and line pairs in a single call. The fitted energy
;    values of the lines at 30.85 and 81 keV are converted to ADC using the calibraion values
;    used when fitting the spectra. Thoe ADC are then converted to gain, keV/ADC1024. Then using the
;    gain, the location of 0 keV, the offset, is obtained from the ADC1024 of E31 and 30.85 keV.
; :Examples:
;     h=stx_calib_read_tvac()
;     r= stx_calib_fit_extract_params()
;    gain_offset_computed = stx_calib_fit_gain_offset( h.gain, h.offset, r.e31, r.e81)
;
; :Params:
;    current_gain - gain used in ospex fitting, keV/adc1024, fltarr(384) 
;    current_offset - ADC1024 offset, where ADC1024 is 0.0 keV, used in ospex fitting, fltarr(384) 
;    e31 - 30.85 keV fitted value in keV  fltarr(384) 
;    e81 - 81 keV fitted value in keV  fltarr(384) 
;
;
;
; :Author: rschwartz70@gmail.com, 2-jul-2019
;-
function stx_calib_fit_gain_offset, current_gain, current_offset, e31, e81

  ;compute 1024 ADC bin for e31 and e81
  ;e31 is at 30.85 keV and e81 is at 81 keV
  shape = size( /dim, current_gain )
  n31 = e31[*]/current_gain[*] + current_offset[*]
  n81 = e81[*]/current_gain[*] + current_offset[*]
  gain = (81.-30.85)/(n81-n31)
  offset = n31 - 30.85/gain
  gain_offset_computed = replicate( {gain: 0.0, offset: 0.0}, 384)
  gain_offset_computed.gain = gain
  gain_offset_computed.offset = offset
  return, reform( gain_offset_computed, shape )
end