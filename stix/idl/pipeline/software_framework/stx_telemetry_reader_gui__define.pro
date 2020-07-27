;+
; :file_comments:
;    this is the telemetry reader gui.
;    
; :categories:
;    telemetry, reader, software, gui
;    
; :examples:
;    ds_gui = obj_new('stx_telemetry_reader_gui')
;    
; :history:
;    03-Nov-2016 - Nicky Hochmuth (FHNW), Initial release
;-

;+
; :description:
; 	 This function initializes the object. It is called automatically upon creation of the object.
;
; :Params:
;    stx_software_framework, in, required, type='stx_software_framework'
;       The software framework object (used to be able to pass data to other modules within the framework)^
;    scenario, in, optional, type=string
;       The name of the scenario which will be simulated. Default is stx_scenario_1 as default folder to lock for telemetry files 
;
; :returns:
;
; :history:
; 	 03-Nov-2016 - Nicky Hochmuth (FHNW), Initial release
;-
function stx_telemetry_reader_gui::init, stx_software_framework=stx_software_framework, scenario=scenario, filename=filename

  ; Store the main gui object as part of this object
  if isa(stx_software_framework) then self.stx_software_framework = stx_software_framework

  ; Initialize the base class
  a = self->stx_gui_base::init()
  
  
  ; Get the content widget id
  self.base_content_widget = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  self.base_button_bar_widget = self->stx_gui_base::get_button_bar_widget_id()
  
  self->set_scenario, scenario=scenario
  
  if isa(filename) then self.telemetry_file = filename else if isa(scenario) then self.telemetry_file = filepath("tmtc.bin",root_dir=self.scenario_name)
  
  
  
  self.plots = list()
 
  ; Create the widgets
  self->_create_widgets_telemetry_reader_gui, content_widget=self.base_content_widget, button_bar_widget=self.base_button_bar_widget
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  ; Start the xmanager
  self->_start_xmanager_data_simulation_gui
  
  
  ; Register self to the base for resizing
  self->stx_gui_base::set_object_for_resizing, obj=self
  
  ; Register the GUI to the software framework
  if isa(self.stx_software_framework) then self.stx_software_framework->register_telemetry_reader_gui, widget_id=self.base_widget_telemetry_reader_gui
  
  return, 1
end

;+
; :description:
;    Cleaning up the object
;
; :Params:
;    -
;
; :returns:
;    -
;    
; :history:
;    12-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    12-Mar-2015 - Roman Boutellier (FHNW), Added destruction of pointers
;-
pro stx_telemetry_reader_gui::cleanup

  if isa(self.stx_software_framework) then self.stx_software_framework->deregister_telemetry_reader_gui
  if isa(self.telemetry_reader) then destroy, self.telemetry_reader
  
end


;+
; :description:
; 	 This method creates all the widgets for the data simulation GUI.
;
; :Keywords:
;    scenario_name: in, required, type='string'
;       Name of the scenario to load
;    background: in, required, type='stx_sim_source'
;       Struct with data used to process the background
;    sources: in, required, type='[stx_sim_source]'
;       Array of source structs used to process the sources
;
; :returns:
;    -
;
; :history:
; 	 13-Nov-2014 - Roman Boutellier (FHNW), Initial release
; 	 05-Mar-2015 - Roman Boutellier (FHNW), - Added xsize to the widget bases for the background and the sources
; 	                                        - Changed ysize of the sources widget to 34 times the number of sources + some padding
; 	 12-Mar-2015 - Roman Boutellier (FHNW), - Added gap between background and sources
; 	                                        - Moved adding of background information to the _add_sources_widgets method
;-
pro stx_telemetry_reader_gui::_create_widgets_telemetry_reader_gui, content_widget=content_widget, button_bar_widget=button_bar_widget
                                                                  
  
  
  ; Create the top level base (i.e. the main window for this GUI)
  self.base_widget_telemetry_reader_gui = widget_base(content_widget, title='Telemetry Reader GUI', /column, uvalue=self, xsize=1200, ysize=650)
  
  widget_control, content_widget, TLB_SET_TITLE="STIX Telemetry Reader"
  
  widget_control, self.loadScenarioItem_id , set_value='Select Telemetry File', event_pro='stx_telemetry_reader_gui_select_file_handler'
  
  filename = "File: " + self.telemetry_file
  
  self.file_label = widget_label(self.base_widget_telemetry_reader_gui, uname='file_label', value=filename, /DYNAMIC_RESIZE, /align_left )
  start_button = widget_button(self.base_widget_telemetry_reader_gui,uname='read_button', value='Read Data', event_pro='stx_telemetry_reader_gui_read_file_event_handler')
    
  self.data_table = widget_table(self.base_widget_telemetry_reader_gui, COLUMN_WIDTHS=[550,75, 200, 200], column_labels=["Data", "IDX", "Start", "End"], $
    XSIZE=4, ysize=1, SCR_XSIZE=1180, SCR_YSIZE=550, uvalue="data_table", SENSITIVE=1, /RESIZEABLE_COLUMNS, /scroll, /all_events, /DISJOINT_SELECTION, event_pro='stx_telemetry_reader_gui_table_event_handler' )
    
  start_button = widget_button(self.base_widget_telemetry_reader_gui, uname='plot_button', value='Plot Data', event_pro='stx_telemetry_reader_gui_plot_data_event_handler')
   
  ;fsw_button = widget_button(button_bar_widget,uname='create_fsw_gui_button',value='Flight Software Simulator',event_pro='create_fsw_gui_event_handler')
