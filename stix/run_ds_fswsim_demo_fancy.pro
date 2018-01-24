;+
; :description:
;   Demo routine to show how to use the DSS and FSW
;
; :categories:
;    simulation, demo
;
; :keywords:
;    scenario : in, optional, type='string', default='stx_scenario_2'
;      the name of the scenario file w/o the CSV file ending
;    fsw : out, optional, type='stx_flight_software_simulator'
;      the initialized and processed fsw object (after simulation)
;    dss : out, optional, type='stx_data_simulation
;      the initialized and processed dss object (after simulation)
;
; :examples:
;    run_ds_fswsim_demo, scenario='stx_scenario_2'
;
; :history:
;    11-Feb-2015 - Laszlo I. Etesi (FHNW), initial release (sort of)
;-

pro run_ds_fswsim_demo_fancy, scenario=scenario, fsw=fsw, dss=dss, newplotter=newplotter, savefile=savefile
tic
  default, scenario, 'stx_scenario_2'
  
  if keyword_set(newplotter) then begin
    ; Check if a path to a sav file has been passed
    ; Then load either that file or the default sav file
    if isvalid(savefile) then begin
      restore, savefile
    endif else begin
      restore, 'lightcurves_save_file.fits'
      restore, 'background_save_file.fits'
    endelse
    
    ; Prepare the stx_plot object
    stx_plot_object = obj_new('stx_plot')
    
    ; Create a lightcurve plot from the loaded data
;    lc_p_object = obj_new('stx_lightcurve_plot')
    void = stx_plot_object.create_stx_plot(lightcurve, /lightcurve)
;    lc_p_object.plot, lightcurve
    
    ; Create a background object from the loaded data
;    bg_p_object = obj_new('stx_background_plot')
    void = stx_plot_object.create_stx_plot(background, /background, /add_legend)
;    bg_p_object.plot, background
    
  endif else begin
    dss = obj_new('stx_data_simulation')
    dss->set, /stop_on_error
    dss->set, math_error_level=0
    result = dss->getdata(scenario_name=scenario)
    
    fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
    fsw->set, /stop_on_error
    fsw->set, math_error_level=0
    fsw->set, eab_m_acc=bytarr(32)+1
    
    ;fsw_p = stx_fsw_plot(fsw, /all)
  
    no_time_bins = long(dss->getdata(scenario_name=scenario, output_target='scenario_length') / 4d)
    
    last_ab_starttime = -1
    
    ; Compare packing in old version of fsw sim
    for time_bin = 0L, no_time_bins do begin
      ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=scenario, rate_control_regime=0)
      
      if(ds_result_data eq !NULL) then continue
      
      ; Quickfixes (to be removed later)
      ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d]) ;stx_construct_time(
      ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d]); stx_construct_time()
      
      ; Process the interval and plot
      fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers
      ;if(time_bin eq 36) then stop
