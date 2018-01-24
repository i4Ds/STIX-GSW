;+
; :file_comments:
;    this is the data simulation gui.
;    
; :categories:
;    data simulation, software, gui
;    
; :examples:
;    ds_gui = obj_new('stx_data_simulation_gui')
;    
; :history:
;    12-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    23-Jan-2014 - Roman Boutellier (FHNW), Adapted to change from stx_data_simulation2 to stx_data_simulation
;    09-Feb-2015 - Roman Boutellier (FHNW), List of sources is now cleaned before the new list is created (after selecting a scenario).
;                                           Therefore a new field has been added to the object which stores all the widget ids of the
;                                           sources.
;-

;+
; :description:
; 	 This function initializes the object. It is called automatically upon creation of the object.
;
; :Params:
;    stx_software_framework, in, required, type='stx_software_framework'
;       The software framework object (used to be able to pass data to other modules within the framework)^
;    scenario, in, optional, type=string
;       The name of the scenario which will be simulated. Default is stx_scenario_1
;
; :returns:
;
; :history:
; 	 12-Nov-2014 - Roman Boutellier (FHNW), Initial release
; 	 23-Jan-2015 - Roman Boutellier (FHNW), - Changed data simulation from stx_data_simulation2 to stx_data_simulation
; 	                                        - Replaced _read_scenario by _prepare_scenario
;    26-Jan-2015 - Roman Boutellier (FHNW), The name of the scenario is now loaded directly from the base class in case there has been no scenario passed
;    09-Feb-2015 - Roman Boutellier (FHNW), Added initialization of pointer to the array of source sub widget ids
;    24-Feb-2015 - Roman Boutellier (FHNW), Now adding ticks to the sources in case the scenario has already been simulated
;-
function stx_data_simulation_gui::init, stx_software_framework, scenario=scenario

  ; Store the main gui object as part of this object
  self.stx_software_framework = stx_software_framework
  
  ; Create a new stx data simulation
  self.stx_data_simulation = obj_new('stx_data_simulation')
  
  ; Initialize the base class
  a = self->stx_gui_base::init()
  
  ; Initialize the ptr to the array of source sub widget ids
  self.sources_sub_widgets_ids = ptr_new(!NULL)
  
  ; Get the content widget id
  self.base_content_widget = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  self.base_button_bar_widget = self->stx_gui_base::get_button_bar_widget_id()
  
  ; Set the default scenario
  self.scenario_name = isa(scenario) ? scenario : self.stx_software_framework->get_scenario()
  
  ; Load the scenario
  src_str_split = self->_load_scenario()
  ; Store the number of sources
  self.nmbr_of_sources =  size(src_str_split,/n_elements)
  
  ; Create the widgets
  self->_create_widgets_data_simulation_gui, content_widget=self.base_content_widget, button_bar_widget=self.base_button_bar_widget, $
                                              scenario_name=self.scenario_name, background=*self.bg_str, sources=*self.src_str, splitted_sources=src_str_split
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  ; Start the xmanager
  self->_start_xmanager_data_simulation_gui
  
  
  ; Register self to the base for resizing
  self->stx_gui_base::set_object_for_resizing, obj=self
  
  ; Register the GUI to the software framework
  self.stx_software_framework->register_data_simulation_gui, widget_id=self.base_widget_data_simulation_gui
  
  ; Add the ticks to the sources in case the scenario has already been simulated
  already_simulated = self->is_already_simulated(scenario_name=self.scenario_name)
  if already_simulated gt 0 then self->_add_oks_to_all_sources
  
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
pro stx_data_simulation_gui::cleanup

  self.stx_software_framework->deregister_data_simulation_gui
  
  ptr_free, self.sources_label_names
  ptr_free, self.sources_sub_widgets_ids
  ptr_free, self.src_str
  ptr_free, self.bg_str
  ptr_free, self.subc_str
end

;+
; :description:
; 	 Loads a scenario by first reading it, storing the returned data in the object and then
; 	 splitting the sources and storing the splitted sources in the object.
; 	 
; :returns:
;    An array of stx_sim_source_structure (the splitted sources)
;
; :history:
; 	 23-Jan-2015 - Roman Boutellier (FHNW), Initial release
;    26-Jan-2015 - Roman Boutellier (FHNW), Call of _read_scenario now gets the name of the scenario directly from the base class
;-
function stx_data_simulation_gui::_load_scenario
  ; Check if the scenario name which is stored is just the name of a scenario or a path to a scenario file.
  ; In case it is a path, use scenario_file in the _read_scenario procedure, otherwise use scenario_name
  scenario_name_or_path = self.stx_software_framework->get_scenario()
  if strpos(scenario_name_or_path, '.csv') eq -1 then begin
    ; The scenario stored is a name
    ; Load the scenario and store the according structs etc
    self.stx_data_simulation->_read_scenario, scenario_name=scenario_name_or_path, out_sources=sources_str, out_bkg_sources=bkg_sources_str
  endif else begin
    ; The scenario stored is a path
    ; Load the scenario and store the according structs etc
    self.stx_data_simulation->_read_scenario, scenario_file=scenario_name_or_path, out_sources=sources_str, out_bkg_sources=bkg_sources_str
  endelse
  self.src_str = ptr_new(sources_str)
  self.bg_str = ptr_new(bkg_sources_str)