end

pro stx_telemetry_reader_gui::plot_data
  table_selection = widget_info(self.data_table, /table_select)
  
  Widget_Control, /Hourglass
    
  rows = table_selection[1,*]
  rows = rows[UNIQ(rows, SORT(rows))]
  
  table_data = *(self.table_data)
  
  lc_plot = obj_new('stx_plot')
  
  energy_axis =  stx_construct_energy_axis()
  
  show_stx_state_plot = 0
  
  heartbeat = list()
  hk_maxi = list()
  hk_mini = list()
  
  foreach selected_row, rows do begin
      
    data_type = (table_data[selected_row]).type
    data_idx = (table_data[selected_row]).idx
    
     
    switch (data_type) of
      
      'stx_tmtc_ql_light_curves': begin
        self.telemetry_reader->getdata, asw_ql_lightcurve=ql_lightcurves, solo_packets=sp
        ql_lightcurve = stx_construct_lightcurve(from=ql_lightcurves[data_idx])
        
        show_stx_state_plot = 1
        rate_control = { $
          type      : "rcr" , $
          rcr       : ql_lightcurves[data_idx].RATE_CONTROL_REGIME, $
          time_axis : ql_lightcurve.time_axis $
        }
        
        ;ql_lightcurve.time_axis = stx_construct_time_axis(indgen(n_elements(ql_lightcurve.time_axis.duration)+1)*4)
        
        a = lc_plot.create_stx_plot(ql_lightcurve, /lightcurve, /add_legend, title="Lightcurve Plot", ylog=1)
        self.plots->add, lc_plot
        break
      end
      
      'stx_tmtc_ql_background_monitor': begin
        self.telemetry_reader->getdata, asw_ql_background=ql_background, solo_packets = sp
        ql_background = stx_construct_lightcurve(from=ql_background[data_idx])
        a = lc_plot.create_stx_plot(ql_background, /background, /add_legend, title="Lightcurve Plot")
        self.plots->add, lc_plot
        break
      end
      
      'stx_tmtc_ql_variance': begin
        self.telemetry_reader->getdata, asw_ql_variance  = variance_blocks
        variance = variance_blocks[data_idx]
        var_plot = stx_line_plot()
        a = lc_plot.add_stx_plot(var_plot._plot(stx_time_diff(variance.time_axis.time_start[0], variance.time_axis.time_start, /abs),  variance.variance, names=["variance"], /add_legend, /overplot)) 
        self.plots->add, var_plot
        break
      end
      
      'stx_tmtc_ql_calibration_spectrum': begin
        self.telemetry_reader->getdata, asw_ql_calibration_spectrum=calibration_spectra
        calibration_spectrum = calibration_spectra[data_idx]
        cs_plot = stx_energy_calibration_spectrum_plot()
        cs_plot->plot, calibration_spectrum, /add_legend, title="Energy Calibration Spectra"
        cs_plot->plot2, calibration_spectrum, /add_legend, title="Energy Calibration Spectra"
        ;cs_plot->plot3, calibration_spectrum, /add_legend, title="Energy Calibration Spectra"
        self.plots->add, cs_plot
        break
      end
      

      'stx_tmtc_ql_spectra': begin
        self.telemetry_reader->getdata, fsw_m_ql_spectra = ql_spectra, solo_packets=sp
        
        next = 0
        
        sp_sp = sp['stx_tmtc_ql_spectra',data_idx,0]
        sp_sp_next = sp['stx_tmtc_ql_spectra',data_idx+next,0]
        
        ql_spec = ql_spectra[data_idx]
        ql_spec_next = ql_spectra[data_idx+next]
        
        ptim, ql_spec.start_time.value, ql_spec_next.start_time.value
        print, stx_time_diff(ql_spec.start_time, ql_spec_next.start_time)
        
      
        stx_telemetry_util_time2scet, coarse_time=sp_sp.COARSE_TIME , fine_time=sp_sp.FINE_TIME, stx_time_obj=st_pa, /reverse_step
        stx_telemetry_util_time2scet, coarse_time=sp_sp_next.COARSE_TIME , fine_time=sp_sp_next.FINE_TIME, stx_time_obj=st_pa_next, /reverse_step
        
        print, "packets times"
        ptim, st_pa.value, st_pa_next.value
        print, stx_time_diff(st_pa, st_pa_next)
        
        stx_telemetry_util_time2scet, coarse_time=(*sp_sp.source_data).coarse_time , fine_time=(*sp_sp.source_data).fine_time, stx_time_obj=st_da, /reverse_step
        stx_telemetry_util_time2scet, coarse_time=(*sp_sp_next.source_data).coarse_time , fine_time=(*sp_sp_next.source_data).fine_time, stx_time_obj=st_da_next, /reverse_step

        print, "data times"
        ptim, st_da.value, st_da_next.value
        print, stx_time_diff(st_da, st_da_next)
      
        
        help, ql_spec
        
        times = ql_spec.SAMPLES[uniq(ql_spec.SAMPLES.delta_time)].delta_time
        
        duration = ql_spec.integration_time
        
        
        
        foreach time, times, t_idx do begin
          
          
          detectors_samples = ql_spec.SAMPLES[where(ql_spec.SAMPLES.delta_time eq time)]
          
          current_time = stx_time_add(ql_spec.start_time,seconds=time) 
          
          
          zero_detector_idx = where(total(detectors_samples.counts,1) eq 0, zero_detectors_cnt)
          
          ;if zero_detectors_cnt ne n_elements(detectors_samples.DETECTOR_INDEX) then begin
          ;  if zero_detectors_cnt ne 0 then message, "Spectra with Zero counts for detector detected: "+strjoin(trim(fix(detectors_samples[zero_detector_idx].DETECTOR_INDEX)+1), " "), /cont
          ;endif
          
          spectra_plot = obj_new('stx_spectra_plot')
          spectra_plot.plot, detectors_samples.counts, detectors_samples.DETECTOR_INDEX, current_time=current_time, duration=duration, $
            start_time=state_plot_start_time, /add_legend
          self.plots->add, spectra_plot
          
        endforeach

        break
       end

      'stx_tmtc_sd_aspect': begin
        self.telemetry_reader->getdata, fsw_m_sd_aspect=sd_aspect
        sd_aspect = sd_aspect[data_idx]
        
        help, sd_aspect
        
