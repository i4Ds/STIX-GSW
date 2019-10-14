;+
; :file_comments:
;    this is the gui for the flight software simulator
;    
; :categories:
;    flight software simulation, software, gui
;    
; :examples:
;
; :history:
;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    16-Jan-2015 - Roman Boutellier (FHNW), Added use of base class
;    20-Jan-2015 - Roman Boutellier (FHNW), Now using the stx_flight_software_simulator_plotter to plot everything
;    13-Feb-2015 - Roman Boutellier (FHNW), Removed _realize_widgets_flight_software_simulation_gui method and therefore the
;                                           according method in the base class is now called directly
;    30-Oct-2015 - Laszlo I. Etesi (FHWN),  renamed event_list to eventlist, and trigger_list to triggerlist
;    23-Jan-2017 – ECMD (Graz),             Default is now to override flare times if no flare flag is present.
;-

;+
; :description:
; 	 This function initializes the object. It is called automatically upon creation of the object.
;
; :Params:
;    stx_software_framework, in, optional, type='stx_software_framework'
;       The software framework object (used to be able to pass data to other modules within the framework).
;
; :returns:
;
; :history:
; 	 17-Nov-2014 - Roman Boutellier (FHNW), Initial release
; 	 16-Jan-2015 - Roman Boutellier (FHNW), Added use of base class (init, getting widget ids, renamed methods)
; 	 13-Feb-2015 - Roman Boutellier (FHNW), Realizing widgets by directly calling the according method in the base class
; 	                                        (not using another intermediate method anymore)
;
; :todo:
;    17-Nov-2014 - Roman Boutellier (FHNW), - including the clocked fsw
;-
function stx_flight_software_simulator_gui::init, stx_software_framework=stx_software_framework, fsw=fsw, process=process, plot=plot
  
  ; Create the flight software simulator object
  self.fsw = isa(fsw) ? fsw : obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
  self.fsw_plotter = obj_new('stx_flight_software_simulator_plotter', self.fsw);, plot=0)
  
  ; Store the link to the software framework
  self.stx_software_framework = stx_software_framework
  
  ; Initialize the indexes for the plots to -1
  self.lightcurve_plot_index = -1L
  self.background_plot_index = -1L
  
  ; Initialize the base class
  a = self->stx_gui_base::init()
  
  ; Get the content widget id
  content_widget = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  button_bar_widget = self->stx_gui_base::get_button_bar_widget_id()
  
  
  ; Create the widgets
  self->_create_widgets_flight_software_simulation_gui, content_widget=content_widget, button_bar_widget=button_bar_widget
  ; Realize the widgets by calling the realize_widgets method of the base class
  self->stx_gui_base::realize_widgets
  ; Start the XManager
  self->_start_xmanager_flight_software_simulation_gui
  
  ; Register self to the base for resizing
  self->stx_gui_base::set_object_for_resizing, obj=self
  
  return, 1
end

pro stx_flight_software_simulator_gui::cleanup
  self.stx_software_framework->deregister_fsw_simulation_gui
  
  obj_destroy, self.fsw_plotter
  
end

function stx_flight_software_simulator_gui::_start_process

  ; Debugging
  ; detect level of this call on stack
  help, /traceback, out=tb
  ; Only install error handler if this routine has not been previously called
  ppl_state_info, out_filename=this_file_name
  found = where(stregex(tb, this_file_name) ne -1, level)
  
  if(level -1 eq 0) then begin
    ; Activate error handler
    ; Setup debugging and flow control
    mod_global = self.fsw->get(module='global')
    debug = mod_global.debug
    stop_on_error = mod_global.stop_on_error
    !EXCEPT = mod_global.math_error_level
    
    ; make sure we start fresh
    message, /reset
    
    ; install error handler if no stop_on_error is set; otherwise skip and let IDL stop where
    ; the error occurred
    if(~stop_on_error) then begin
      error = 0
      catch, error
      if(error ne 0) then begin
        catch, /cancel
        help, /last_message, out=last_message
        error = ppl_construct_error(message=last_message, /parse)
        ppl_print_error, error
        return, 1
      endif
    endif
  endif

  ; Set a new software framework object if there is none
  if self.stx_software_framework eq !NULL then self.stx_software_framework = obj_new('stx_software_framework')
  
  self.fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time())
  
