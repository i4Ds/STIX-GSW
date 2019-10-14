;+
; :description:
;    This function converts calibration data in telemetry format to an array of [1024, 12, 32 ] 
;     ([ad_channels, pixels, detectors])
;
; :categories:
;    fsw, calibration
;
; :params:
;   
;
;
; :keywords:
;
;
; :returns:
;
;
; :examples:
; 
;  calibration_spectrum = stx_calibration_data_array(tmtc_calibration_spectra, pixel_mask = pixel_mask , detector_mask = detector_mask )
;
; :history:
; 
;       03-Dec-2018 – ECMD (Graz), initial release
;
;-
function stx_calibration_data_array, calibration_data, pixel_mask =pixel_mask , detector_mask =detector_mask

  if typename(calibration_data) eq 'LIST' then calibration_data = calibration_data.toarray()

  subspectra = calibration_data.subspectra

  default, pixel_mask, subspectra[0].pixel_mask
  default, detector_mask, subspectra[0].detector_mask


  n_spectra = subspectra.count()

  calibration_spectrum = dblarr(1024, 12, 32)
  for i = 0,n_spectra-1 do begin

    ; Get the current subspectrum
    current_subspectrum = subspectra[i].spectrum

    e_start = subspectra[i].lower_energy_bound_channel ge 0 ?  subspectra[i].lower_energy_bound_channel : subspectra[i].lower_energy_bound_channel+1024
    e_range = subspectra[i].number_of_summed_channels
    e_n = subspectra[i].number_of_spectral_points

    for e = 0, e_n-1 do begin
      e_bins = indgen(e_range)+e_start+(e*e_range)
      for p = 0, size(pixel_mask, /n_elements)-1 do begin
        if pixel_mask[p] eq 1 then begin
          for d = 0, size(detector_mask, /n_elements)-1 do begin
            if detector_mask[d] eq 1 then begin
              calibration_spectrum[e_bins, p, d] += current_subspectrum[e,p,d] / (1.0d* e_range)
            endif
          endfor
        endif
      endfor
    endfor

  endfor

  return, calibration_spectrum

end