;        as_plot = stx_aspect_plot();
;        as_plot.plot, sd_aspect,  /add_legend, /histogram
        self.plots->add, as_plot
        
        break
      end
      
      'stx_tmtc_ql_flare_flag_location' : begin
        self.telemetry_reader->getdata, asw_ql_background=ql_background
        show_stx_state_plot = 1
        self.telemetry_reader->getdata, fsw_m_coarse_flare_locator=flare_locator_blocks, fsw_m_flare_flag=flare_flag_blocks, solo_packets=sp

        coarse_flare_location = flare_locator_blocks[data_idx]
        flare_flag = flare_flag_blocks[data_idx]

        state_plot_start_time = flare_flag.time_axis.time_start[0]

        break
      end
      
      'stx_tmtc_ql_flare_list' : begin
        self.telemetry_reader->getdata, asw_ql_flare_list=asw_ql_flare_list_blocks
        asw_ql_flare_list = asw_ql_flare_list_blocks[data_idx]

        print, asw_ql_flare_list

        break
      end
      
      'stx_tmtc_sd_xray_0': begin

        if ~isa(asw) then asw = obj_new('stx_analysis_software')

        self.telemetry_reader->getdata, fsw_archive_buffer_time_group=archive_buffer_blocks

        asw_data = stx_convert_fsw_archive_buffer_time_group_to_asw(archive_buffer_blocks[data_idx], energy_axis=energy_axis, datasource="TMTC: "+self.telemetry_file)

        ;pass the pixel data as the input for the analysis software object
        asw->setdata, asw_data.pixel_data

        ab_plot = stx_archive_buffer_plot();
        
        
        
        ab_plot_data = { $
          type: "", $
          time_axis : asw_data.time_axis, $
          TRIGGERS : {triggers : transpose(asw_data.triggers)},  $
          total_counts : total(total(total(asw_data.spec,1),1),1) $
        }

        ;ab_plot.plot, start_time=asw_data.time_axis.time_start[0], current_time= asw_data.time_axis.time_start[-1], archive_buffer=ab_plot_data, /add_legend, /histogram

        self.plots->add, ab_plot
        asw->set, module="global", max_reprocess_level = max([2,asw->get(/max_reprocess_level)])
        
        
        break
      end
      
      'stx_tmtc_sd_xray_1': begin
        if ~isa(asw) then asw = obj_new('stx_analysis_software')
        self.telemetry_reader->getdata, fsw_pixel_data_time_group=image_blocks
        
        all_pixel_data = stx_convert_fsw_pixel_data_time_group_to_asw(image_blocks[data_idx], energy_axis=energy_axis, datasource="TMTC: "+self.telemetry_file)
        
        ;pass the pixel data as the input for the analysis software object
        asw->setdata, all_pixel_data
        asw->set, module="global", max_reprocess_level = max([3,asw->get(/max_reprocess_level)])
        break
      end

      'stx_tmtc_sd_xray_2': begin
        if ~isa(asw) then asw = obj_new('stx_analysis_software')
        self.telemetry_reader->getdata, fsw_pixel_data_summed_time_group=image_blocks, solo_packets=solo_packets

        all_pixel_data = stx_convert_fsw_pixel_data_summed_time_group_to_asw(image_blocks[data_idx], energy_axis=energy_axis, datasource="TMTC: "+self.telemetry_file)

        ;pass the summed pixel data as the input for the analysis software object
        asw->set, module="global", max_reprocess_level = max([4,asw->get(/max_reprocess_level)])
        asw->setdata, all_pixel_data

        break
      end
      
      'stx_tmtc_sd_xray_3': begin
        if ~isa(asw) then asw = obj_new('stx_analysis_software')

        subc_str = stx_construct_subcollimator(asw->get(/subc_file))

        self.telemetry_reader->getdata, fsw_visibility_time_group=image_blocks, solo_packets=solo_packets
        
        all_vis_data = stx_convert_fsw_visibility_time_group_to_asw(image_blocks[data_idx], subc_str, energy_axis=energy_axis, datasource="TMTC: "+self.telemetry_file)
        
        ;pass the visibility bags into the analysis software object
        asw->set, module="global", max_reprocess_level = max([5,asw->get(/max_reprocess_level)])
        asw->setdata, all_vis_data

        break
      end
      
      'stx_tmtc_sd_spectrogram': begin
        self.telemetry_reader->getdata, fsw_spc_data_time_group=fsw_spc_data_time_group
        
        fsw_spc_data = fsw_spc_data_time_group[data_idx];
        
        n_time_bins = N_ELEMENTS(fsw_spc_data)
        
        boxStart = 0

        
        
        while boxStart lt n_time_bins do begin
          n_energies = n_elements(fsw_spc_data[boxStart].INTERVALS)
          boxEnd = boxStart
          while boxEnd lt n_time_bins-1 && n_elements(fsw_spc_data[boxEnd+1].INTERVALS) eq n_energies do boxEnd++
          
          print, "found spectrogramm box ", boxStart, boxEnd, n_energies 
          
          
          fsw_spc = fsw_spc_data[boxStart:boxEnd]->toarray()

          spectrogram = { $
            type          : "stx_fsw_sd_spectrogram", $
            counts        : fsw_spc.intervals.counts, $
            trigger       : fsw_spc.trigger, $
            time_axis     : stx_construct_time_axis([fsw_spc.start_time,fsw_spc[-1].end_time]) , $
            energy_axis   : stx_construct_energy_axis(select=where(fsw_spc[0].energy_bin_mask)), $
            pixel_mask    : fsw_spc.pixel_mask $
          }
          
          root_dir = self.scenario_name
          if strlen(root_dir) le 0 then  cd, CURRENT= root_dir
          
           
          
          srmfilename = filepath("stx_spectrum_srm_"+trim(data_idx)+"_box_"+trim(boxStart)+".fits",root_dir=root_dir)
          specfilename = filepath("stx_spectrum_"+trim(data_idx)+"_box_"+trim(boxStart)+".fits",root_dir=root_dir)

          ospex_obj =   stx_fsw_sd_spectrogram2ospex(spectrogram , /fits, specfilename=specfilename, srmfilename=srmfilename  )
          self.plots->add, ospex_obj
          
          
          boxStart=boxEnd+1
        endwhile
        break
      end
     
      'stx_tmtc_hc_heartbeat' : begin
        if ~isa(asw_hc_heartbeat_packets) then self.telemetry_reader->getdata, solo_packets = solo_packets, asw_hc_heartbeat=asw_hc_heartbeat_packets 
        
        heartbeat->add, asw_hc_heartbeat_packets[data_idx]
        
        break
      end
       
      'stx_tmtc_hc_regular_mini' : begin
        self.telemetry_reader->getdata, solo_packets = solo_packets, asw_hc_regular_mini = asw_hc_regular_mini_packets

        hk_mini ->add, asw_hc_regular_mini_packets[data_idx]

        break
      end  
      
      'stx_tmtc_hc_regular_maxi' : begin
        self.telemetry_reader->getdata, solo_packets = solo_packets, asw_hc_regular_maxi = asw_hc_regular_maxi_packets

        hk_maxi ->add, asw_hc_regular_maxi_packets[data_idx]

        break
      end
      
      'stx_tmtc_hc_trace' : begin
        self.telemetry_reader->getdata, solo_packets = solo_packets, asw_hc_trace = asw_hc_trace_packets

        hc_trace =  asw_hc_trace_packets[data_idx]
        
        print, hc_trace.tracetext
        

        break
      end
         
      else: begin
        print, data_type
      end
    endswitch

  endforeach
  
  
  if n_elements(heartbeat) gt 0 then begin
      hb_plot = stx_line_plot()
      nt = n_elements(heartbeat)
      heartbeat = heartbeat->toarray()
      
      a = hb_plot->_plot(lindgen(nt), stx_time2any(heartbeat.time)- stx_time2any(heartbeat[0].time), xtitle="heardbeat#", ytitle="at seconds ", title="heardbeat since: " + stx_time2any(heartbeat[0].time, /ecs), ylog=0)
      self.plots->add, hb_plot
    
  endif
  
  if (n_elements(hk_maxi) + n_elements(hk_min)) gt 0 then begin

  endif
 
  
  if isa(asw) then begin
    ;asw->set, module="global", max_reprocess_level=max_reprocess_level
    print, "start pixel_data_viewer with asw max_reprocess_level: ", asw->get(/max_reprocess_level)
    stx_pixel_data_viewer, asw
  endif
  
  if show_stx_state_plot then begin
    
    state_plot_object = obj_new('stx_state_plot')
    
    ;if isa(flare_flag) AND isa(rate_control) then rate_control.time_axis = flare_flag.time_axis
    
    current_time = isa(flare_flag) ? flare_flag.time_axis.time_start[-1] : rate_control.time_axis.time_start[-1]
    state_plot_start_time = isa(flare_flag) ? flare_flag.time_axis.time_start[0] : rate_control.time_axis.time_start[0]
    
    state_plot_object.plot, flare_flag=flare_flag, rate_control=rate_control, current_time=current_time, $
      start_time=state_plot_start_time, coarse_flare_location=coarse_flare_location, dimensions=[1260,350], /add_legend, current_window = window()
      
    self.plots->add, state_plot_object
  endif
  
  