;  ; Register the GUI to the software framework
;  self.stx_software_framework->register_fsw_simulation_gui, widget_id=self.base_widget_flight_software_simulation_gui
  
  ; Start the flight software simulator
  
  dss = self.stx_software_framework->get_dss()
  
  scenario_name = self.stx_software_framework->get_scenario()
  

  coarse_flare_row = 0b
  
  self->clear_plot
  
  no_time_bins = long(dss->getdata(scenario_name=scenario_name, output_target='scenario_length') / 4d)

  self.stx_software_framework->focus_flight_software_simulation_gui
  
  for time_bin = 0L, no_time_bins do begin
    
    ; Check the rcr state
    self.fsw->getproperty, current_rcr = rate_control_str
    rcr = rate_control_str.rcr
    
    ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=scenario_name, rate_control_regime=rcr)

    if(ds_result_data eq !NULL) then continue

    ;TODO: remove Quickfixes
    ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d])
    ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d])

    ; Process the interval and plot
    self.fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, total_source_counts=ds_result_data.total_source_counts;, plotting=self.show_fsw_plots

   
    
    ; Plot
    self->plot, fsw=self.fsw, _extra=extra

  endfor
  
  fsw = self.fsw
  fsw->getProperty,  stx_fsw_m_flare_flag = flare_flag, /comp, /comb
  if max(flare_flag.flare_flag) eq 0 then begin
  Widget_Control, self.button_flare_time , Set_Button = 1 
  self -> setFlareTimeOverride, value = 1 

  endif
  
  save, fsw, filename=filepath("fsw.sav",root_dir=scenario_name) 
  return, 1
end


;+
; :description:
; 	 This method creates all the widgets for the flight software simulation GUI.
;
; :returns:
;
; :history:
; 	 17-Nov-2014 - Roman Boutellier (FHNW), Initial release
; 	 16-Jan-2015 - Roman Boutellier (FHNW), Renamed because otherwise the according method in the base class would be overwritten.
; 	                                        Added keywords and changed base widget and buttons
; 	                                        Added button to start the simulation
;    09-Feb-2015 - Roman Boutellier (FHNW), The variance plot and the state plot are now also in seperate tabs
;    26-Feb-2015 - Roman Boutellier (FHNW), The actually selected scenario is now shown in the gui
;    30-Jun-2015 - Roman Boutellier (FHNW), Using default sizes from _get_sizes_widgets as start size
;-
pro stx_flight_software_simulator_gui::_create_widgets_flight_software_simulation_gui, content_widget=content_widget, button_bar_widget=button_bar_widget
  ; Get the default sizes
  default_sizes = (self._get_sizes_widgets()).default_sizes
  
  ; Create the top level base (i.e. the main window for this GUI)
  self.base_widget_flight_software_simulation_gui = widget_base(content_widget,title='Flight Software Simulation GUI', /column, uvalue=self, xsize=default_sizes.fsw_base_widget_x, ysize=default_sizes.fsw_base_widget_y)
  
  ; Register the GUI to the software framework
  self.stx_software_framework->register_fsw_simulation_gui, widget_id=self.base_widget_flight_software_simulation_gui
  
  ; Add the area for the scenario to the top level base
  scenario_area = widget_base(self.base_widget_flight_software_simulation_gui, uname='scenario_area', ysize=20, /row)
  ; Add the scenario label and the place to put the name of the scenario
  label_scenario = widget_label(scenario_area, uname='label_scenario', xsize=50, ysize=15, /align_left, value='Scenario: ')
  self.label_scenario_name = widget_label(scenario_area, uname='label_scenario_name', xsize=250, ysize=15, /align_left, value=file_basename(self.stx_software_framework->get_scenario(),'.csv'))
  
  ; Create the tab base
  self.tab_widget_flight_software_simulaion_gui = widget_tab(self.base_widget_flight_software_simulation_gui)
  
  ; Add the base of the graphs
  self.graph_area = widget_base(self.tab_widget_flight_software_simulaion_gui, title='Lightcurves / States / Variance', uname='graph_area', /column);, ysize=700, xsize=1280)
  ; Add the area for the lightcurve
  lightcurve_area = widget_base(self.graph_area, uname='lightcurve_area', xpad=10, /row);, xsize=1260, ysize=400)
  self.lightcurve_plot_widget = widget_window(lightcurve_area, uname='lightcurve_plot', xsize=default_sizes.fsw_lightcurve_plot_area_x, ysize=default_sizes.fsw_lightcurve_plot_area_y); ysize=default_sizes xsize=1260, ysize=400)
  ; Add the area for the states and variance tabs
  self.tab_variance_state_flight_software_simulation_gui = widget_tab(self.graph_area)
  ;Add the area for the variance
  variance_area = widget_base(self.tab_variance_state_flight_software_simulation_gui, title='Variance', uname='variance_area', xpad=10, /row);, xsize=1260, ysize=260)
  self.variance_plot_widget = widget_window(variance_area, uname='variance_plot', xsize=default_sizes.fsw_lightcurve_plot_area_x, ysize=default_sizes.fsw_variance_plot_area_y);, xsize=1260, ysize=250)
  ; Add the area for the states
  states_area = widget_base(self.tab_variance_state_flight_software_simulation_gui, title='State', uname='states_area', xpad=10, /row);, xsize=1260, ysize=260)
  self.states_plot_widget = widget_window(states_area, uname='states_plot', xsize=default_sizes.fsw_lightcurve_plot_area_x, ysize=default_sizes.fsw_variance_plot_area_y);, xsize=1260, ysize=250)
  
  ; Add the base for the health plot
  self.health_area = widget_base(self.tab_widget_flight_software_simulaion_gui, title='Health', uname='health_area', /column);, ysize=700, xsize=1280)
  ; Add the health plot widget
  self.health_plot_widget = widget_window(self.health_area, uname='health_plot', xsize=default_sizes.fsw_lightcurve_plot_area_x, ysize=default_sizes.fsw_detector_health_plot_area_y);, xsize=1260, ysize=690)
  
  ; Add the buttons
  button_data_sim = widget_button(button_bar_widget, uvalue='button_data_sim', value='Data Simulation')
  button_start_fsw_sim = widget_button(button_bar_widget, uvalue='button_start_fsw_sim', value='Start Flight Software Simulation')
  
  self.tmtc_options = ptr_new(["ALL", "ALL QUICKLOOK", "ALL SCIENCE DATA", "ql_light_curves","ql_background_monitor","ql_calibration_spectrum","ql_flare_flag_location","ql_spectra","ql_variance","sd_xray_0","sd_xray_1","sd_xray_2","sd_xray_3","sd_spectrogram"])
  
  self.list_dump_fsw = widget_list(button_bar_widget, uvalue="list_dump_fsw", value=*self.tmtc_options, ysize=5, /multiple)
  
  time_widged = widget_base(button_bar_widget, /column, title="Override Flaretimes" )
  time_widged_ch = widget_base(time_widged, /column,  /nonexclusive)
  self.override_flare_time = 0
  self.button_flare_time =  widget_button(time_widged_ch, uvalue='button_flare_time', value='Override Flaretimes (%)')
  Widget_Control, self.button_flare_time , Set_Button=0 
  
  self.flare_o_start = 20
  self.flare_o_end = 60
    
  void = CW_FSLIDER(time_widged, /drag,maximum=100, minimum=0,value=self.flare_o_start, uvalue="timer_l")
  void = CW_FSLIDER(time_widged, /drag,maximum=100, minimum=0, value=self.flare_o_end, uvalue="timer_r")
  
  widget_control, self.list_dump_fsw , set_list_select=0
  button_dump_fsw = widget_button(button_bar_widget, uvalue='button_dump_fsw', value='Dump to TMTC')

