pro auto_scale_sas_data, data, simu_data_file, aperfile, n_iter=n_iter, do_plot=do_plot
  default, n_iter, 1
  
  ; Make sure that input data is a structure
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  ; Test data has been calibrated
  if not data._calibrated then begin
    print,"WARNING: input data not calibrated at all - are you sure?"
    stop
  endif

  ; Compute first solution on a 4x smoothed version of the data
  smo_data = data
  for i=0,1 do smooth_data, smo_data
  derive_aspect_solution, smo_data, simu_data_file, interpol_r=0, interpol_xy=0
  
  ; Compute mean correction factor needed to match simulated with observed signals
  xx = smo_data.z_srf / 0.375e6  ; convert back from arcsec to mic
  yy = smo_data.y_srf / 0.375e6
  simu_data = compute_sas_signals(xx, yy, smo_data.UTC, aperfile, /quiet)
  if keyword_set(do_plot) then plot4sig, smo_data, exp=simu_data
  corr = fltarr(4)
  for arm=0,3 do corr[arm] = median(simu_data.signal[arm,*] / smo_data.signal[arm,*])
  print,mean(corr),sigma(corr), format='("  Calibration correction factor (1):   ",F5.3," [+/- ",F5.3,"]")'
  cumul_corr = mean(corr)
  
  for i=1, n_iter do begin
    smo_data.signal *= mean(corr)
    derive_aspect_solution, smo_data, simu_data_file, interpol_r=0, interpol_xy=0
    xx = smo_data.z_srf / 0.375e6  ; convert back from arcsec to mic
    yy = smo_data.y_srf / 0.375e6
    simu_data = compute_sas_signals(xx, yy, smo_data.UTC, aperfile, /quiet)
    if keyword_set(do_plot) then plot4sig, smo_data, exp=simu_data
    for arm=0,3 do corr[arm] = median(simu_data.signal[arm,*] / smo_data.signal[arm,*])
    cumul_corr *= mean(corr)
    print,i+1,mean(corr),sigma(corr), cumul_corr, format='("  Calibration correction factor (",I1,"): * ",F5.3," [+/- ",F5.3,"] = ",F5.3)'
  endfor

  data.signal *= cumul_corr
  derive_aspect_solution, data, simu_data_file, interpol_r=0, interpol_xy=0
  xx = data.z_srf / 0.375e6
  yy = data.y_srf / 0.375e6
  simu_data = compute_sas_signals(xx, yy, data.UTC, aperfile, /quiet)
  if keyword_set(do_plot) then plot4sig, data, exp=simu_data
  for arm=0,3 do corr[arm] = median(simu_data.signal[arm,*] / data.signal[arm,*])
  print,i+1,mean(corr),sigma(corr),  cumul_corr * mean(corr), format='("  Calibration correction factor (",I1,"): * ",F5.3," [+/- ",F5.3,"] = ",F5.3)'
  data.signal *= mean(corr)

  ; Store the calibration factor in the Primary header
  primary = data.primary
  prev_factor = sxpar(primary,'SAS_CALI')
  sxaddpar, primary, 'SAS_CALI', cumul_corr * mean(corr) * prev_factor
  data.primary = primary

end