end

pro stx_telemetry_reader_gui::read_telemetry, stream=stream

  if ~isa(stream) && ~file_exist(self.telemetry_file) then return
  
  Widget_Control, /Hourglass
  
  if isa(self.telemetry_reader) then begin
    ; destroy reader object
    destroy, self.telemetry_reader
  end
  
  self.telemetry_reader = isa(stream) ? stx_telemetry_reader(stream=stream, /scan_mode) : stx_telemetry_reader(filename=self.telemetry_file, /scan_mode)
  
  ; getdata
  self.telemetry_reader->getdata, statistics = statistics
  
  data = list()
  
  foreach datatype, statistics.keys() do $
    foreach dataentry, statistics[datatype], idx do $
      data->add, {type : datatype, idx : idx, start_time : dataentry.start_time, NBR_OF_PACKETS : dataentry.NBR_OF_PACKETS} 

  
  
  nd = n_elements(data)
  
  data = [data->toarray()]
  
  self.table_data = ptr_new(data)
  widget_control, self.data_table, set_value=data, table_ysize=nd
  
    
end


pro stx_telemetry_reader_gui_read_file_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->read_telemetry
end

pro stx_telemetry_reader_gui_table_event_handler, event
  return
  widget_control, event.top, get_uvalue=owidget
  
