;+
; :file_comments:
;    This is the main gui for STIX which provides the user the possibility
;    to start the data simulation gui.
;    TODO: Extend description
;
; :categories:
;    software, gui
;
; :examples:
;    stx_sw_gui = obj_new('software_framework')
;
; :history:
;    06-Nov-2014 - Roman Boutellier (FHNW), initial release
;    12-Nov-2014 - Roman Boutellier (FHNW), renamed to stx_software_framework__define
;-

;+
; :description:
;    This function initialises this module and is called automatically when creating
;    a stx_software_framework object.
;    It creates the software framework GUI.
;
; :params:
;    -
;    
; :returns:
;    -
;
; :history:
;    06-Nov-2014 - Roman Boutellier (FHNW), initial release
;    02-Jun-2015 - Roman Boutellier (FHNW), Added registration to base for resizing
;-
function stx_software_framework::init

  ; Set the widget ids of the differen GUIs to -1
  self.data_simulation_gui_widget_id = -1L
  self.flight_software_simulator_gui_widget_id = -1L
  self.energy_calibration_spectra_gui_widget_id = -1L
  self.telemetry_reader_gui_widget_id = -1L

  ; Set the default scenario name
  self.scenario_name = 'stx_scenario_1'
  
  ; Initialize the base class
  a = self->stx_gui_base::init()
  
  ; Get the content widget id
  content_widget = self->stx_gui_base::get_content_widget_id()
  
  ; Create the widgets
  self->_create_widgets_software_framework, content_widget_id=content_widget
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  ; Start the xmanager
  self->_start_xmanager_software_framework
  
  ; Register self to the base for resizing
  self->stx_gui_base::set_object_for_resizing, obj=self
  
  return, 1
end

;+
; :description:
; 	 Cleanup method of the object. This method is called on destruction
; 	 of the object and also cleans up all the objects which are part
; 	 of this object.
;
; :returns:
;    -
;
; :history:
; 	 06-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::cleanup
  compile_opt idl2
  
  obj_destroy, [self.data_simulation_gui, self.flight_software_simulator_gui]
end

pro stx_software_framework::_create_widgets_software_framework, content_widget_id=content_widget_id

  font = 'Times*25*Italic*Bold'

  ; Create the top level base widget
  self.base_widget_software_framework = widget_base(content_widget_id,title='STIX Software', /column, xsize=300, ysize=400, uvalue=self)
  ; Add the area to hold the buttons
  simulation_area = widget_base(self.base_widget_software_framework, uname='simulation_area', xsize=290, ysize=180, /column, frame=2)
  ; Add the buttons
  simlabel = widget_label(simulation_area, uname='simlabel', value=' Data Simulation ', font=font, /align_left )
  button_data_sim = widget_button(simulation_area, uname='button_data_sim', value='Source Data Simulation', event_pro='button_data_sim_event_handler')
  button_fsw = widget_button(simulation_area, uname='button_fsw', value='Flight Software Simulation', event_pro='button_fsw_event_handler')
  
  analyses_area = widget_base(self.base_widget_software_framework, uname='analyses_area', xsize=290, ysize=180, /column, frame=2)
  analabel = widget_label(analyses_area, uname='simlabel', value=' Data Analytics ', font=font, /align_left )
  
  button_tm = widget_button(analyses_area, uname='button_tm', value='Telemetry Reader', event_pro='button_tm_event_handler')

  
  
  ;button_hk = widget_button(analyses_area, uname='button_hk', value='STIX HK Plots', event_pro='button_hk_event_handler')
  ;button_energy_calibration = widget_button(analyses_area, uname='button_energy_calibration', value='Energy Calibration Spectra', event_pro='button_energy_calibration_spectra_event_handler')
end

pro stx_software_framework::_realize_widgets_software_framework
  widget_control, self.base_widget_software_framework, /realize
end

pro stx_software_framework::_start_xmanager_software_framework
  xmanager, 'stx_software_framework', self.base_widget_software_framework, /no_block, cleanup='stx_software_framework_cleanup'
end

pro stx_software_framework_cleanup, base_widget_software_framework
  widget_control, base_widget_software_framework, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_software_framework, base_widget_software_framework
  endif
end

pro stx_software_framework::_cleanup_widgets_software_framework, base_widget_software_framework
  obj_destroy, self
end

;+
; :description:
;    This procedure handles the resize events of the top level base.
;    It is called by the stx_gui_base upon resizing the tlb.
;    The main GUI of the STIX Software Framework should not be resizable
;    (it already has a small size) and therefore only the default size
;    is restored upon resizing.
;
; :history:
;    02-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::_handle_resize_events
  ; Restore the default size
  widget_control, self.base_widget_software_framework, xsize=300
  widget_control, self.base_widget_software_framework, ysize=400
end

pro button_data_sim_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_data_simulation
end

pro stx_software_framework::_handle_data_simulation
  ; Create the data simulation gui
  self->create_data_simulation_gui
end

pro button_fsw_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_fsw
end