;  self.out_scen_file = scenario_file
  
  ; Prepare subc_str
  self.subc_str = ptr_new(stx_construct_subcollimator())
  
  ; Split the sources
  src_str_split = stx_sim_split_sources(sources=*self.src_str, max_photons=10L^7, $
    subc_str=*self.subc_str, all_drm_factors=all_drm_factors, drm0=drm0 )

  if src_str_split eq !NULL then self.sources_label_names = ptr_new(strarr(n_elements(0))) else $
  self.sources_label_names = ptr_new(strarr(n_elements(src_str_split)))
  
  return, src_str_split
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
pro stx_data_simulation_gui::_create_widgets_data_simulation_gui, content_widget=content_widget, button_bar_widget=button_bar_widget, scenario_name=scenario_name, $
                                                                  background=background, sources=sources, splitted_sources=splitted_sources
  ; Get the number of sources
  number_of_sources = n_elements(splitted_sources)
  ; Split up the background and set the number of background sources
  splitted_background_sources = stx_sim_split_sources(sources=background, max_photons=10L^7, $
      subc_str=*self.subc_str, /background)
  self.nmbr_of_background_sources = n_elements(splitted_background_sources)
  
  
  ; Create the top level base (i.e. the main window for this GUI)
  self.base_widget_data_simulation_gui = widget_base(content_widget, title='Data Simulation GUI', /column, uvalue=self);, xsize=560, ysize=(number_of_sources * 34 + 110)
  
  ; Add the area for the scenario to the top level base
  self.scenario_area_widget = widget_base(self.base_widget_data_simulation_gui, uname='scenario_area', /row);, xsize=550, ysize=20
  ; Add the scenario label and the place to put the name of the scenario
  label_scenario = widget_label(self.scenario_area_widget, uname='label_scenario', xsize=50, ysize=15, /align_left, value='Scenario: ')
  self.label_scenario_name = widget_label(self.scenario_area_widget, uname='label_scenario_name', xsize=250, ysize=15, /align_left, value=file_basename(self.scenario_name,'.csv'))
  
  ; Add the area for the background
  self.background_area_widget = widget_base(self.base_widget_data_simulation_gui, uname='background_area', /column, frame=1);, xsize=550, ysize=35
  
  ; Add a small widget which creates a gap between background and sources
  gap_widget = widget_base(self.base_widget_data_simulation_gui, uname='gap_area', xsize=250, ysize=5)
  
  ; Add the area for the list of sources
  self.sources_area_widget = widget_base(self.base_widget_data_simulation_gui, uname='sources_area', /column, frame=1);, xsize=550, ysize=(number_of_sources * 34+10)
  ; Add the sources
  self->_add_sources_widgets, nmbr_of_sources=number_of_sources, splitted_sources=splitted_sources, $
                              nmbr_of_background_sources=self.nmbr_of_background_sources, splitted_background_sources=splitted_background_sources

  ; Add the button to start calculating the data
  start_button = widget_button(button_bar_widget,uname='run_data_simulation_button', value='Run', event_pro='run_data_simulation_event_handler')
  fsw_button = widget_button(button_bar_widget,uname='create_fsw_gui_button',value='Flight Software Simulator',event_pro='create_fsw_gui_event_handler')
end