end


pro stx_telemetry_reader_gui_select_file_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_select_file
end

pro stx_telemetry_reader_gui_plot_data_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->plot_data
end


;+
; :description:
;    This method realizes the widget hierarchy for the data simulation GUI.
;
; :Keywords:
;    -
;
; :returns:
;    -
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_telemetry_reader_gui::_realize_widgets_data_simulation_gui
  
  ; Realize the widget hierarchy
  widget_control, self.base_widget_data_simulation_gui, /realize
end


;+
; :description:
; 	 Starting the xmanager which handles all clicks in the ui and forwards them to
; 	 the according event handlers.
;
; :returns:
;
; :history:
; 	 12-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_telemetry_reader_gui::_start_xmanager_data_simulation_gui
  xmanager, 'stx_telemetry_reader_gui', self.base_widget_telemetry_reader_gui, /no_block, cleanup='stx_telemetry_reader_gui_cleanup'
end

pro stx_telemetry_reader_gui_cleanup, base_widget_data_simulation_gui
  widget_control, base_widget_data_simulation_gui, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_telemetry_reader_gui, base_widget_telemetry_reader_gui
  endif
end

pro stx_telemetry_reader_gui::_cleanup_widgets_telemetry_reader_gui, base_widget_telemetry_reader_gui
  obj_destroy, self