end

;;+
;; :description:
;;    This method realizes the widget hierarchy for the flight software simulation GUI.
;;    It also creates the different plot widgets, using the according _create_plot_... methods
;;    of the plotter.
;;
;; :Keywords:
;;    -
;;
;; :returns:
;;    -
;;
;; :history:
;;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;;    16-Jan-2015 - Roman Boutellier (FHNW), Renamed because otherwise the according method in the base class would be overwritten.
;;                                           Now uses base class _realize_widget
;;    13-Feb-2015 - Roman Boutellier (FHNW), Removed
;;-
;pro stx_flight_software_simulator_gui::_realize_widgets_flight_software_simulation_gui
;;  widget_control, self.base_widget_flight_software_simulation_gui, /realize
;  self->stx_gui_base::realize_widgets
;end

;+
; :description:
; 	 Start the xmanager to manage the widgets
;
; :returns:
;    -
;    
; :history:
; 	 17-Nov-2014 - Roman Boutellier (FHNW), initial release
;    16-Jan-2015 - Roman Boutellier (FHNW), Renamed because otherwise the according method in the base class would be overwritten.
;-
pro stx_flight_software_simulator_gui::_start_xmanager_flight_software_simulation_gui
  xmanager, 'stx_flight_software_simulator_gui', self.base_widget_flight_software_simulation_gui, /no_block, cleanup='stx_flight_software_simulator_gui_cleanup'
  self->load_fsw
end

pro stx_flight_software_simulator_gui_cleanup, base_widget_flight_software_simulation_gui
  widget_control, base_widget_flight_software_simulation_gui, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_flight_software_simulator_gui
  endif
end

pro stx_flight_software_simulator_gui::_cleanup_widgets_flight_software_simulator_gui
  obj_destroy, self
end


pro stx_flight_software_simulator_gui::_create_data_simulation
  ; Create the data simulation gui
  self.stx_software_framework->create_data_simulation_gui
end