;+
; :description:
; 	 This method creates the widgets which show the different sources of a scenario.
;
; :Keywords:
;    nmbr_of_sources, in, required, type='Integer'
;       The total number of sources to be displayed
;    splitted_sources, in, required, type='[stx_sim_source]'
;       Array of stx_sim_sources (the splitted sources)
;
; :returns:
;       -
;
; :history:
; 	 23-Jan-2015 - Roman Boutellier (FHNW), Initial release
; 	 09-Feb-2015 - Roman Boutellier (FHNW), - Bugfixing
; 	                                        - Sources area is now cleaned before its content is created
;    05-Mar-2015 - Roman Boutellier (FHNW), - Changed ysize of the sources widget to 34 times the number of sources + some padding
;    12-Mar-2015 - Roman Boutellier (FHNW), Now also deleting and adding the background part of the GUI
;    02-Jun-2015 - Roman Boutellier (FHNW), The minimal y-sizes are now stored at the end of this procedure (use later when resizing)
;    17-Jun-2015 - Roman Boutellier (FHNW), - Added keywords nmbr_of_background_sources and splitted_background_sources to support background with several sub ids
;                                           - Started implementation of using list instead of creating a widget for every entry
;-
pro stx_data_simulation_gui::_add_sources_widgets, nmbr_of_sources=nmbr_of_sources, splitted_sources=splitted_sources, $
                                                    nmbr_of_background_sources=nmbr_of_background_sources, splitted_background_sources=splitted_background_sources
  ;-------------------------------------------------------------
  ;                     Background sources                     -
  ;-------------------------------------------------------------
  ; Delete the old table if necessary
  if self.background_table_widget_id gt 0 then widget_control, self.background_table_widget_id, /destroy
  
  ; Only add the background table in case there are any background sources
  if nmbr_of_background_sources gt 0 then begin
    ; Prepare the value arrays for the background sources
    value_array_bg = make_array(6, nmbr_of_background_sources, /string)
    ; Add all the needed values to the array
    for i=0, nmbr_of_background_sources-1 do begin
      current_background_source = splitted_background_sources[i]
      value_array_bg[0,i] = '-'
      value_array_bg[1,i] = strtrim(fix(current_background_source.source_id),2)
      value_array_bg[2,i] = strtrim(fix(current_background_source.source_sub_id),2)
      value_array_bg[3,i] = strtrim(current_background_source.start_time,2)
      value_array_bg[4,i] = strtrim(current_background_source.duration,2)
      value_array_bg[5,i] = strtrim(current_background_source.flux,2)
    endfor
    
    
    ; Set the height of the table. In case there are less than 5 rows, set the height to the number of rows.
    ; If there are more than 5 rows, set the height to number_of_rows * 21 + 25. Thereby the maximum is 150
    ; (afterwards, the table must be scrolled).
    if nmbr_of_background_sources le 5 then begin
      table_height_rows_bg = nmbr_of_background_sources
      ; Add the table with the sources
      self.background_table_widget_id = widget_table(self.background_area_widget, value=value_array_bg, column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                      /no_row_headers, ysize=table_height_rows_bg, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
      self.table_background_default_y = (widget_info(self.background_table_widget_id, /geometry)).scr_ysize
    endif else begin
      table_height_pixel_bg = nmbr_of_background_sources * 21 + 25
      if table_height_pixel_bg gt 500 then table_height_pixel_bg = 500
      self.table_background_default_y = table_height_pixel_bg
      ; Add the table with the sources
      self.background_table_widget_id = widget_table(self.background_area_widget, value=value_array_bg, column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                      /no_row_headers, scr_ysize=table_height_pixel_bg, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
    endelse
                                                    
    ; Deselect the selected cell
    widget_control, self.background_table_widget_id, set_table_select=[-1,-1,-1,-1]
  endif else begin
    ; Add an empty table
    self.background_table_widget_id = widget_table(self.background_area_widget, value=[], column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                    /no_row_headers, ysize=1, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
    self.table_background_default_y = (widget_info(self.background_table_widget_id, /geometry)).scr_ysize
    ; Deselect the selected cell
    widget_control, self.background_table_widget_id, set_table_select=[-1,-1,-1,-1]
  endelse
  
  ;-------------------------------------------------------------
  ;                      Scenario sources                      -
  ;-------------------------------------------------------------
  ; Delete the old table if necessary
  if self.sources_table_widget_id gt 0 then widget_control, self.sources_table_widget_id, /destroy
  
  ; Only add the sources table in case there are any background sources
  if nmbr_of_sources gt 0 then begin
    ; Prepare the value arrays for the sources
    value_array = make_array(6, nmbr_of_sources, /string)
    ; Add all the needed values to the array
    for i=0, nmbr_of_sources-1 do begin
      current_source = splitted_sources[i]
      value_array[0,i] = '-'
      value_array[1,i] = strtrim(fix(current_source.source_id),2)
      value_array[2,i] = strtrim(fix(current_source.source_sub_id),2)
      value_array[3,i] = strtrim(current_source.start_time,2)
      value_array[4,i] = strtrim(current_source.duration,2)
      value_array[5,i] = strtrim(current_source.flux,2)
    endfor
    
    ; Set the height of the table. In case there are less than 20 rows, set the height to the number of rows.
    ; If there are more than 20 rows, set the height to number_of_rows * 21 + 25. Thereby the maximum
    ; is 500 (afterwards, the table must be scrolled)
    if nmbr_of_sources le 20 then begin
      table_height_rows = nmbr_of_sources
      ; Add the table with the sources
      self.sources_table_widget_id = widget_table(self.sources_area_widget, value=value_array, column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                      /no_row_headers, ysize=table_height_rows, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
      self.table_sources_default_y = (widget_info(self.sources_table_widget_id, /geometry)).scr_ysize
    endif else begin
      table_height_pixel = nmbr_of_sources * 21 + 25
      if table_height_pixel gt 500 then table_height_pixel = 500
      self.table_sources_default_y = table_height_pixel
      ; Add the table with the sources
      self.sources_table_widget_id = widget_table(self.sources_area_widget, value=value_array, column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                      /no_row_headers, scr_ysize=table_height_pixel, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
    endelse
                                                    
    ; Deselect the selected cell
    widget_control, self.sources_table_widget_id, set_table_select=[-1,-1,-1,-1]
  endif else begin
    ; Add an empty table
    self.sources_table_widget_id = widget_table(self.sources_area_widget, value=[], column_labels=['Simulated', 'Source ID', 'Source Sub-ID', 'Start Time', 'Duration', 'Flux'], $
                                                      /no_row_headers, ysize=1, xsize=6, column_widths=[60,60,80,70,80,90], alignment=0);, sensitive=0
    self.table_sources_default_y = (widget_info(self.sources_table_widget_id, /geometry)).scr_ysize
    ; Deselect the selected cell
    widget_control, self.sources_table_widget_id, set_table_select=[-1,-1,-1,-1]
  endelse
  
;  ; Delete the content of the sources area (if needed)
;  if *self.sources_sub_widgets_ids ne !NULL then begin
;    for s=0, size(*self.sources_sub_widgets_ids,/n_elements)-1 do begin
;      widget_control, (*self.sources_sub_widgets_ids)[s], /destroy
;    endfor
;  endif
;  ; Delete the background content
;  if self.background_content_widget gt 0 then begin
;    widget_control, self.background_content_widget, /destroy
;    self.background_content_widget = 0
;  endif
;  ; Set the ysize of the base_widget_data_simulation_gui
;  widget_control, self.base_widget_data_simulation_gui, ysize=(nmbr_of_sources * 34 + 110)
;  ; Set the ysize of the sources_area_widget
;  widget_control, self.sources_area_widget, ysize=(nmbr_of_sources * 34 + 10)
;  
;  ; Create the array which will store the ids of the sources sub widgets
;  ptr_free, self.sources_sub_widgets_ids
;  if nmbr_of_sources le 0 then self.sources_sub_widgets_ids = ptr_new(0) else $
;  self.sources_sub_widgets_ids = ptr_new(make_array(nmbr_of_sources))
;  
;  ; Add the background content
;  self.background_content_widget = widget_base(self.background_area_widget, uname='background_content_widget', xsize=540, ysize=30, /row)
;  ; Add the area for the OK
;  self.background_ok_area_widget = widget_base(self.background_content_widget, uname='background_tick_area', xsize=30, ysize=30)
;  self.background_ok_label = widget_label(self.background_ok_area_widget, uname='background_ok_label', value='', xsize=30, ysize=30)
;  ; Add a widget base for the label with the content 'Background...'
;  background_label_widget = widget_base(self.background_content_widget, uname='background_label_widget', xsize=450, ysize=30)
;  ; Add the background label and the place to put the green tick
;  label_background = widget_label(background_label_widget, uname='background_scenario', xsize=400, ysize=30, /align_left, value='Background...')
;  
;  ; Add the sources
;  for i = 0L, nmbr_of_sources-1 do begin
;    name_label = 'source_label_area_'+strtrim(i,2)
;    label_sub_area = widget_base(self.sources_area_widget, uname=name_label, xsize=540, ysize=30, /row)
;    ; Store the id of the source
;    (*self.sources_sub_widgets_ids)[i] = label_sub_area
;    ; Add the area for the green tick
;    name_tick_area = 'source_tick_area_' + strtrim(i,1)
;    (*self.sources_label_names)[i] = name_tick_area
;    source_tick_area = widget_base(label_sub_area, uname=name_tick_area);, xsize=30, ysize=30)
;    ok_label = widget_label(source_tick_area, uname='source_ok_label_' + strtrim(i,2), value='', xsize=30, ysize=30)
;    ; Add the label with all the information about the source
;    label_source = widget_label(label_sub_area, uname='source_label_'+strtrim(i,2), xsize=500, ysize=30, /align_left, $
;        value='Source ID: ' + strtrim(fix(splitted_sources[i].source_id),2) + ', Source Sub-ID: ' + strtrim(fix(splitted_sources[i].source_sub_id),2) + ', Start Time: ' +$
;        strtrim(fix(splitted_sources[i].start_time),2) + ', Duration: ' + strtrim(fix(splitted_sources[i].duration),2) +$
;        ', Flux: ' + strtrim(long(splitted_sources[i].flux),2))
;  endfor
;  
;  ; Store the y-sizes for the base and the sources area
;  self.base_widget_data_simulation_gui_y_size = nmbr_of_sources * 34 + 100
;  self.sources_area_widget_y_size = nmbr_of_sources * 34 + 10
end


;+
; :description:
; 	 Adds the text 'OK' to all labels within the gui (i.e. the background and all the sources)
;
; :returns:
;
; :history:
; 	 25-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_data_simulation_gui::_add_oks_to_all_sources
  ; Add the ticks to the background sources
  for i=0, self.nmbr_of_background_sources-1 do begin
    self->_background_finished,index=i
  endfor
  
  ; Add the ticks to the sources
  for i = 0L, self.nmbr_of_sources-1 do begin
    self->_source_finished,index=i
  endfor
  
  ; Set the scenario to 'already simulated'
  self.scenario_already_simulated = 1
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
pro stx_data_simulation_gui::_realize_widgets_data_simulation_gui
  
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
pro stx_data_simulation_gui::_start_xmanager_data_simulation_gui
  xmanager, 'stx_data_simulation_gui', self.base_widget_data_simulation_gui, /no_block, cleanup='stx_data_simulation_gui_cleanup'
end

pro stx_data_simulation_gui_cleanup, base_widget_data_simulation_gui
  widget_control, base_widget_data_simulation_gui, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_data_simluation_gui, base_widget_data_simulation_gui
  endif
end

pro stx_data_simulation_gui::_cleanup_widgets_data_simluation_gui, base_widget_data_simulation_gui
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
pro stx_data_simulation_gui::_handle_resize_events
  ; Get the geometry data of the top level base
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
    widget_control, self.base_widget_data_simulation_gui, xsize=default_minimal_sizes.minimal_sizes.ds_base_widget_x
    ; Set all other needed x sizes
    widget_control, self.scenario_area_widget, xsize=default_minimal_sizes.minimal_sizes.ds_scenario_area_x
    widget_control, self.background_area_widget, xsize=default_minimal_sizes.minimal_sizes.ds_background_area_x
    widget_control, self.sources_area_widget, xsize=default_minimal_sizes.minimal_sizes.ds_sources_area_x
    ; Go over all sources and set the x sizes
;    all_sources = *self.sources_sub_widgets_ids
;    for i=0,size(all_sources,/n_elements)-1 do begin
;      widget_control, all_sources[i], xsize=default_minimal_sizes.minimal_sizes.ds_source_label_area_x
;    endfor
;  endif else begin
;    ; Set the x-size of the content base widget to the new size
;    widget_control, self.base_widget_data_simulation_gui, xsize=new_x_content
;    ; Set all other needed x sizes
;    widget_control, self.scenario_area_widget, xsize=new_x_content
;    widget_control, self.background_area_widget, xsize=new_x_content
;    widget_control, self.sources_area_widget, xsize=new_x_content
;    ; Go over all sources and set the x sizes
;    all_sources = *self.sources_sub_widgets_ids
;    for i=0,size(all_sources,/n_elements)-1 do begin
;      widget_control, all_sources[i], xsize=new_x_content
;    endfor
;  endelse
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

;+
; :description:
;    This is the event handler for the click event of the run button.
;
; :Keywords:
;    event: in, required, type='widget_button'
;       The click-event
;
; :returns:
;    -
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro run_data_simulation_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_run_data_simulation
end

;+
; :description:
;    The method called by the event handler of the run button.
;    It processes all the background and sources of the selected scenario.
;
; :Keywords:
;    -
;
; :returns:
;    -
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    23-Jan-2015 - Roman Boutellier (FHNW), - Changed _process_background to _run_background_simulation
;                                           - Changed _process_source to _run_source_simulation
;                                           - Changed _finish_scenario to _wrapup_scenario
;    26-Jan-2015 - Roman Boutellier (FHNW), - Call of _prepare_scenario now gets the name of the scenario directly from the base class
;                                           - Call of _wrapup_scenario now does not use the keyword scenario_file anymore
;    11-Feb-2015 - Roman Boutellier (FHNW), Removed checking if the scenario has already been simulated and replaced it with the 'out_skip_sim'
;                                           parameter of the _prepare_scenario method which shows the same.
;    18-Jun-2015 - Roman Boutellier (FHNW), Background is now also splitted
;-
pro stx_data_simulation_gui::_handle_run_data_simulation

  ; Prepare the scenario
  self.stx_data_simulation->_prepare_scenario, scenario_name=self.stx_software_framework->get_scenario(), out_output_path=output_path, out_skip_sim=out_skip_sim, gui=1
  
  ; Depending on the value of the out_skip_sim parameter, remove the ok labels or abort running the simulation
  if out_skip_sim eq -1 then begin
    ; Abort running the simulation
    return
  endif else begin
    if ((out_skip_sim eq 1) || (out_skip_sim eq 2)) then begin
      ; The user wants to use the already simulated data. Therefore abort running the simulation
      return
    endif else begin
      if out_skip_sim eq 0 then begin
        ; The user wants to simulate the data. First remove the OK labels and then start the simulation
        self->_remove_ok_labels, number_of_sources=self.nmbr_of_sources
      endif else begin
        ; There has been an error in the _prepare_scenario method (while computing the out_skip_sim parameter)
        error_dialog = dialog_message('An error occured during preparation of the scenario.',/error)
        return
      endelse
    endelse
  endelse
;  ; In case the scenario has already been simulated, ask the user if it should be simulated again
;  ; (and therefore the previously simulated data will be deleted)
;  if self.scenario_already_simulated eq 1 then begin
;    simulate_scenario = dialog_message('The selected scenario has already been simulated. Would you like to simulate the scenario again?' + $
;                                        ' (ATTENTION: Simulating the scenario again will delete all the previously simulated data of this scenario.)',/question)
;                                        
;    if simulate_scenario eq 'No' then begin
;      return
;    endif else begin
;      ; Delete the old simulated data (in a first version, just rename the folder)
;      file_move, self.scenario_name, self.scenario_name + '_old'
;      ; Remove the 'OK' labels
;      self->_remove_ok_labels, self.nmbr_of_sources
;    endelse
;  endif else begin
;    ; The scenario has not yet been simulated, so continue
;  endelse
  
  self.output_path = output_path
  ; Split the background struct and then process the backgrounds
  if(ppl_typeof(*self.bg_str, compareto='stx_sim_source', /raw)) then begin
    bg_str_split = stx_sim_split_sources(sources=*self.bg_str, max_photons=10L^7, $
      subc_str=*self.subc_str, /background)
    ; Process the background
    for bg_idx = 0L, n_elements(bg_str_split)-1 do begin
      ; Extract current background
      curr_bg_str = bg_str_split[bg_idx]
      ; Generate data
      a = self.stx_data_simulation->_run_background_simulation(background_str=curr_bg_str, subc_str=*self.subc_str, output_path=self.output_path)
  
      ; Inidicate finished background
      self->_background_finished, index=bg_idx
    endfor
  endif
  
;  ; Load the image into the buffer
;  tick_image = file_which('done.png')
;  im_buffer = image(tick_image,/buffer)

  ; Split the sources struct and then process the sources
  if (isvalid(*self.src_str)) then src_str_split = stx_sim_split_sources( sources=*self.src_str, max_photons=10L^7, $
    subc_str=*self.subc_str, all_drm_factors=all_drm_factors, drm0=drm0 )
  
  for src_idx = 0L, n_elements(src_str_split)-1 do begin
    ; Extract current source
    curr_src_str = src_str_split[src_idx]
    ; generate data
    a = self.stx_data_simulation->_run_source_simulation(source=curr_src_str, subc_str=*self.subc_str, all_drm_factors=all_drm_factors, drm0=drm0, index=src_idx, output_path=self.output_path)
    
    ; Indicate finished source
    self->_source_finished, index=src_idx
  endfor

  ; Finish the scenario
;  a = self.stx_data_simulation->_wrapup_scenario(scenario_file=self.out_scen_file, output_path=self.output_path, source_str=*self.src_str)
  a = self.stx_data_simulation->_wrapup_scenario(output_path=self.output_path, source_str=*self.src_str)
  
  ; Set the value which indicates if the scenario has been simulated to 1
  self.scenario_already_simulated = 1
end

;+
; :description:
;    This method adds the text 'OK' to the background label in the GUI.
;    It is called after the processing of the background has been finished.
;
; :Keywords:
;    -
;
; :returns:
;    -
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    25-Feb-2015 - Roman Boutellier (FHNW), Changed from green tick to text 'OK' (as the green tick would have been stored in a
;                                           widget window which destroys the whole widget tree upon destruction and not only itself
;                                           and its children)
;    18-Jun-2015 - Roman Boutellier (FHNW), Changed from widget labels to table
;-
pro stx_data_simulation_gui::_background_finished, index=index
  ; Get the values
  widget_control, self.background_table_widget_id, get_value=values_background
  ; Change the simulated column of the correct row to 'OK'
  values_background[0,index] = 'OK'
  
  ; Prepare the color array
  current_bg_colors = widget_info(self.background_table_widget_id, /table_background_color)
  if ((size(values_background))[0]) eq 1 then begin
    nmbr_rows = 1
  endif else begin
    nmbr_rows = (size(values_background))[2]
  endelse
  if size(current_bg_colors, /n_elements) eq 3 then begin
    color_array = make_array(3,6, nmbr_rows, value=255)
  endif else begin
    color_array = current_bg_colors
  endelse
  ; Set the color of the complete row to green
  color_array[0,*,index] = 0
  color_array[1,*,index] = 255
  color_array[2,*,index] = 0
  
  ; Set the values and the color
  widget_control, self.background_table_widget_id, set_value=values_background
  widget_control, self.background_table_widget_id, background_color=color_array
  
  ; Get the label id and add the text
;  ok_label_id = widget_info(self.base_widget_data_simulation_gui, find_by_uname='background_ok_label')
;  widget_control, self.background_ok_label, set_value='OK'
end

;+
; :description:
;    This method adds a green tick to the source label with the given index.
;    It is called each time a source has been processed.
;
; :Keywords:
;    index: in, required, type='integer'
;       Index of the source that has been finished processing
;
; :returns:
;    -
;
; :history:
;    13-Nov-2014 - Roman Boutellier (FHNW), Initial release
;    25-Feb-2015 - Roman Boutellier (FHNW), Changed from green tick to text 'OK' (as the green tick would have been stored in a
;                                           widget window which destroys the whole widget tree upon destruction and not only itself
;                                           and its children)
;    18-Jun-2015 - Roman Boutellier (FHNW), Changed from widget labels to table
;-
pro stx_data_simulation_gui::_source_finished, index=index
  ; Get the values
  widget_control, self.sources_table_widget_id, get_value=values_sources
  ; Change the simulated column of the correct row to 'OK'
  values_sources[0,index] = 'OK'
  
  ; Prepare the color array
  current_bg_colors = widget_info(self.sources_table_widget_id, /table_background_color)
  if ((size(values_sources))[0]) eq 1 then begin
    nmbr_rows = 1
  endif else begin
    nmbr_rows = (size(values_sources))[2]
  endelse
  if size(current_bg_colors, /n_elements) eq 3 then begin
    color_array = make_array(3,6, nmbr_rows, value=255)
  endif else begin
    color_array = current_bg_colors
  endelse
  ; Set the color of the complete row to green
  color_array[0,*,index] = 0
  color_array[1,*,index] = 255
  color_array[2,*,index] = 0
  
  ; Set the values and the color
  widget_control, self.sources_table_widget_id, set_value=values_sources
  widget_control, self.sources_table_widget_id, background_color=color_array
;  ; Get the label id and add the text
;  uname_widget = 'source_ok_label_' + strtrim(index,2)
;  ok_label_id = widget_info(self.base_widget_data_simulation_gui, find_by_uname=uname_widget)
;  widget_control, ok_label_id, set_value='OK'
end

;+
; :description:
; 	 This method delets all the "OK" labels in front of the background and sources lines within the
; 	 data simulation gui. To do so, it replaces the text with an empty string.
;
; :Keywords:
;    number_of_sources, in, required, type='Integer'
;       The total number of sources for the selected scenario
;
; :returns:
;
; :history:
; 	 26-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_data_simulation_gui::_remove_ok_labels, number_of_sources=number_of_sources
  ; Delete the ok label of the background
;  ok_widget_id = widget_info(self.base_widget_data_simulation_gui, find_by_uname='background_ok_label')
  if self.background_ok_label gt 0 then widget_control, self.background_ok_label, set_value=''
  ; Delete all labels of the sources
  for i=0, number_of_sources-1 do begin
    ; Remove the ok label
    uname_widget = 'source_ok_label_' + strtrim(i,2)
    ok_label_id = widget_info(self.base_widget_data_simulation_gui, find_by_uname=uname_widget)
    if ok_label_id gt 0 then widget_control, ok_label_id, set_value=''
  endfor
end

;+
; :description:
;    This is the event handler for the click event of the fsw button.
;
; :Keywords:
;    event: in, required, type='widget_button'
;       The click-event
;
; :returns:
;    -
;
; :history:
;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro create_fsw_gui_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_create_fsw_gui
end

;+
; :description:
;    The method called by the event handler of the fsw button.
;    It starts a new fsw by calling the according method in the software framework
;
; :Keywords:
;    -
;
; :returns:
;    -
;
; :history:
;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_data_simulation_gui::_handle_create_fsw_gui
  self.stx_software_framework->create_flight_software_simulation_gui
end

function stx_data_simulation_gui::get_dss
  return, self.stx_data_simulation
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
pro stx_data_simulation_gui::set_scenario, scenario=scenario
  ; Update the scenario within the stx_software_framework
  self.stx_software_framework->set_scenario, scenario=scenario
end

function stx_data_simulation_gui::get_scenario
  return, self.scenario_name
end

;+
; :description:
; 	 Update the labels and set according data of the newly selected scenario
;
; :Keywords:
;    scenario, in, required, type='String'
;       Name of the newly selected scenario
;
; :returns:
;
; :history:
; 	 26-Feb-2015 - Roman Boutellier (FHNW), Initial release
; 	 10-Jun-2015 - Roman Boutellier (FHNW), Added support for scenario paths
;-
pro stx_data_simulation_gui::update_gui_after_selecting_scenario, scenario=scenario
  ; Store the scenario name
  self.scenario_name = scenario
  ; Update the scenario label
  scenario_label_name = file_basename(scenario, '.csv')
  widget_control, self.label_scenario_name, set_value=scenario_label_name
  ; Delete the ok label of the background
;  ok_widget_id = widget_info(self.base_widget_data_simulation_gui, find_by_uname='background_ok_label')
;  if self.background_ok_label gt 0 then widget_control, self.background_ok_label, set_value=' '
  ; Now load the new scenario
  splitted_sources = self->_load_scenario()
  ; Store the number of sources
  self.nmbr_of_sources =  size(splitted_sources,/n_elements)
  ; Split up the background and set the number of background sources
  splitted_background_sources = stx_sim_split_sources(sources=*self.bg_str, max_photons=10L^7, $
      subc_str=*self.subc_str, /background)
  self.nmbr_of_background_sources = n_elements(splitted_background_sources)
  ; Redraw the according widgets
  self->_add_sources_widgets, nmbr_of_sources=size(splitted_sources,/n_elements), splitted_sources=splitted_sources, $
                              nmbr_of_background_sources=self.nmbr_of_background_sources, splitted_background_sources=splitted_background_sources
  
  ; Add the ticks to the sources in case the scenario has already been simulated
  ; Check if the scenario keyword passed is a name or a path
  if strpos(scenario, '.csv') eq -1 then begin
    ; The scenario keyword is a name
    already_simulated = self.stx_data_simulation->test_output_path_emtpy(scenario_name=scenario, gui=1)
  endif else begin
    ; The scenario keyword is a path
    already_simulated = self.stx_data_simulation->test_output_path_emtpy(scenario_file=scenario, gui=1)
  endelse
  if already_simulated gt 0 then self->_add_oks_to_all_sources else self.scenario_already_simulated = 0
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
;    28-Jan-2015 - Roman Boutellier (FHNW), Initial release
;    25-Feb-2015 - Roman Boutellier (FHNW), Added keyword "selected_scenario" to the creation of the selection window
;-
pro stx_data_simulation_gui::handle_load_scenario_click, callback_object=callback_object
  scenario_selection_object = obj_new('stx_gui_select_scenario_window',calling_stx_software_framework=self,selected_scenario=self.scenario_name)
end


;+
; :description:
; 	 Returns 1 if the scenario has already been simulated, 0 otherwise.
; 	 To check if the scenario has been simulated, the folder where the simulated data
; 	 is stored is searched. In case the folder exists and is not empty, it is
; 	 assumed that the scenario has already been simulated.
;
; :Keywords:
;    scenario_name, in, required, type='String'
;
; :returns:
;    1 in case the scenario has already been simulated, 0 otherwise
;
; :history:
; 	 18-Feb-2015 - Roman Boutellier (FHNW), Initial release
; 	 26-Feb-2015 - Roman Boutellier (FHNW), If the scenario has not been simulated correctly in a last simulation (i.e. the file 'sources.fits' is missing),
; 	                                        the user is now asked if the previously created data shall be deleted.
;-
function stx_data_simulation_gui::is_already_simulated, scenario_name=scenario_name

  ; Read configuration structure
  conf = self.stx_data_simulation->get(module='data_simulation')
  ; Get the base output path
  base_output_path = conf.target_output_directory
  ; Prepare the output path
  scenario_output_path = concat_dir(base_output_path, scenario_name)
  
  ; Prepare the variable to store the return value
  files_found = 0
  
  ; Check if the folder exists
  void = file_search(scenario_output_path, count=folder_exists)
  if folder_exists eq 1 then begin
    ; Check if the folder is not empty
    ; Search for the sources.fits file in the folder
    void = file_search(scenario_output_path, 'sources.fits', count=count_file)
    if count_file gt 0 then begin
      files_found = 1
    endif else begin
      files_found = 0
      ; The simulation did not finish correctly, as the sources.fits file is missing.
      ; Therefore ask the user if the unfinished data can be deleted
       remove_incorrectly_finished_data = dialog_message('The previous simulation of the selected scenario has not finished correctly.' + $
                                        ' To be able to simulate the scenario again, the already created data products must be deleted.' + $
                                        ' Would you like to delete this data now?',/question)
                                        
      if remove_incorrectly_finished_data eq 'No' then begin
        ; Do nothing
      endif else begin
        ; Delete the old simulated data
        file_delete, self.scenario_name, /recursive
      endelse
    endelse
  endif else begin
    ; The folder does not exist, therefore return 0
    files_found = 0
  endelse

  self.scenario_already_simulated = files_found

  return, files_found
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
function stx_data_simulation_gui::_get_sizes_widgets
  base_y = self.base_widget_data_simulation_gui_y_size
  sources_y = self.sources_area_widget_y_size
  default_background_y = self.table_background_default_y
  default_sources_y = self.table_sources_default_y
  x_size_base = 471
  x_size_sub = 463
  ; Return a struct which contains the default and minimal sizes of the different parts of the gui
  sizes_struct = { $
    default_sizes: { $
      ds_base_widget_x: x_size_base, $
      ds_base_widget_y: base_y, $
      ds_scenario_area_x: x_size_sub, $
      ds_background_area_x: x_size_sub, $
      ds_sources_area_x: x_size_sub,$
      ds_sources_area_y: sources_y, $
      ds_source_label_area_x: x_size_sub, $
      ds_table_background_y: default_background_y, $
      ds_table_sources_y: default_sources_y $
    }, $
    minimal_sizes: { $
      ds_base_widget_x: x_size_base, $
      ds_base_widget_y: base_y, $
      ds_scenario_area_x: x_size_sub, $
      ds_background_area_x: x_size_sub, $
      ds_sources_area_x: x_size_sub,$
      ds_sources_area_y: sources_y, $
      ds_source_label_area_x: x_size_sub, $
      ds_table_background_y: 55, $
      ds_table_sources_y: 125 $
    } $
  }
  
  return, sizes_struct
end

pro stx_data_simulation_gui__define
  compile_opt idl2
  
  define={stx_data_simulation_gui, $
    stx_software_framework: obj_new(), $
    stx_data_simulation: obj_new(),$
    base_widget_data_simulation_gui: 0L, $
    base_widget_data_simulation_gui_y_size: 0L, $
    base_content_widget: 0L, $
    base_button_bar_widget: 0L, $
    scenario_area_widget: 0L, $
    sources_area_widget: 0L, $
    sources_area_widget_y_size: 0L, $
    background_area_widget: 0L, $
    background_content_widget: 0L, $
    background_ok_area_widget: 0L, $
    background_ok_label: 0L, $
    background_table_widget_id: 0L, $
    table_background_default_y: 0L, $
    nmbr_of_background_sources: 0L, $
    sources_sub_widgets_ids: ptr_new(), $
    sources_table_widget_id: 0L, $
    table_sources_default_y: 0L, $
    nmbr_of_sources: 0L, $
    scenario_name: '', $
    scenario_already_simulated: 0, $
    label_scenario_name: '', $
    src_str: ptr_new(), $
    bg_str: ptr_new(), $
    output_path: '', $
    subc_str: ptr_new(), $
    out_scen_file: '', $
    sources_label_names: ptr_new(), $
    inherits stx_gui_base $
  }
end