;      if(time_bin gt 8) then begin
;        fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, most_n_recent=(time_bin+1), /combine
;        stx_plot, lightcurve, plot=plot
;        stop
;      endif
      
      ; Update all plots
      ;fsw_p->plot, /light;, /arch, /dete, /light, /states
      
      fsw->getproperty, $
      stx_fsw_m_archive_buffer_group=archive_buffer_group, $
        stx_fsw_m_flare_flag=flare_flag, $
        stx_fsw_m_rate_control_regime=rate_control, $
        stx_fsw_m_calibration_spectrum=calibration_spectrum, $
        stx_fsw_m_coarse_flare_location=coarse_flare_location, $
        stx_fsw_m_background=background, $
        stx_fsw_m_variance=variance, $
        stx_fsw_m_detector_monitor=detector_monitor, $
        /most_n_recent
        
      fsw->getproperty, $
        stx_fsw_ql_lightcurve=stx_fsw_ql_lightcurve, $
        stx_fsw_ql_lt_lightcurve=stx_fsw_ql_lt_lightcurve, $
        stx_fsw_ql_spectra=stx_fsw_ql_spectra, $
        stx_fsw_ql_lt_spectra=stx_fsw_ql_lt_spectra, $
        stx_fsw_ql_bkgd_monitor=stx_fsw_ql_bkgd_monitor, $
        stx_fsw_ql_lt_bkgd_monitor=stx_fsw_ql_lt_bkgd_monitor, $
        stx_fsw_ql_variance=stx_fsw_ql_variance, $
        stx_fsw_ql_lt_variance=stx_fsw_ql_lt_variance, $
        stx_fsw_ql_flare_detection=stx_fsw_ql_flare_detection, $
        stx_fsw_ql_lt_flare_detection=stx_fsw_ql_lt_flare_detection, $
        stx_fsw_ql_flare_location_1=stx_fsw_ql_flare_location_1, $
        stx_fsw_ql_lt_flare_location_1=stx_fsw_ql_lt_flare_location_1, $
        stx_fsw_ql_flare_location_2=stx_fsw_ql_flare_location_2, $
        stx_fsw_ql_lt_flare_location_2=stx_fsw_ql_lt_flare_location_2, $
        stx_fsw_ql_detector_anomaly=stx_fsw_ql_detector_anomaly, $
        stx_fsw_ql_lt_detector_anomaly=stx_fsw_ql_lt_detector_anomaly, $
        stx_fsw_ql_quicklook=stx_fsw_ql_quicklook, $
        stx_fsw_ql_lt_quicklook=stx_fsw_ql_lt_quicklook, $
        /complete, /combine
      
      if(time_bin eq 33) then stop
      
      if(archive_buffer_group ne !NULL) then begin
        archive_buffer = archive_buffer_group.archive_buffer
        triggers = transpose(archive_buffer_group.triggers.triggers)
        
        if(last_ab_starttime eq -1 || last_ab_starttime ne min(archive_buffer.relative_time_range)) then begin
          openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'ab', /get_lun
          printf, lun, archive_buffer
          close, lun
          free_lun, lun
          
          last_ab_starttime = min(archive_buffer.relative_time_range)
    
          openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'trg', /get_lun
          printf, lun, uint(triggers)
          close, lun
          free_lun, lun
        endif
      endif

      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'ff', /get_lun
      printf, lun, flare_flag.flare_flag
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'rcr', /get_lun
      printf, lun, rate_control.rcr
      close, lun
      free_lun, lun
      last_rcr_idx = n_elements(rate_control)

      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'calib', /get_lun
      printf, lun, calibration_spectrum.accumulated_counts
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'cfl', /get_lun
      if(coarse_flare_location eq !NULL) then printf, lun, !VALUES.f_nan $
      else printf, lun, transpose([coarse_flare_location.x_pos, coarse_flare_location.y_pos])
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'dm', /get_lun
      printf, lun, transpose(detector_monitor.active_detectors)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'var', /get_lun
      printf, lun, variance.variance
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'bkg', /get_lun
      printf, lun, float(transpose(background.background))
      close, lun
      free_lun, lun
      
      ;stop
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_lightcurve', /get_lun
      printf, lun, reform(stx_fsw_ql_lightcurve.accumulated_counts)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_lightcurve_lt', /get_lun
      printf, lun, reform(stx_fsw_ql_lt_lightcurve.accumulated_counts)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_detection', /get_lun
      printf, lun, reform(stx_fsw_ql_flare_detection.accumulated_counts)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_detection_lt', /get_lun
      printf, lun, reform(stx_fsw_ql_lt_flare_detection.accumulated_counts)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_variance', /get_lun
      printf, lun, reform(stx_fsw_ql_variance.accumulated_counts, n_elements(reform(stx_fsw_ql_variance.accumulated_counts)))
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_variance_lt', /get_lun
      printf, lun, reform(stx_fsw_ql_lt_variance.accumulated_counts, n_elements(reform(stx_fsw_ql_lt_variance.accumulated_counts)))
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_quicklook_lt', /get_lun
      printf, lun, reform(stx_fsw_ql_lt_quicklook.accumulated_counts)
      close, lun
      free_lun, lun
      
      openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_quicklook', /get_lun
      printf, lun, reform(stx_fsw_ql_quicklook.accumulated_counts)
      close, lun
      free_lun, lun
      
      if(time_bin ge 1 && time_bin mod 2) then begin
      
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_det_anomaly', /get_lun
        printf, lun, reform(stx_fsw_ql_detector_anomaly.accumulated_counts)
        close, lun
        free_lun, lun
        
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_det_anomaly_lt', /get_lun
        printf, lun, reform(stx_fsw_ql_lt_detector_anomaly.accumulated_counts)
        close, lun
        free_lun, lun
        
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_location_1', /get_lun
        printf, lun, reform(stx_fsw_ql_flare_location_1.accumulated_counts)
        close, lun
        free_lun, lun
        
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_location_1_lt', /get_lun
        printf, lun, reform(stx_fsw_ql_lt_flare_location_1.accumulated_counts)
        close, lun
        free_lun, lun
        
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_location_2', /get_lun
        printf, lun, reform(stx_fsw_ql_flare_location_2.accumulated_counts)
        close, lun
        free_lun, lun
        
        openw, lun, 'c:\temp\comp\new\' + trim(string(time_bin)) + 'stx_fsw_ql_flare_location_2_lt', /get_lun
        printf, lun, reform(stx_fsw_ql_lt_flare_location_2.accumulated_counts)
        close, lun
        free_lun, lun
      endif
    endfor
  endelse
  ;save, fsw, file='fsw.sav'
  print, 1
  toc
  
  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot
  stop
end
