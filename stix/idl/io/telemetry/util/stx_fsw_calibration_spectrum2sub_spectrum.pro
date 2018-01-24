function stx_fsw_calibration_spectrum2sub_spectrum, calibration_spectrum, li=li, wi=wi, ni=ni, pixel_mask=pixel_mask, detector_mask=detector_mask, _extra=extra
  default, calibration_spectrum, stx_sim_calibration_spectrum()
  default, li, 0
  default, wi, 4
  default, ni, 256
  default, pixel_mask, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
  default, detector_mask, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

  ; get total of calibration spectrum energy channels
  n_all_energy_channels = ((size(calibration_spectrum.accumulated_counts, /dimensions))[0])

  ; sanity checks
  if(li + wi * ni gt n_all_energy_channels) then message, "Parameter 'Li', 'Wi', and/or 'Ni' are/is incorrect."

  ; extract selected pixels and detectors
  selected_pxls = where(pixel_mask eq 1, n_selected_pxls)
  selected_dets = where(detector_mask eq 1, n_selected_dets)

  all_energy_channels = lindgen(n_all_energy_channels) + li

  ; calculating the total number of selected (i.e. included) data points in this subspectrum
  n_total_selected_idx = n_all_energy_channels * n_selected_pxls * n_selected_dets

  ; preparing rebin sizes
  rebin_det_len = n_total_selected_idx/n_selected_dets
  rebin_ch_len = n_all_energy_channels * n_selected_dets
  rebin_pxl_len = rebin_ch_len * n_selected_pxls

  ; generating an index array to address all the selected data points in the calibration spectrum
  total_selected_idx = reform(rebin(selected_dets, n_selected_dets, rebin_det_len), n_total_selected_idx) + $
    n_selected_dets * reform(rebin(rebin(all_energy_channels, rebin_ch_len), rebin_ch_len, n_total_selected_idx/rebin_ch_len), n_total_selected_idx) + $
    rebin_ch_len * reform(rebin(rebin(selected_pxls, rebin_pxl_len), rebin_pxl_len, n_total_selected_idx/rebin_pxl_len), n_total_selected_idx)

  ; sort indeces
  total_selected_idx = total_selected_idx[bsort(total_selected_idx)]

  ; extract the "reduced" spectrum (only selected energies, pixels and detectors)
  reduced_spectrum = reform(calibration_spectrum.accumulated_counts[total_selected_idx], n_all_energy_channels, n_selected_pxls, n_selected_dets)

  ; generate the subspectrum
  sub_spectrum = lonarr(ni, n_selected_pxls, n_selected_dets)
  for eidx = 0L, ni-1 do begin
    ; loop over every channel group and total the counts for all selected pixels and detectors
    sub_spectrum[eidx, *, *] = total(reduced_spectrum[li + wi * eidx : li + wi * (eidx + 1) -1, *, *], 1)
  endfor
  
  return, sub_spectrum
end