;+
; :description:
; 	 This procedure handles the resize events of the top level base.
; 	 It is called by the stx_gui_base upon resizing the tlb.
;
; :history:
; 	 27-May-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_flight_software_simulator_gui::_handle_resize_events
  ; Get the geometry data of the top level base
  tlb_geometry = self->stx_gui_base::get_tlb_geometry()
  ; Calculate the new x- and y-sizes of the content widget (differences result from the
  ; space the contents of the gui base take)
  new_x_content = tlb_geometry.xsize - 6
  new_y_content = tlb_geometry.ysize
  
  ; Get the default and minimal values for the sizes
  default_minimal_sizes = self->_get_sizes_widgets()
  
  ; Check if the new values are at least of minimal size
  if new_x_content lt default_minimal_sizes.minimal_sizes.fsw_base_widget_x then begin
    ; Set the x-size to the minimal size
    widget_control, self.lightcurve_plot_widget, xsize=default_minimal_sizes.minimal_sizes.fsw_lightcurve_plot_area_x
    widget_control, self.variance_plot_widget, xsize=default_minimal_sizes.minimal_sizes.fsw_lightcurve_plot_area_x
    widget_control, self.states_plot_widget, xsize=default_minimal_sizes.minimal_sizes.fsw_lightcurve_plot_area_x
    widget_control, self.health_plot_widget, xsize=default_minimal_sizes.minimal_sizes.fsw_lightcurve_plot_area_x
    ; Set the new x-size of the main widget base
    widget_control, self.base_widget_flight_software_simulation_gui, xsize=default_minimal_sizes.minimal_sizes.fsw_base_widget_x
  endif else begin
    ; Set the new x-size of the widget windows
    widget_control, self.lightcurve_plot_widget, xsize=new_x_content - 40
    widget_control, self.variance_plot_widget, xsize=new_x_content - 40
    widget_control, self.states_plot_widget, xsize=new_x_content - 40
    widget_control, self.health_plot_widget, xsize=new_x_content - 40
    ; Set the new x-size of the main widget base
    widget_control, self.base_widget_flight_software_simulation_gui, xsize=new_x_content
  endelse
  if new_y_content lt default_minimal_sizes.minimal_sizes.fsw_base_widget_y then begin
    ; Set the y-size to the minimal size
    ; Therefore set the minimal y-size of the health plot and the other plots
    widget_control, self.lightcurve_plot_widget, ysize=default_minimal_sizes.minimal_sizes.fsw_lightcurve_plot_area_y
    widget_control, self.variance_plot_widget, ysize=default_minimal_sizes.minimal_sizes.fsw_variance_plot_area_y
    widget_control, self.states_plot_widget, ysize=default_minimal_sizes.minimal_sizes.fsw_variance_plot_area_y
    widget_control, self.health_plot_widget, ysize=default_minimal_sizes.minimal_sizes.fsw_detector_health_plot_area_y
    ; Set the new y-size of the main widget base
    widget_control, self.base_widget_flight_software_simulation_gui, ysize=default_minimal_sizes.minimal_sizes.fsw_base_widget_y
  endif else begin
    ; Set the new y-size
    widget_control, self.lightcurve_plot_widget, ysize=(((new_y_content) / 13) * 5)
    widget_control, self.variance_plot_widget, ysize=(((new_y_content) / 13) * 6) -180
    widget_control, self.states_plot_widget, ysize=(((new_y_content) / 13) * 6) -180
    widget_control, self.health_plot_widget, ysize=new_y_content - 200
    ; Set the new y-size of the main widget base
    widget_control, self.base_widget_flight_software_simulation_gui, ysize=new_y_content-210
  endelse
end



pro stx_flight_software_simulator_gui::_write_tmtc 
  if isa(self.fsw) then self.fsw->getproperty, current_bin=current_bin
  
  if ~isa(current_bin) or current_bin lt 0 then begin
    start_scenario = dialog_message('The selected scenario has not yet been processed. Would you like to run the scenario simulation now?',/question)
    ; Check the answer of the user
    if start_scenario eq 'No' then begin
      return
    endif else begin
      ; Show the data simulation window
      self._start_flight_software_simulation
    endelse
  endif
  
  print, *self.tmtc_options  
  selection = widget_info(self.list_dump_fsw, /list_select)
  
  if n_elements(selection) eq 1 && selection eq -1 then selection = 0
  
  if where(selection eq 0) ne -1 then input_data = {ql_all : 1, sd_all : 1} $ 
    else if where(selection eq 1) ne -1 then input_data = {ql_all : 1} $
      else if where(selection eq 2) ne -1 then input_data = {sd_all : 1}
          
  foreach dataproduct, (*self.tmtc_options)[selection]  do begin
    input_data = add_tag(input_data, 1, dataproduct)
  endforeach
          
        
  if (self.override_flare_time) then begin
    self.override_shape->getdata, s
    flare_start = s[0,0]
    flare_end = s[0,2]
    input_data = add_tag(input_data,[flare_start,flare_end], "rel_flare_time")
  endif
  
  tmtc_filename = filepath("tmtc.bin",root_dir=self.stx_software_framework->get_scenario())
  ret = self.fsw->getdata(output_target="stx_fsw_tmtc", filename=tmtc_filename, _extra=input_data)
  print, "TMTC export done: "; + ret
  