end

;+
; :description:
;    This procedure handles the resize events of the top level base.
;    It is called by the stx_gui_base upon resizing the tlb.
;
; :history:
;    02-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_telemetry_reader_gui::_handle_resize_events
  ; Get the geometry data of the top level base
      return 
      
      
  tlb_geometry = self->stx_gui_base::get_tlb_geometry()
  ; Calculate the new x- and y-sizes of the content widget (differences result from the
  ; space the contents of the gui base take)
  new_x_content = tlb_geometry.xsize - 6
  new_y_content = tlb_geometry.ysize - 60
  
  ; Get the default and minimal values for the sizes
  default_minimal_sizes = self->_get_sizes_widgets()

  ; The x-size is not resizable, so in every case just reset the default size
;  if new_x_content lt default_minimal_sizes.minimal_sizes.ds_base_widget_x then begin
    ; Set the x-size of the content base widget to the minimal size
    widget_control, self.base_widget_telemetry_reader_gui, xsize=default_minimal_sizes.minimal_sizes.ds_base_widget_x
    
    return 
    ; Set all other needed x sizes
    ;widget_control, self.scenario_area_widget, xsize=default_minimal_sizes.minimal_sizes.DS_BASE_WIDGET_X
    ;widget_control, self.background_area_widget, xsize=default_minimal_sizes.minimal_sizes.ds_background_area_x
    ;widget_control, self.sources_area_widget, xsize=default_minimal_sizes.minimal_sizes.ds_sources_area_x

  ; Set the y size. To do so, just set the y sizes of the two tables.
  minimal_background_y = default_minimal_sizes.minimal_sizes.ds_table_background_y
  minimal_sources_y = default_minimal_sizes.minimal_sizes.ds_table_sources_y
  minimal_total_y = minimal_background_y + minimal_sources_y + 30
  if new_y_content lt minimal_total_y then begin
    ; Set the y-size to the minimal size
    widget_control, self.background_table_widget_id, scr_ysize=minimal_background_y
    widget_control, self.sources_table_widget_id, scr_ysize=minimal_sources_y
