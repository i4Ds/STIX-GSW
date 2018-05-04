;+
;This is a demonstration of creating STIX calibration line spectra, compressing the data into subspectra
;Reading the subspectra, and extracting the line parameters after fitting the spectra with a background model
;plus the Barium calibration lines
; 29-nov-2017, RAS
; 3-may-2018, RAS, now it has the added demonstration of measuring the offset from two simulated daily
; calibration spectra. At the end three techniques demostrate the measurement of the new offset
; 
;-
;pro stx_det_cal_proc, dgain, doffset
  default, dgain, 0.0000 ;keV per bin
  default, doffset, 2.3 ;keV
  ;make default offset gain structure, this will be used differentially from the
  ;default offset and gain found in sp.e_axis without
  dog_str  =  stx_offsetgain()
  dog_str.gain = dgain ;nominal is 0.1 so this is 1/2 of 1 percent
  dog_str.offset = doffset
  ;Simulate the initial spectrum in the sp structure and the deviated one in dsp
  ;Uses the values of dog_str to generate the simulated deviated spectrum
  stx_bkg_sim_demo, spec=sp, dspec = dsp, ch_axis = ch_axis, doffset_gain = dog_str, $
    /noplot, poisson = 1 ;first time without MonteCarlo to get line centers
  
  ;use the crosscorrelation to find a preliminary estimate of the offset
  ;This will be used to modify the curvefit line energy initial values
  eshift = stx_cal_crosscorr( sp.data, dsp.data,  ii, cc, imax, gain = 0.4)
  
  def_gain = avg( sp.e_axis.width )
  def_off  = sp.e_axis.edges_1[0]
  
  ;Find the max flux to set the fit_comp_maxima
  ;establish the fit range prior
  mxflux = max( f_div( sp.data, sp.ltime * sp.e_axis.width ))
  fit_range = 10.^round(alog10(mxflux)) * [.001, 100]
  ;  ;The details of the drm don't matter, the fitting is done in nodrm mode

  ;Start with a baseline fit done previously to speed up the fitting process
  fit_comp_params = $
    [ 0.78379, 30.27580, 14.53129, $;continuum under 31 and 35 keV lines
    0.06922, 30.84947,  0.44213, $; 31 keV line, ilines[0]
    0.01259, 35.01090,  0.50337, $; 35 keV line, ilines[1]
    0.01721, 80.99154,  0.64765, $; 81 keV line, ilines[2]
    0.72488, 64.02208, 27.41861 ]; continuum under 81 keV line

  ;line energies
  ilines = [1,2,3]
  ;
  fit_comp_minima = [ 1e-4,  25.000,   5.000,$
    1e-4,  25,   0.30,$
    1e-4,  28.000,   0.300,$
    1e-4,  75.000,   0.300,$
    1e-4,  60.000,   5 ]
  fit_comp_maxima = [ 10, 40.000,  30.000,$
    10, 35.000,   3.000,$
    10, 38.000,   3.000,$
    10, 86.000,   2.000,$
    10, 75.000,  40.000 ]
  ;By setting the prior from mxflux for the fit_range for the max and min
  ;normalization parameter we speed up the fitting process.  Important for fitting
  ;384 calibration spectra
  fit_comp_maxima[0:*:3] = fit_range[1]
  fit_comp_minima[0:*:3] = fit_range[0]
  fit_comp_free_mask= 1b + bytarr( n_elements( fit_comp_params ) )

  set_logenv, 'OSPEX_NOINTERACTIVE', '1'
  obj = is_class( obj, 'spex') ? obj : ospex()
  obj -> set, spex_data_source = 'SPEX_USER_DATA'

  ut = anytim( sp.t_axis.time_start.value) + [0,86400.]
  obj->set, spectrum = sp.data, spex_ct_edges=sp.e_axis.edges_2, spex_ut_edges=ut, livetime=sp.ltime,errors = sqrt( sp.data)
  obj->set, spex_respinfo=1, spex_area=1, spex_detectors='stix'
  stx_cal_script, obj=obj, $
    ;spex_specfile= '.\Cal_bkg_dev.fits', spex_drmfile= '.\Cal_bkg_dev_drm.fits', $
    fit_comp_params = fit_comp_params, fit_comp_minima = fit_comp_minima, $
    fit_comp_maxima = fit_comp_maxima, fit_comp_free_mask = fit_comp_free_mask, $
    _extra = _extra, quiet = quiet
  ;extract line energies and bin locations
  fit_function = str2arr( obj->get(/fit_function), '+')
  ;if all are line_no_drm then 3 params each
  fit_params = reform( obj->get(/spex_summ_params), 3, n_elements( fit_function ) )
  fit_sigmas = reform( obj->get(/spex_summ_sigma), 3, n_elements( fit_function ) )
  cal_lines = fit_params[1,ilines]
  ;  IDL> print, fit_params, form='( 3(" ",f8.5) )'
  ;  0.78379 30.27580 14.53129
  ;  0.06922 30.84947  0.44213
  ;  0.01259 35.01090  0.50337
  ;  0.01721 80.99154  0.64765
  ;  0.72488 64.02208 27.41861
  ;Now fit the offset spectra and extract the line parameters
  fit_comp_params = $
    [ 0.78379, 30.27580, 14.53129, $;continuum under 31 and 35 keV lines
    0.06922, 30.84947,  0.44213, $; 31 keV line, ilines[0]
    0.01259, 35.01090,  0.50337, $; 35 keV line, ilines[1]
    0.01721, 80.99154,  0.64765, $; 81 keV line, ilines[2]
    0.72488, 64.02208, 27.41861 ]; continuum under 81 keV line
  fit_comp_params = fit_params[*]
  fit_comp_params[1:*:3] += eshift
  obj->set, spectrum = dsp.data, fit_comp_params = fit_comp_params
  obj->dofit, /all, /quiet
  dfit_params = reform( obj->get(/spex_summ_params), 3, n_elements( fit_function ) )
  dfit_sigmas = reform( obj->get(/spex_summ_sigma), 3, n_elements( fit_function ) )
  dcal_lines = dfit_params[1,ilines]

  ;we can use crosscorr to estimate the shift before fitting and from that adjust fitting
  ;parameters and ranges to make the fit more robust.
  ;  IDL> crosscorr, dsp.data, sp.data, cc, ii, npix
  ;  IDL> cc >= 0
  ;  % Program caused arithmetic error: Floating illegal operand
  ;  IDL> pmm, cc
  ;  0.000000     0.986900
  ;  IDL> print, max(cc, imax)
  ;  0.986900
  ;  IDL> shift = imax - npix
  ;  IDL> print, shift
  ;  -6
  ;  IDL> ;lines shift approx 6 bins lower, ~2.4 keV
  ;
  print, cal_lines, cal_lines- dcal_lines
  ;30.8445
  ;35.0113
  ;80.9807
  ;-2.41186
  ;-2.34120
  ;-2.60766
  line_ibin0 = (cal_lines - def_off)/def_gain
  line_ibin1 = (dcal_lines - def_off )/def_gain
  ;compute new cal from cal_lines and line_ibin1
  new_gain = regress( line_ibin1, transpose( cal_lines ) , const= new_offset )
  
  dbin_crosscorr =  eshift / (def_gain/4)
  dbin_linecenters = avg( ([dcal_lines[*] - cal_lines[*]])[[0,2]] ) / (def_gain/4)
  dbin_fitgain   = (def_off - new_offset) / (def_gain/4)
  print, 'From Cross-correlation: '
  print, 'Change channel value in ELUT by ',dbin_crosscorr, ' PHA bins
  print, 'From two principal line centers by curvefit in OSPEX:' 
  print, 'Change channel value in ELUT by ', dbin_linecenters, ' PHA bins'
  print, 'From fitting line centers to obtain new gain and offset and finding the offset difference'
  print, 'Change channel value in ELUT by ', dbin_fitgain, ' PHA bins'
  elut_shift = { crosscorr: dbin_crosscorr, $
    linecenters: dbin_linecenters, $
    fitgain: dbin_fitgain }
end