end

;+
; :description:
;    Event handler for the button to start the simulation.
;    Starts the fsw simulation process.
;    In case there is no simulated data ready, tell the user so and ask if
;    the scenario should be simulated first.
;
; :Params:
;   -
;
; :returns:
;   -
;   
; :history:
;    16-Jan-2015 - Roman Boutellier (FHNW), Initial release
;    18-Feb-2015 - Roman Boutellier (FHNW), Added check if scenario has already been simulated
;    
; :todo:
;    18-Feb-2015 - Roman Boutellier (FHNW), Change so that the stx_software_framework is not used anymore
;                                           as otherwise the fsw simulator won't work without it
;-
pro stx_flight_software_simulator_gui::_start_flight_software_simulation

  ; Check if the scenario has already been simulated
  already_simulated = self.stx_software_framework->is_scenario_simulated()
  ; Hide the data simulation gui
;  self.stx_software_framework->hide_data_simulation_gui
  
  widget_control, self.base_widget_flight_software_simulation_gui, /show
  ; Show a dialog explaining that the scenario has to be simulated first in case it has not yet been done
  if already_simulated eq 0 then begin
    simulate_scenario = dialog_message('The selected scenario has not yet been simulated. Would you like to simulate the scenario now?',/question)
    ; Check the answer of the user
    if simulate_scenario eq 'No' then begin
      ; Do nothing
    endif else begin
      ; Show the data simulation window
      self.stx_software_framework->focus_data_simulation_gui
    endelse
  endif else begin
    res = self->_start_process()
  endelse

end


PRO stx_flight_software_simulator_gui::process, eventlist, triggerlist, plotting=plotting, fsw=fsw, _extra=extra
      ; detect level of this call on stack
  help, /traceback, out=tb
  ; only install error handler if this routine has not been previously called
  ppl_state_info, out_filename=this_file_name
  found = where(stregex(tb, this_file_name) ne -1, level)
  
  if(level -1 eq 0) then begin
    ; activate error handler
    ; setup debugging and flow control
    mod_global = self->get(module='global')
    debug = mod_global.debug
    stop_on_error = mod_global.stop_on_error
    !EXCEPT = mod_global.math_error_level
    
    ; make sure we start fresh
    message, /reset
    
    ; install error handler if no stop_on_error is set; otherwise skip and let IDL stop where
    ; the error occurred
    if(~stop_on_error) then begin
      error = 0
      catch, error
      if(error ne 0) then begin
        catch, /cancel
        help, /last_message, out=last_message
        error = ppl_construct_error(message=last_message, /parse)
        ppl_print_error, error
        return
      endif
    endif
  endif
    
   if ~ppl_typeof(eventlist, compareto="stx_sim_detector_eventlist") then begin
    message, "eventlist has to be of type 'stx_sim_detector_eventlist'", /continue
    return
   end
   if ~ppl_typeof(triggerlist, compareto="stx_sim_event_triggerlist") then begin
    message, "triggerlist has to be of type 'stx_sim_event_triggerlist'", /continue
    return
   end

   fsw->process, eventlist, triggerlist, _extra=extra
        
   ; Plot
   if keyword_set(plotting) then self->plot, fsw=fsw, _extra=extra

end

pro stx_flight_software_simulator_gui::clear_plot
  
  
  
  ;if  widget_info(self.lightcurve_plot_widget, /VALID_ID)  then widget_control, self.lightcurve_plot_widget, get_value=window_lightcurves
  ;if  widget_info(self.health_plot_widget, /VALID_ID)  then  widget_control, self.health_plot_widget, get_value=window_health
  ;if  widget_info(self.variance_plot_widget, /VALID_ID)  then  widget_control, self.variance_plot_widget, get_value=window_variance
  ;if  widget_info(self.states_plot_widget, /VALID_ID)  then  widget_control, self.states_plot_widget, get_value=window_states
  
  ;self.lightcurve_plot_index = -1
  ;self.background_plot_index = -1
  
  if isa(self.variance_plot_object) then self.variance_plot_object->delete
  if isa(self.health_plot_object) then self.health_plot_object->delete
  if isa(self.states_plot_object) then  self.states_plot_object->delete
  if isa(self.lightcurve_plot_object) then self.lightcurve_plot_object->delete

    
  ;if (isa(window_lightcurves)) then window_lightcurves.Erase
  ;if (isa(window_health)) then window_health.Erase
  ;if (isa(window_variance)) then window_variance.Erase
  ;if (isa(window_states)) then window_states.Erase
  
