function median_factor_simu_obs, simu_data, obs_data
  corr = fltarr(4)
  corr[0] = median(simu_data[0,*] / obs_data.cha_diode0)
  corr[1] = median(simu_data[1,*] / obs_data.cha_diode1)
  corr[2] = median(simu_data[2,*] / obs_data.chb_diode0)
  corr[3] = median(simu_data[3,*] / obs_data.chb_diode1)
  return, corr
end


pro auto_scale_sas_data, data, simu_data_file, aperfile, n_iter=n_iter, do_plot=do_plot
  default, n_iter, 1
  
  ; Make sure that input data is a structure
  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif

  ; Test data has been calibrated
  _calibrated = data[0].calib
  if not _calibrated then begin
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
  foclen = 0.55         ; SAS focal length, in [m]
  rsol = foclen * (smo_data.SPICE_DISC_SIZE * !pi/180. / 3600.)
  simu_data = compute_sas_signals(xx, yy, rsol, aperfile, /quiet)
;  if keyword_set(do_plot) then plot4sig, smo_data, exp=simu_data
  corr = median_factor_simu_obs(simu_data, smo_data)
  print,mean(corr),sigma(corr), format='("  Calibration correction factor (1):   ",F5.3," [+/- ",F5.3,"]")'
  cumul_corr = mean(corr)
  
  for i=1, n_iter do begin
    smo_data.CHA_DIODE0 *= mean(corr)
    smo_data.CHA_DIODE1 *= mean(corr)
    smo_data.CHB_DIODE0 *= mean(corr)
    smo_data.CHB_DIODE1 *= mean(corr)
    derive_aspect_solution, smo_data, simu_data_file, interpol_r=0, interpol_xy=0
    xx = smo_data.z_srf / 0.375e6  ; convert back from arcsec to mic
    yy = smo_data.y_srf / 0.375e6
    simu_data = compute_sas_signals(xx, yy, rsol, aperfile, /quiet)
;    if keyword_set(do_plot) then plot4sig, smo_data, exp=simu_data
    corr = median_factor_simu_obs(simu_data, smo_data)
    cumul_corr *= mean(corr)
    print,i+1,mean(corr),sigma(corr), cumul_corr, format='("  Calibration correction factor (",I1,"): * ",F5.3," [+/- ",F5.3,"] = ",F5.3)'
  endfor

  ; One more iteration at full time resolution
  data.CHA_DIODE0 *= cumul_corr
  data.CHA_DIODE1 *= cumul_corr
  data.CHB_DIODE0 *= cumul_corr
  data.CHB_DIODE1 *= cumul_corr
  derive_aspect_solution, data, simu_data_file, interpol_r=0, interpol_xy=0
  xx = data.z_srf / 0.375e6
  yy = data.y_srf / 0.375e6
  rsol = foclen * (data.SPICE_DISC_SIZE * !pi/180. / 3600.)
  simu_data = compute_sas_signals(xx, yy, rsol, aperfile, /quiet)
;  if keyword_set(do_plot) then plot4sig, data, exp=simu_data
  corr = median_factor_simu_obs(simu_data, data)
  print,i+1,mean(corr),sigma(corr),  cumul_corr * mean(corr), format='("  Calibration correction factor (",I1,"): * ",F5.3," [+/- ",F5.3,"] = ",F5.3)'

  ; Update signal arrays and value of CALIB in input data structure
  data.CHA_DIODE0 *= mean(corr)
  data.CHA_DIODE1 *= mean(corr)
  data.CHB_DIODE0 *= mean(corr)
  data.CHB_DIODE1 *= mean(corr)
  data.CALIB *= cumul_corr * mean(corr)
end