pro stx_software_framework::_handle_fsw
  ; Create the data simulation gui
  self->create_flight_software_simulation_gui
end

pro button_hk_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_hk
end

pro stx_software_framework::_handle_hk
  ; Create the data simulation gui
  self->create_hk_plots_gui
end



pro button_tm_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_telemetry_reader
end

pro stx_software_framework::_handle_telemetry_reader
  ; Create the energy telemetry reader gui
  self->create_telemetry_reader_gui
end

pro button_energy_calibration_spectra_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_energy_calibration
end

pro stx_software_framework::_handle_energy_calibration
  ; Create the energy calibration spectra gui
  self->create_energy_calibration_spectra_gui
end

pro stx_software_framework::create_data_simulation_gui
  ; Create the data simulation gui. If already a data simulation gui has been created, set
  ; the focus to that gui.
  if (self.data_simulation_gui_widget_id eq -1L) then begin
    self.data_simulation_gui = obj_new('stx_data_simulation_gui', self, scenario=self.scenario_name)
  endif else begin
    widget_control, self.data_simulation_gui_widget_id, /show
  endelse
end

;+
; :description:
; 	 Register the data simulation gui by passing the widget id of the GUI.
;    This id is stored within this object and can be used to check, if already
;    a data simulation GUI exists.
;
; :Keywords:
;    widget_id, in, required, type='Long'
;       The widget id of the created data simulation GUI
;       
; :returns:
;    -
;    
; :history:
; 	 17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::register_data_simulation_gui, widget_id=widget_id
  self.data_simulation_gui_widget_id = widget_id
end

;+
; :description:
; 	 Set the focus to the data simulation gui.
;
; :returns:
;
; :history:
; 	 19-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::focus_data_simulation_gui
  widget_control, self.data_simulation_gui_widget_id, /show
end

pro stx_software_framework::hide_data_simulation_gui
;  widget_control, self.data_simulation_gui_widget_id, map=0
end

;+
; :description:
;    Deregister the data simulation gui. This sets the according entry in this object
;    to -1.
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
pro stx_software_framework::deregister_data_simulation_gui
  self.data_simulation_gui_widget_id = -1L
end

;+
; :description:
; 	 Create the flight software simulation gui. In case it already exists, put the
; 	 focus to the gui.
;
; :returns:
;    -
;
; :history:
; 	 17-Nov-2014 - Roman (FHNW), Initial release
;-
pro stx_software_framework::create_flight_software_simulation_gui
  ; Create the fsw simulation gui. If already a fsw simulation gui has been created, set
  ; the focus to that gui.
  if (self.flight_software_simulator_gui_widget_id eq -1L) then begin
    self.flight_software_simulator_gui = obj_new('stx_flight_software_simulator_gui', stx_software_framework=self)
  endif else begin
    widget_control, self.flight_software_simulator_gui_widget_id, /show
  endelse
end

pro stx_software_framework::focus_flight_software_simulation_gui
  widget_control, self.flight_software_simulator_gui_widget_id, /show
end

;+
; :description:
;    Register the flight software simulation gui by passing the widget id of the GUI.
;    This id is stored within this object and can be used to check, if already
;    a flight software simulation GUI exists.
;
; :Keywords:
;    widget_id, in, required, type='Long'
;       The widget id of the created flight software simulation GUI
;       
; :returns:
;    -
;    
; :history:
;    17-Nov-2014 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::register_fsw_simulation_gui, widget_id=widget_id
  self.flight_software_simulator_gui_widget_id = widget_id
end

;+
; :description:
;    Deregister the flight software simulation gui. This sets the according entry in this object
;    to -1.
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
pro stx_software_framework::deregister_fsw_simulation_gui
  self.flight_software_simulator_gui_widget_id = -1L
end

;+
; :DESCRIPTION:
;    Create the telemetry reader gui. In case it already exists, put the
;    focus to the gui.
;
; :RETURNS:
;    -
;
; :HISTORY:
;    03-Nov-2016 - Nicky Hochmuth (FHNW), Initial release
;-
pro stx_software_framework::create_telemetry_reader_gui
  ; Create the telemetry reader gui. If already a telemetry reader gui has been created, set
  ; the focus to that gui.
  if (self.telemetry_reader_gui_widget_id eq -1L) then begin
    self.telemetry_reader_gui = obj_new('stx_telemetry_reader_gui', stx_software_framework=self, scenario=self->get_scenario())
  endif else begin
    widget_control, self.telemetry_reader_gui_widget_id, /show
  endelse
end

;+
; :description:
;    Create the energy calibration spectra gui. In case it already exists, put the
;    focus to the gui.
;
; :returns:
;    -
;
; :history:
;    15-Jun-2015 - Roman (FHNW), Initial release
;-
pro stx_software_framework::create_energy_calibration_spectra_gui
  ; Create the energy calibration spectra gui. If already a energy calibration spectra gui has been created, set
  ; the focus to that gui.
  if (self.energy_calibration_spectra_gui_widget_id eq -1L) then begin
    self.energy_calibration_spectra_gui = obj_new('stx_energy_calibration_spectra_gui', stx_software_framework=self)
  endif else begin
    widget_control, self.energy_calibration_spectra_gui_widget_id, /show
  endelse
