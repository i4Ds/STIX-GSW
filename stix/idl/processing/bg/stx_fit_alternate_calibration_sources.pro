;+
; :description:
;    This procedure reads a telemetry file from test calibration spectra data and fits the known emission lines
;    for that source. The offset and gain for each detector pixel are calculated and saved to a file
;
; :categories:
;    calibration, fitting
;
; :params:
;    temperature: temperature of the aluminium plate for desired test run
;
;    timepeak: peaking time in us for test run
;
;    voltage: applied voltage
;
;    source: calibration source used in test run
;
; :keywords:
;
;    plotting : plot the calibration
;
;
; :examples:
;   stx_fit_alternate_calibration_sources, -40, 2,  300, 'co57', /plotting
;
; :history:
;    1-Apr-2019 - ECMD (Graz), initial release
;
;-
pro stx_fit_alternate_calibration_sources, temperature, timepeak, voltage, source, plotting = plotting

  ;set defaults of the parameters from different test procedures
  default, temperature,  -20
  default, timepeak, 2
  default, voltage, 300
  default, source, 'co57'
  default, plotting, 1


  ;get the line energies, any additional Gaussians needed for background and the broad energy ranges to perform fits
  ;for the specific source
  gauss_line_param = stx_alternate_cal_lines_mdl(source, background_line_param = background_line_param, $
    fit_energy_ranges = fit_energy_ranges, ilines = ilines)

  ; the number of real emission line components
  n_fit_lines = n_elements(gauss_line_param)/3
  ; the number of background Gaussians components
  n_back_lines = n_elements(background_line_param)/3

  ; the total number of components to fit
  ncomponents  =  n_fit_lines + n_back_lines

  ;the expected intensity of the emission lines and the energy of the emission line are included in the gauss_line_param
  ;extract them for easier setting of the default fit parameters later
  line_intensity =  gauss_line_param[0:*:3]
  realtive_line_intensity = line_intensity/max(line_intensity)
  line_energies = gauss_line_param[1:*:3]

  ;set the telemetry parameters to get an array at the maximum resolution
  iedg = [[0,511],[512,1020]]
  nconfig = (size( /dim, iedg))[1]
  igroup = [ 1,1]
  ql_calibration_spectrum_compression_counts = [0b,5b,3b]

  width = reform(  iedg[1,*] - iedg[0,*] + 1 )
  npoints = width /igroup
  ;check that iedg[1,i] is consistent with igroup and iedg[0,i], if not change the iedg
  for i=0,nconfig-1 do begin
    iedg[1,i] = iedg[0,i] + npoints[i] * igroup[i] -1
    if i lt (nconfig-1) then iedg[0,i+1] = iedg[1,i]+1
  endfor

  ilo = reform( iedg[ 0, *] )
  configuration_struct = replicate( stx_bkg_ecal_substr(), nconfig )

  configuration_struct.ichan_lo = ilo
  configuration_struct.ngroup   = igroup
  configuration_struct.npoints  = npoints
  configuration_struct.did      = 1 ;should not be zero, even for demo
  configuration_struct.cmp_s = ql_calibration_spectrum_compression_counts[0]
  configuration_struct.cmp_k = ql_calibration_spectrum_compression_counts[1]
  configuration_struct.cmp_m = ql_calibration_spectrum_compression_counts[2]

  erange = [-1000.,1000.]

  stx_bkg_sim_demo, configuration_struct, spec=sp, dspec = dsp, ch_axis = ch_axis, gauss_line_param = gauss_line_param, $
    /noplot, poisson = 0, continuum_factor = 0 , erange = erange ;first time without MonteCarlo to get line centers

  ;the calibration telemetry files are saved with a naming scheme based on the parameters tested
  name = strcompress('TMTC_packet_T'+string(temperature)+'_Peak'+string(timepeak)+'_Volt'+string(voltage)+'_'+SOURCE+'.bin',/remove_all)

  ;read in the data from the telemetry file
  tmtc_reader = stx_telemetry_reader(filename=name, /scan_mode)
  tmtc_reader->getdata, asw_ql_calibration_spectrum = calibration_spectra, solo_packets = solo_packets, statistics = statistics, /comp, /comb

  ;use a similar naming scheme to save the fit data
  savename = 'Calibration_fit_T'+string(temperature)+'_Peak'+string(timepeak)+'_Volt'+string(voltage)+'_'+SOURCE+'.sav'

  ;loop through all calibration
  foreach calibration_data, calibration_spectra do begin

    ;masks assuming all pixels and detectors are active
    pixel_mask = make_array(12, /byte, value=1b)
    detector_mask = make_array(32, /byte, value=1b)

    ;concert calibration_data structure into array of [1024 energy bins x 12 pixels x 32 detectors]
    calibration_spectrum = stx_calibration_data_array(calibration_data, pixel_mask = pixel_mask , detector_mask = detector_mask )

    ;get the first entry for a detailed fit
    cs0  = calibration_spectrum[*,0,0]

    ;the converted data uses an energy binning that runs to 300 keV with 1024 bins
    e_bin = (findgen(1025)+1)*(300./1023.)
    edge_products, e_bin, edges_2 = e_bin2, width = ewidth

    ;Find the max flux to set the fit_comp_maxima
    ;establish the fit range prior
    mxflux = max(cs0 )
    fit_range = 10.^round(alog10(mxflux)) * [.001, 100]

    ;make an array of offset gain structures to store the fit results
    dog_str = replicate(stx_offsetgain(), 32, 12)

    ;Start with a baseline fit to speed up the fitting process
    ;fitting is done using ospex so make a new object
    obj = ospex()
    set_logenv, 'OSPEX_NOINTERACTIVE', '1'

    ; calibration spectrum will be passed directly to the object
    obj -> set, spex_data_source = 'SPEX_USER_DATA'

    ;nominal time range of 1 day
    ut = [0,86400.]

    ;load the calibration spectrum, default energy binning, time range
    ;livetime fraction of 1 assumed as calibration spectrum is only accumulated during quiet times
    ;Poisson errors of sqrt(counts) are assumed
    obj->set, spectrum = cs0, spex_ct_edges=e_bin2, spex_ut_edges=ut, livetime=cs0*0+1. ,errors = sqrt(cs0)

    ;response values are set to 1 as nodrm components are used for the fitting
    obj->set, spex_respinfo=1, spex_area=1, spex_detectors='stix'

    obj-> set, spex_source_angle= 0.00000
    obj-> set, spex_source_xy= [0.00000, 0.00000]

    ;set the energy ranges based on the source being fit
    obj-> set, spex_erange= fit_energy_ranges

    ;use a Gaussian line which does not go through the drm for all components
    fnames = replicate('line_nodrm',ncomponents)

    obj-> set, fit_function= arr2str(fnames,delim='+')

    ;default starting parameters for both the emission lines and background components as read in previously
    fit_comp_params = [gauss_line_param, background_line_param]

    ;make an array for the minima, most of these values with be overwritten setting line widths
    ;0.1 for the real emission lines and 1 for the background components
    fit_comp_minima = [ fltarr(3 * n_fit_lines) + 0.1 , fltarr(3 *n_back_lines) + 1]

    fit_comp_maxima = [ fltarr(3 * n_fit_lines) + 3 , fltarr(3 *n_back_lines) + 25]

    ;the first peak contains emission from several lines so it is usually the highest
    ;scale for the other lines based on the
    line_intensity =  fit_comp_params[0:*:3]
    realtive_line_intensity = line_intensity/max(line_intensity)

    line_energies = fit_comp_params[1:*:3]
    line_sigma = fit_comp_params[2:*:3]

    ;set the integrated intensity for the lines based on the maximum peak value and the expected width of each line
    fit_comp_params[0:*:3] = mxflux*sqrt(2*!pi)*line_sigma/ewidth[0]

    ;set the range for the line intensity based on the maximum peak value
    fit_comp_minima[0:*:3] = fit_range[0]
    fit_comp_maxima[0:*:3] = fit_range[1]

    ;set the maximum and minimum values for the line energies to ±20% of their expected values
    fit_comp_minima[1:*:3] = line_energies*.8
    fit_comp_maxima[1:*:3] = line_energies*1.2

    ;set the starting values, maxima and minima in the object
    obj-> set, fit_comp_params= fit_comp_params
    obj-> set, fit_comp_maxima = fit_comp_maxima
    obj-> set, fit_comp_minima = fit_comp_minima

    ;all parameters are free
    obj-> set, fit_comp_free_mask= intarr(3*ncomponents) +1
    obj-> set, fit_comp_spectrum= replicate('',ncomponents)
    obj-> set, fit_comp_model= replicate('',ncomponents)
    obj-> set, spex_autoplot_bksub= 0
    obj-> set, spex_autoplot_overlay_back= 0
    obj-> set, spex_autoplot_units= 'counts'
    obj-> set, spex_fitcomp_plot_units= 'Counts'

    obj->set, spex_fit_manual=0, spex_autoplot_enable=plotting, spex_fitcomp_plot_resid = 0, spex_fit_progbar=0
    ;do the fit
    obj->dofit, /all

    if plotting then obj->plot_spectrum, /show_fit

    fit_function = str2arr( obj->get(/fit_function), '+')

    ;read the fit parameters and sigma
    fit_params = reform( obj->get(/spex_summ_params), 3, ncomponents )
    fit_sigmas = reform( obj->get(/spex_summ_sigma), 3, ncomponents )

    ;the line energies that correspond to the emission lines used to estimate offset and gain
    cal_lines = fit_params[1,ilines]

    ;the expected parameters as read from stx_alternate_cal_lines_mdl
    true_params = reform( gauss_line_param, 3, n_fit_lines )

    ;get the energy bins used by ospex
    ebin = obj->get(/spex_summ_energy)

    edg1 = get_edges( ebin, /edges_1 )

    ;the number of the energy bins where the energies correspond to the fit lines
    a = value_locate( edg1, cal_lines[0])
    b = value_locate( edg1, cal_lines[1])

    ;the energy value of the bin where the lines are located
    e1 =  ebin[*,a]
    e2 =  ebin[*,b]

    ;get an initial estimate of the gain in terms of the 1024 bins used here to use with stx_cal_crosscorr to get
    ; a close estimate of the starting values for the line locations
    gain0 =  ( true_params[1,ilines[1]] - true_params[1,ilines[0]]) / (b-a)

    ;get the fit parameters from this initial fit, the will be usued as a basis fo subsequent fits to speed up the processing
    first_fit_params = reform( obj->get(/spex_summ_params))

    ;loop over all detectors and pixels
    for idx_det = 0, 31 do begin
      if detector_mask[idx_det] eq 1 then begin
        for idx_pix = 0, 11 do begin
          if pixel_mask[idx_pix] eq 1 then begin

            cs  = calibration_spectrum[*,idx_pix,idx_det]

            ;use the crosscorrelation to find a preliminary estimate of the offset
            ;This will be used to modify the curvefit line energy initial values
            eshift = stx_cal_crosscorr( cs0, cs,  ii, cc, imax, gain = gain0)

            ;initial guess based on the first fit
            this_fit_params = first_fit_params

            ;shift the estimated line energy based on the correlation
            this_fit_params[1:*:3] = first_fit_params[1:*:3] + eshift
            ;line_sigma = first_fit_params[2:*:3]

            ;get the maximum peak value for this calibration spectrum and set the range based on that
            mxflux = max(cs)

            fit_range = 10.^round(alog10(mxflux)) * [.001, 100]

            ;starting values for intensity are agfin based on the
            fit_comp_params[0:*:3] = mxflux*sqrt(2*!pi)*line_sigma/ewidth[0]

            fit_comp_minima[0:*:3] = fit_range[0]
            fit_comp_maxima[0:*:3] = fit_range[1]

            ;starting values for energy are based on true line energy + cross correlation
            fit_comp_minima[1:*:3] = (this_fit_params[1:*:3])*.8
            fit_comp_maxima[1:*:3] = (this_fit_params[1:*:3])*1.2

            ;initial guesses for parameters not set above are taken from the results of the first fit
            obj-> set, fit_comp_params= this_fit_params
            obj-> set, fit_comp_maxima = fit_comp_maxima
            obj-> set, fit_comp_minima = fit_comp_minima

            ;set the spectrum data into the object and perform the fit
            obj->set, spectrum = cs, spex_ct_edges=edges_2, spex_ut_edges=ut, errors = sqrt(cs)
            obj->dofit, /all

            if plotting then obj->plot_spectrum, /show_fit

            ;recover the fitted parameters for this iteration
            fit_params = reform( obj->get(/spex_summ_params), 3, ncomponents )
            fit_sigmas = reform( obj->get(/spex_summ_sigma),  3, ncomponents )

            ;the line energies that correspond to the emission lines used to estimate offset and gain
            cal_lines = fit_params[1,ilines]

            print, cal_lines

            ;extract line energies and bin locations
            ;the number of the energy bins where the energies correspond to the fit lines
            a = value_locate( edg1, cal_lines[0])
            b = value_locate( edg1, cal_lines[1])

            ;the enegy value of the bin where the lines are located
            e1 =  ebin[*,a]
            e2 =  ebin[*,b]

            ;calculate the offset and gain for this spectrum for the full on board 4096 ADC bins
            gain =  ( true_params[1,ilines[1]] - true_params[1,ilines[0]])/(b-a)/4.
            offset = 4*a -  true_params[1,ilines[0]]/gain

            ;set all relevant parameters into the offset gain structure
            dog_str[idx_det, idx_pix].det_nr = idx_det + 1
            dog_str[idx_det, idx_pix].pix_nr = idx_pix
            dog_str[idx_det, idx_pix].gain = gain
            dog_str[idx_det, idx_pix].offset = offset

          endif
        endfor
      endif
    endfor


    ;write new params to file
    save, dog_str, savename
    set_logenv, 'OSPEX_NOINTERACTIVE', '0'

  endforeach

end