end



;+
; :description:
; 	 Plots all the different plots of the Flight Software Simulator GUI by calling for each plot
; 	 the plot method of the fsw_plotter.
;
; :Keywords:
;    _extra
;
; :returns:
;
; :history:
; 	 20-Jan-2015 - Roman Boutellier (FHNW), Initial release
;
; :todo:
;    20-Jan-2015 - Roman Boutellier (FHNW), - Add health plot
;-
pro stx_flight_software_simulator_gui::plot, fsw=fsw, _extra=extra

  ; Check if enough steps have been made to be able to plot any lightcurves
  if fsw.current_bin gt 7 then begin
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
    
    ; Lightcurve/Background
    widget_control, self.lightcurve_plot_widget, get_value=window_lightcurves
    
    
    lightcurve = stx_construct_lightcurve(from=lightcurve)
    background = stx_construct_lightcurve(from=bg)
    background.energy_axis = bg.energy_axis
    
    lc_total_counts = ppl_replace_tag(lightcurve, "data", double(reform(total(lightcurve.data,1))))
    lc_total_counts =  ppl_replace_tag(lc_total_counts, "energy_axis", stx_construct_energy_axis(energy_edges=lc_total_counts.energy_axis.edges_1[[0,5]], select=[0,1]))

    
    if self.lightcurve_plot_index eq -1 then begin
      ; Create a new stx_plot
      self.lightcurve_plot_object = obj_new('stx_plot')
      self.lightcurve_plot_index = self.lightcurve_plot_object.create_stx_plot(lightcurve, /lightcurve, dimension=[1260,400], position=[0.1,0.15,0.7,0.95], current=window_lightcurves)
      self.background_plot_index = self.lightcurve_plot_object.create_stx_plot(background, /background, dimension=[1260,400], position=[0.1,0.15,0.7,0.95], /add_legend)
    endif else begin
      void = self.lightcurve_plot_object.create_stx_plot(lightcurve, /lightcurve, /append, idx=self.lightcurve_plot_index)
      void = self.lightcurve_plot_object.create_stx_plot(background, /background, /append, idx=self.background_plot_index)
    endelse
    
    ; Archive Buffer
    widget_control, self.variance_plot_widget, get_value=window_variance
    if self.variance_plot_object eq !NULL then begin
      ; Create a new archive buffer plot object
      self.variance_plot_object = obj_new('stx_archive_buffer_plot')
      self.variance_plot_object.plot, start_time=reference_time, current_time=current_time, lc_total_counts=lc_total_counts, $
                                      variance=variance, archive_buffer=stx_fsw_m_archive_buffer_group, dimensions=[1260,250], $
                                      position=[0.1,0.2,0.7,0.95], current_window=window_variance, /add_legend, /xstyle, /ystyle
    endif else begin
      self.variance_plot_object.append_data, start_time=reference_time, current_time=current_time, $
                                    lc_total_counts=lc_total_counts, $
                                    variance=variance, archive_buffer=stx_fsw_m_archive_buffer_group
    endelse
    
    ; State plot
    widget_control, self.states_plot_widget, get_value=window_states
    if self.states_plot_object eq !NULL then begin
      ; Create a new state plot object
      self.states_plot_object = obj_new('stx_state_plot')
      self.states_plot_object.plot, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
                                    start_time=reference_time, coarse_flare_location=coarse_flare_location, dimensions=[1260,250], $
                                    position=[0.1,0.2,0.7,0.95], current_window=window_states, /add_legend
    endif else begin
      self.states_plot_object.append_data, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
                                  start_time=reference_time, coarse_flare_location=coarse_flare_location
    endelse
    