end

pro stx_software_framework::focus_energy_calibration_spectra_gui
  widget_control, self.energy_calibration_spectra_gui_widget_id, /show
end


;+
; :DESCRIPTION:
;    Register the telemetry reader gui by passing the widget id of the GUI.
;    This id is stored within this object and can be used to check, if already
;    a telemetry reader GUI exists.
;
; :KEYWORDS:
;    widget_id, in, required, type='Long'
;       The widget id of the created telemetry reader GUI
;
; :RETURNS:
;
; :HISTORY:
;    03-Nov-2016 - Nicky Hochmuth (FHNW), Initial release
;-
pro stx_software_framework::register_telemetry_reader_gui, widget_id=widget_id
  self.telemetry_reader_gui_widget_id = widget_id
end

;+
; :DESCRIPTION:
;    Deregister the telemetry reader gui. This sets the according entry in this object
;    to -1.
;
; :KEYWORDS:
;    -
;
; :RETURNS:
;    -
;
; :HISTORY:
;    03-Nov-2016 - Nicky Hochmuth (FHNW), Initial release
;-
pro stx_software_framework::deregister_telemetry_reader_gui
  self.telemetry_reader_gui_widget_id = -1L
end

;+
; :description:
; 	 Opens a new gui window with an example for the hk plots
;
; :returns:
;
; :history:
; 	 26-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::create_hk_plots_gui
  hk_gui = obj_new('stx_hk_test_gui')
end

function stx_software_framework::get_gui
  if (self.data_simulation_gui eq !NULL) then begin
    ; No data simulation gui has been created yet
    self->create_data_simulation_gui
  endif else begin
  endelse
  return, self.data_simulation_gui
end

function stx_software_framework::get_dss
  dss_gui = self->get_gui()
  return, dss_gui->get_dss()
end


;+
; :description:
; 	 This method stores a given scenario name within the object.
;
; :Keywords:
;    scenario, in, required, type='string'
;       The name of the scenario to store
;
; :returns:
;    -
;    
; :history:
; 	 26-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_software_framework::set_scenario, scenario=scenario
  self.scenario_name = scenario
  ; Update the scenario name in the stx_flight_software_simulator_gui (in case it exists)
  if self.flight_software_simulator_gui_widget_id gt 0 then self.flight_software_simulator_gui->update_scenario_name_label, new_scenario_name=scenario
  ; Update the scenario data in the stx_data_simulation_gui (in case it exists)
  if self.data_simulation_gui_widget_id gt 0 then self.data_simulation_gui->update_gui_after_selecting_scenario, scenario=scenario
  
  if self.telemetry_reader_gui_widget_id gt 0 then self.telemetry_reader_gui->set_scenario, scenario=scenario
end

;+
; :description:
; 	 This function returns the scenario name of the object
;
; :returns:
;    'string': Scenario name of the object
;
; :history:
; 	 26-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_software_framework::get_scenario
  return, self.scenario_name
end


;+
; :description:
; 	 This method handles a click on the "Load Scenario" entry of the menu bar.
;
; :Keywords:
;    callback_object, in, required
;
; :returns:
;
; :history:
; 	 28-Jan-2015 - Roman Boutellier (FHNW), Initial release
; 	 25-Feb-2015 - Roman Boutellier (FHNW), Added keyword "selected_scenario" to the creation of the selection window
;-
pro stx_software_framework::handle_load_scenario_click, callback_object=callback_object
  selected_scenario = obj_new('stx_gui_select_scenario_window',calling_stx_software_framework=self,selected_scenario=self.scenario_name)
end

;+
; :description:
; 	 Checks if the actually selected scenario has already been simulated.
;
; :returns:
;    1 if the actually selected scenario has already been simulated, 0 otherwise.
;    
; :history:
; 	 18-Feb-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_software_framework::is_scenario_simulated
  if self.scenario_name eq '' then begin
    return, 0
  endif else begin
    ; Check if a data simulation gui has already been created and do so if not
    if (self.data_simulation_gui eq !NULL) then begin
      ; No data simulation gui has been created yet
      self->create_data_simulation_gui
    endif
    return, self.data_simulation_gui->is_already_simulated(scenario_name=self.scenario_name)
  endelse
end

pro stx_software_framework__define
  compile_opt hidden, idl2
  
  define = { stx_software_framework, $
    base_widget_software_framework: 0l, $
    data_simulation_gui: obj_new(), $
    data_simulation_gui_widget_id: -1L, $
    flight_software_simulator_gui: obj_new(), $
    flight_software_simulator_gui_widget_id: -1L, $
    energy_calibration_spectra_gui: obj_new(), $
    energy_calibration_spectra_gui_widget_id: -1L, $
    telemetry_reader_gui: obj_new(), $
    telemetry_reader_gui_widget_id: -1L, $
    scenario_name: '', $
    inherits stx_gui_base $
  }
end