;    widget_control, self.base_widget_data_simulation_gui, ysize=default_minimal_sizes.minimal_sizes.ds_base_widget_y
;    widget_control, self.sources_area_widget, ysize=default_minimal_sizes.minimal_sizes.ds_sources_area_y
  endif else begin
    new_background_y = (new_y_content-30)/4
    new_sources_y = ((new_y_content-30)/4)*3
    ; Check that the new background is not bigger than the whole list
    if new_background_y gt self.table_background_default_y then new_background_y = self.table_background_default_y
    ; Set the new_sources_y
    if new_sources_y + new_background_y lt (new_y_content-30) then new_sources_y = (new_y_content-30) - new_background_y
    ; Check that the new source is not bigger than the whole list
    if new_sources_y gt self.table_sources_default_y then new_sources_y = self.table_sources_default_y
    
    ; Set the y-size to the new size
    widget_control, self.background_table_widget_id, scr_ysize=new_background_y
    widget_control, self.sources_table_widget_id, scr_ysize=new_sources_y
      
    ; Set the new y-size
;    widget_control, self.base_widget_data_simulation_gui, ysize=new_y_content
;    widget_control, self.sources_area_widget, ysize=new_y_content-60
  endelse
end


pro stx_telemetry_reader_gui::_handle_select_file, scenario=scenario
  sFile = dialog_pickfile(PATH=self.scenario_name, TITLE='Select Telemetry File',  FILTER='*.bin')
  
  if isa(sFile) then begin
    self.telemetry_file = sFile
    widget_control, self.file_label, set_value = ("File: "+(sFile))
  endif
end

;+
; :description:
; 	 Set the scenario and update the according label.
;
; :Keywords:
;    scenario, in, required, type=String
;     The name of the scenario
;
; :returns:
;
; :history:
; 	 21-Jan-2015 - Roman Boutellier (FHNW), Initial release
; 	 09-Feb-2015 - Roman Boutellier (FHNW), Added updating of scenario name in stx_software_framework
; 	 24-Feb-2015 - Roman Boutellier (FHNW), Now adding the "OK"s to the sources in case the scenario has already been simulated
; 	 26-Feb-2015 - Roman Boutellier (FHNW), Moved all the commands (except setting the scenario in the stx_software_framework) to the new
; 	                                        method 'update_gui_after_selecting_scenario'. This function will be called from the stx_software_framework.
;-
pro stx_telemetry_reader_gui::set_scenario, scenario=scenario
  if isa(scenario) then self.scenario_name = scenario
  sFile = filepath("tmtc.bin",root_dir=scenario)
  if file_exist(sFile) then begin
    self.telemetry_file = sFile
    if (self.file_label gt 0) then widget_control, self.file_label, set_value = ("File: "+sFile)
  endif
  
end

function stx_telemetry_reader_gui::get_scenario
  return, self.scenario_name
end


;+
; :description:
;    The default and minimal sizes for all the GUI parts are stored in this function.
;    It returns a struct containing two structs with the values, one for default values
;    and one for minimal values.
;
; :returns:
;   struct
;   
; :history:
;    01-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_telemetry_reader_gui::_get_sizes_widgets
  base_y = self.base_widget_telemetry_reader_gui_y_size
  x_size_base = 471
  base_y = 200
  ; Return a struct which contains the default and minimal sizes of the different parts of the gui
  sizes_struct = { $
    default_sizes: { $
      ds_base_widget_x: x_size_base, $
      ds_base_widget_y: base_y $
     }, $
    minimal_sizes: { $
      ds_base_widget_x: x_size_base, $
      ds_base_widget_y: base_y $
    } $
  }
  
  return, sizes_struct
end

pro stx_telemetry_reader_gui__define
  compile_opt idl2
  
  define={stx_telemetry_reader_gui, $
    stx_software_framework: obj_new(), $
    base_widget_telemetry_reader_gui: 0L, $
    base_widget_telemetry_reader_gui_y_size: 0L, $
    base_content_widget: 0L, $
    base_button_bar_widget: 0L, $
    scenario_area_widget: 0L, $
    scenario_name: '', $
    label_scenario_name: '', $
    output_path: '', $
    out_scen_file: '', $
    file_label: 0L, $
    data_table: 0L, $
    telemetry_file:'', $
    table_data: ptr_new(), $
    telemetry_reader : obj_new(), $
    plots : list(), $
    inherits stx_gui_base $
  }
end