;    ; Detector health plot
    widget_control, self.health_plot_widget, get_value=window_health
    ; Set the plot positions
    plot_positions = [[0.1,0.1,0.9,0.1185],[0.1,0.1235,0.9,0.142],[0.1,0.147,0.9,0.1655],[0.1,0.1705,0.9,0.189],[0.1,0.194,0.9,0.2125],[0.1,0.2175,0.9,0.236], $
                [0.1,0.241,0.9,0.2595],[0.1,0.264,0.9,0.283],[0.1,0.288,0.9,0.3065],[0.1,0.3115,0.9,0.33],[0.1,0.335,0.9,0.3535],[0.1,0.3585,0.9,0.377], $
                [0.1,0.382,0.9,0.4005],[0.1,0.4055,0.9,0.424],[0.1,0.429,0.9,0.4475],[0.1,0.4525,0.9,0.471],[0.1,0.476,0.9,0.4945],[0.1,0.4995,0.9,0.518], $
                [0.1,0.523,0.9,0.5415],[0.1,0.5465,0.9,0.565],[0.1,0.57,0.9,0.5885],[0.1,0.5935,0.9,0.612],[0.1,0.617,0.9,0.6355],[0.1,0.6405,0.9,0.659], $
                [0.1,0.664,0.9,0.6825],[0.1,0.6875,0.9,0.706],[0.1,0.711,0.9,0.7295],[0.1,0.7345,0.9,0.753],[0.1,0.758,0.9,0.7765],[0.1,0.7845,0.9,0.8], $
                [0.1,0.805,0.9,0.8235],[0.1,0.8285,0.9,0.847],[0.1,0.852,0.9,0.8705]]
    if self.health_plot_object eq !NULL then begin
      ; Create a new detector health plot object
      self.health_plot_object = obj_new('stx_detector_health_plot')
      self.health_plot_object.plot, detector_monitor=detector_monitor, flare_flag=flare_flag, $
                                    start_time=reference_time, current_time=current_time, $
                                    dimensions=[700,1280], position=[0.1,0.2,0.9,0.9], plot_position=plot_positions, current_window=window_health
    endif else begin
      self.health_plot_object.update_plots, detector_monitor=detector_monitor, flare_flag=flare_flag, $
                                    start_time=reference_time, current_time=current_time
    endelse
  endif
  
;  widget_control, self.lightcurve_plot_widget, get_value=window_lightcurves
;  self.fsw_plotter->plot, /light, current=window_lightcurves, showxlabels=0, position=[0.1,0.1,0.7,0.95]
;  
;  widget_control, self.states_plot_widget, get_value=window_states
;  self.fsw_plotter->plot, /states, current=window_states, showxlabels=0, position=[0.1,0.1,0.7,0.95]
;  
;  widget_control, self.variance_plot_widget, get_value=window_variance
;  self.fsw_plotter->plot, /archive, current=window_variance, showxlabels=1, position=[0.1,0.2,0.7,0.95]
;  
;  widget_control, self.health_plot_widget, get_value=window_health
;  self.fsw_plotter->plot, /detector_health, current=window_health, showxlabels=0, position=[0.1,0.1,0.8,0.95]
end

;+
; :description:
;    This method handles a click on the "Load Scenario" entry of the menu bar.
;
; :Keywords:
;    callback_object, in, required
;
; :returns:
;
; :history:
;    13-Feb-2015 - Roman Boutellier (FHNW), Initial release
;    25-Feb-2015 - Roman Boutellier (FHNW), Added keyword "selected_scenario" to the creation of the selection window
;-
pro stx_flight_software_simulator_gui::handle_load_scenario_click, callback_object=callback_object
  scenario_selection_object = obj_new('stx_gui_select_scenario_window',calling_stx_software_framework=self,selected_scenario=self.stx_software_framework->get_scenario())
end

;+
; :description:
;    Set the scenario in the software framework.
;
; :Keywords:
;    scenario, in, required, type=String
;     The name of the scenario
;
; :returns:
;
; :history:
;    13-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_flight_software_simulator_gui::set_scenario, scenario=scenario
  ; Update the scenario within the stx_software_framework
  self.stx_software_framework->set_scenario, scenario=scenario
  
  self->load_fsw
end

pro stx_flight_software_simulator_gui::load_fsw
    
  fsw_filename = filepath("fsw.sav",root_dir=self.stx_software_framework->get_scenario())

  self->clear_plot

  if file_exist(fsw_filename) then begin
    restore, filename=fsw_filename, /ver
    if isa(fsw) then begin
      destroy, self.fsw
      self.fsw = fsw
      self->plot, fsw=self.fsw
    endif
  endif

end

;+
; :description:
; 	 Setting the name of the scenario in the according label
;
; :Keywords:
;    new_scenario_name, in, required, type='String'
;
; :returns:
;    -
;    
; :history:
; 	 26-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_flight_software_simulator_gui::update_scenario_name_label, new_scenario_name=new_scenario_name
  ; Remove any path parts and extensions
  cleaned_scenario_name = file_basename(new_scenario_name, '.csv')
  ; Set the name of the scenario
  widget_control, self.label_scenario_name, set_value=cleaned_scenario_name
end

