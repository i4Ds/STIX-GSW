pro stx_plot, data1, data2, data3, data4, data5, data6, plot=plot, fsw=fsw
  compile_opt idl2

  
  
  if ~arg_present(plot) then begin
    
  endif
  
  ; Check if the fsw has been set. If that is the case, plot all the 4 different plots
  if keyword_set(fsw) then begin
    ; Get all the needed data from the fsw object
    fsw->getProperty,     reference_time = reference_time, $
                          current_time  = current_time, $
                          ;total_counts = total_counts, $
                          stx_fsw_m_variance = variance, $
                          ;livetime = livetime, $
                          ;ql_data = ql_data, $
                          stx_fsw_ql_lightcurve=lightcurve, $
                          stx_fsw_m_archive_buffer_group = stx_fsw_m_archive_buffer_group, $
                          stx_fsw_m_background = bg, $
                          stx_fsw_m_detector_monitor = detector_monitor, $
                          stx_fsw_m_flare_flag = flare_flag, $
                          stx_fsw_m_rate_control = rate_control, $
                          stx_fsw_m_coarse_flare_location = coarse_flare_location, $
                          /complete, /combine
      
    ;---------------------------------------------------------------------------------------
    ; First plot the lightcurves and the background
    stx_plot_object = obj_new('stx_plot')


    lightcurve = stx_construct_lightcurve(from=lightcurve)
    background = stx_construct_lightcurve(from=bg)
    background.energy_axis = lightcurve.energy_axis
           
    lc_total_counts = ppl_replace_tag(lightcurve, "data", double(reform(total(lightcurve.data,1))))
    lc_total_counts =  ppl_replace_tag(lc_total_counts, "energy_axis", stx_construct_energy_axis(energy_edges=lc_total_counts.energy_axis.edges_1[[0,5]], select=[0,1]))
           
    a = stx_plot_object.create_stx_plot(lightcurve, /lightcurve, dimensions=[1260,350], position=[0.1,0.1,0.7,0.95])
    b = stx_plot_object.create_stx_plot(background, /background, /add_legend)
    
 
    ;---------------------------------------------------------------------------------------
    ; Plot the archive buffer
    
        
    variance_plot_object = obj_new('stx_archive_buffer_plot')
    variance_plot_object.plot, start_time=reference_time, current_time=current_time, lc_total_counts=lc_total_counts, $
                                      variance=variance, archive_buffer=stx_fsw_m_archive_buffer_group, dimensions=[1260,350], /add_legend


    ;---------------------------------------------------------------------------------------
    ; Plot the state plot
    states_plot_object = obj_new('stx_state_plot')
    states_plot_object.plot, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
                                    start_time=reference_time, coarse_flare_location=coarse_flare_location, dimensions=[1260,350], /add_legend
    
    ;---------------------------------------------------------------------------------------
    ; Plot the detector health plot
    health_plot_object = obj_new('stx_detector_health_plot')
    health_plot_object.plot, detector_monitor=detector_monitor, flare_flag=flare_flag, $
                                    start_time=reference_time, current_time=current_time, $
                                    dimensions=[800,800], position=[0.1,0.1,0.9,0.9]
                                    
    if arg_present(plot) then plot = { $
      stx_lightcurve_plot : stx_plot_object, $
      stx_archive_buffer_plot : variance_plot_object ,$
      stx_state_plot : states_plot_object, $
      stx_detector_health_plot : health_plot_object $
      
    }
 
  endif else begin
    ; Check the number of arguments
    nmbr_params = n_params()
    
    ; Prepare the stx_plot object in case there are more than one parameter
    if nmbr_params gt 1 then stx_plot_object = obj_new('stx_plot')
  
    for ind=0 , nmbr_params-1 do begin
      ; Get the current parameter
      if ind eq 0 then begin
        current_parameter = data1
      endif else begin
        if ind eq 1 then begin
          current_parameter = data2
        endif else begin
          if ind eq 2 then begin
            current_parameter = data3
          endif else begin
            if ind eq 3 then begin
              current_parameter = data4
            endif else begin
              if ind eq 4 then begin
                current_parameter = data5
              endif else begin
                if ind eq 5 then begin
                  current_parameter = data6
                endif
              endelse
            endelse
          endelse
        endelse
      endelse
     
      
      ; If only one parameter has been passed, draw the according plot
      if nmbr_params eq 1 then begin
        ; Check the parameter for its type
        if ppl_typeof(current_parameter, compareto='stx_fsw_ql_lightcurve') then begin
          lightcurve = stx_construct_lightcurve(from=current_parameter)
          ; Create a lightcurve plot
          lc_obj = obj_new('stx_lightcurve_plot')
          lc_obj.plot, lightcurve, /add_legend, /histogram
          
          plot = lc_obj
        endif else begin
          if ppl_typeof(current_parameter, compareto='stx_fsw_result_background') then begin
            background = stx_construct_lightcurve(from=current_parameter)
            ; Create a lightcurve plot
            lc_obj = obj_new('stx_lightcurve_plot')
            lc_obj.plot, background, current=w, /add_legend,  /histogram
            
            plot = lc_obj
          endif else begin
            if ppl_typeof(current_parameter, compareto='') then begin
            
            endif
          endelse
        endelse
      endif else begin
        ; There are more than one parameter
        ; Check the parameter for its type
        if ppl_typeof(current_parameter, compareto='stx_fsw_ql_lightcurve') then begin
          lightcurve = stx_construct_lightcurve(from=current_parameter)
          ; Create a lightcurve plot
          if ind eq nmbr_params-1 then a = stx_plot_object.create_stx_plot(lightcurve, /lightcurve, /add_legend) else $
                                        a = stx_plot_object.create_stx_plot(lightcurve, /lightcurve)
          
          ; If plot is set, store the lightcurve object in that parameter
          if keyword_set(plot) then plot = lc_obj
        endif else begin
          if ppl_typeof(current_parameter, compareto='stx_fsw_result_background') then begin
            background = stx_construct_lightcurve(from=current_parameter)
            ; Create a background plot
            if ind eq nmbr_params-1 then b = stx_plot_object.create_stx_plot(background, /background, /add_legend) else $
                                          b = stx_plot_object.create_stx_plot(background, /background)
                                          
            ; If plot is set, store the background object in that parameter
            if keyword_set(plot) then plot = lc_obj
          endif
        endelse
      endelse
      
    endfor
  endelse
end