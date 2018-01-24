pro stx_run_scenario, scenario_name, fsw=fsw, dss=dss, plotting=plotting
    
   default, plotting, 1
  
  fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
  fsw->set, math_error_level=0
  
  dss = obj_new('stx_data_simulation')
    
  if(~ppl_typeof(scenario_name, compareto='string')) then message, 'You must specify scenario_name'
  
  ;run the data simulation
  res = dss->getdata(scenario_name=scenario_name) 
   
  ; set default rate control state and coarse flare row (0 for top, 1 for bottom)
  rcr = 0
  
  no_time_bins = long(dss->getdata(scenario_name=scenario_name, output_target='scenario_length') / 4d)
  
  fsw->getproperty, current_time=current_time, reference_time=reference_time
  append_time_shift = max([0,stx_time_diff(current_time,reference_time)])
  
  for time_bin = 0L, no_time_bins-1 do begin
    ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=scenario_name, rate_control_regime=rcr)

    if(ds_result_data eq !NULL) then continue

    ; Quickfixes (to be removed later)
    ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d])
    ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d])
        
    ds_result_data.filtered_eventlist.DETECTOR_EVENTS.RELATIVE_TIME += append_time_shift
    ds_result_data.triggers.TRIGGER_EVENTS.RELATIVE_TIME += append_time_shift
    
    ; Process the interval and plot
    fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, total_source_counts=ds_result_data.total_source_counts

    fsw->getproperty, stx_fsw_m_rate_control=rate_control_str, current_bin=current_bin
    
    ; Check the rcr state
    rcr = rate_control_str.rcr
        if plotting then begin
    
      if current_bin eq 2 then begin
        fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
        stx_plot, lightcurve, plot=plot
      endif
      if current_bin gt 2 then begin
        fsw->getproperty, stx_fsw_ql_lightcurve=lightcurve, /complete, /combine
        lightcurve = stx_construct_lightcurve(from=lightcurve)
        plot->plot, lightcurve, /overplot
      endif
    endif ;plotting
  endfor
  
  
end
