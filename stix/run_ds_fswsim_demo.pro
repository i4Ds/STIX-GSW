pro run_ds_fswsim_demo, scenario=scenario, fsw=fsw, dss=dss, newplotter=newplotter, savefile=savefile
  default, scenario, 'stx_scenario_1'
  
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
    void = stx_plot_object.create_stx_plot(lightcurve, /lightcurve)
    
    ; Create a background object from the loaded data
    void = stx_plot_object.create_stx_plot(background, /background, /add_legend)

  endif else begin
    dss = obj_new('stx_data_simulation')
    dss->set, /stop_on_error
    dss->set, math_error_level=0
    result = dss->getdata(scenario_name=scenario)
    
    fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
    fsw->set, /stop_on_error
    fsw->set, math_error_level=0
    fsw->set, eab_m_acc=bytarr(32)+1
  
    no_time_bins = long(dss->getdata(scenario_name=scenario, output_target='scenario_length') / 4d)
    
    last_ab_starttime = -1
    
    ; Compare packing in old version of fsw sim
    for time_bin = 0L, no_time_bins do begin
      fsw->getproperty,stx_fsw_m_rate_control_regime=rcr 
     
      rcrt = 0
      ;if time_bin gt 35 AND time_bin lt 55 then rcrt = 1
      print, "RCR ", rcr.rcr + rcrt
      
      ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=scenario, rate_control_regime = rcr.rcr + rcrt)
      
      if(ds_result_data eq !NULL) then continue
      
      ; Quickfixes (to be removed later)
      ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d])
      ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d])
      
      ; Process the interval and plot
      fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, total_source_counts=ds_result_data.total_source_counts
      
      if (time_bin eq 8) then begin
        fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
        stx_plot, lightcurve, plot=plot
      endif 
      if (time_bin gt 8) then begin
        fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
        lightcurve = stx_construct_lightcurve(from=lightcurve)
        plot->plot, lightcurve, /overplot
      endif 
    endfor
  endelse
  
  fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
  stx_plot, lightcurve, plot=plot
  stop
end