;+
; :description:
; 	 The default and minimal sizes for all the GUI parts are stored in this function.
; 	 It returns a struct containing two structs with the values, one for default values
; 	 and one for minimal values.
;
; :returns:
;   struct
;   
; :history:
; 	 28-May-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_flight_software_simulator_gui::_get_sizes_widgets
  ; Return a struct which contains the default and minimal sizes of the different parts of the gui
  sizes_struct = { $
    default_sizes: { $
      fsw_base_widget_x: 1000, $
      fsw_base_widget_y: 500, $
      fsw_lightcurve_plot_area_x: 960, $
      fsw_lightcurve_plot_area_y: 200, $
      fsw_variance_plot_area_y: 200, $
      fsw_detector_health_plot_area_y: 400 $
    }, $
    minimal_sizes: { $
      fsw_base_widget_x: 1000, $
      fsw_base_widget_y: 500, $
      fsw_lightcurve_plot_area_x: 960, $
      fsw_lightcurve_plot_area_y: 330, $
      fsw_variance_plot_area_y: 208, $
      fsw_detector_health_plot_area_y: 540 $
    } $
  }
  
  return, sizes_struct
end

pro stx_flight_software_simulator_gui::_handle_events, event
  print, event
  widget_control, event.id, get_uvalue=component
  if ~isa(component) then  return 
  
  if is_object(component) then begin
    component->_handle_resize_events
    return
  endif
  switch (component) of
    "button_start_fsw_sim": begin
      self->_start_flight_software_simulation
      break
    end
    
    "button_data_sim": begin
      self->_create_data_simulation
      break
    end
    
    "button_dump_fsw": begin
      self->_write_tmtc
      break
    end
    
    "list_dump_fsw": begin
      ;nothing
      break
    end
   
    
    "timer_l": begin
      self.flare_o_start = event.value
      
      if self.flare_o_start gt self.flare_o_end then begin
        self.flare_o_start = self.flare_o_end
        widget_control, event.id, set_value = self.flare_o_start
      endif
      self->setrect
      break
    end
    
    "timer_r": begin
      self.flare_o_end = event.value
      
      if self.flare_o_end lt self.flare_o_start then begin
        self.flare_o_end = self.flare_o_start
        widget_control, event.id, set_value = self.flare_o_end
      endif
      self->setrect
      break
    end
    "button_flare_time": begin
      self -> setFlareTimeOverride 
      break
    end
    
    else: begin
      self->_handle_resize_events
    end
  endswitch

  
  
end

pro stx_flight_software_simulator_gui::setRect
  if ~isa(self.fsw) || ~isa(self.override_shape) then return
  
  self.fsw->getproperty, current_time=current_time, reference_time=reference_time
  
  time_range = stx_time_diff(current_time, reference_time,/abs)
  
  start_time = time_range * (self.flare_o_start/100.0)
  end_time = time_range * (self.flare_o_end/100.0)
  
  self.override_shape->setData, [ [start_time ,1], [start_time,10], [end_time,10], [end_time,1]] 
  
end

pro  stx_flight_software_simulator_gui::setFlareTimeOverride, value = value

 self.override_flare_time = keyword_set(value) ? value : ~self.override_flare_time
      
      if self.override_flare_time AND isa(self.lightcurve_plot_object) then begin
        coords = [ [1,1], [1,1], [1,1], [1,1]]
        self.override_shape = polygon(coords,  TARGET=(self.lightcurve_plot_object)->getWindow(), /DATA, FILL_BACKGROUND=0,  COLOR='red', THICK=3)
        self->setRect
      endif else begin
        if (isa(self.override_shape)) then self.override_shape->delete
        destroy, self.override_shape
      endelse
      
 end     


pro stx_flight_software_simulator_gui__define
  compile_opt idl2
  
  define = {stx_flight_software_simulator_gui, $
      stx_software_framework: obj_new(), $
      fsw         : obj_new(), $
      fsw_plotter : obj_new(), $
      lightcurve_plot_object: obj_new(), $
      variance_plot_object: obj_new(), $
      states_plot_object: obj_new(), $
      health_plot_object: obj_new(), $
      gui: hash(), $
      label_scenario_name: 0L, $
      base_widget_flight_software_simulation_gui: 0L, $
      tab_widget_flight_software_simulaion_gui: 0L, $
      tab_variance_state_flight_software_simulation_gui: 0L, $
      graph_area: 0L, $
      health_area: 0L, $
      lightcurve_plot_widget: 0L, $
      states_plot_widget: 0L, $
      variance_plot_widget: 0L, $
      health_plot_widget: 0L,$
      lightcurve_plot_index: -1L, $
      background_plot_index: -1L, $
      list_dump_fsw : -1L, $ 
      tmtc_options : ptr_new(), $
      button_flare_time : 0L, $
      flare_o_start : 20, $
      flare_o_end : 60, $
      override_flare_time : 0, $
      override_shape : obj_new(), $ 
      inherits stx_gui_base $
  }
end
