;+
; :file_comments:
;   This is the base class for scneario-based testing of flight software modules
;   The input directory for scenario file definitions and dss/fsw configuration files
;   is constructed relative to $STX_SCN_TEST using the test type (e.g. 'basic') and
;   the test name (e.g. 'calib_spec_acc'). The output directory for the simulated
;   detector events is set to $SSW_STIX/../scenario_test (i.e. outside the STIX code directory)
;
; :categories:
;   data simulation, software, testing
;
; :examples:
;   Not to be used directly
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   30-Jun-2015 - Laszlo I. Etesi (FHNW), added rcr handler to the flight software run routine
;   10-May-2016 - Laszlo I. Etesi (FHNW), updated routine to work with new structures
;-

;+
; :description:
;   this function initialises this module
;
; :keywords:
;   keep_detector_eventlist : in, optional, type='boolean', default='1b'
;     if set to 1, the original data from previous simulations are kept, otherwise they are deleted
;
;   show_fsw_plots : in, optional, type='boolean', default='1b'
;     if set to 1, the flight software simulator will display the plot planes (lightcurves, detector health, etc.)
;     
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_scenario_test::init, keep_detector_eventlist=keep_detector_eventlist, show_fsw_plots=show_fsw_plots
  default, keep_detector_eventlist, 1b
  default, show_fsw_plots, 1b
  
  self.keep_detector_eventlist = keep_detector_eventlist
  self.show_fsw_plots = show_fsw_plots

  self.base_test_input_dir = getenv('STX_SCN_TEST')
  self.base_test_output_dir = concat_dir(getenv('SSW_STIX'), concat_dir('..', 'scenario_test'))

  ; DO NOT CHANGE AFTER THIS LINE
  self.test_input_dir = concat_dir(concat_dir(self.base_test_input_dir, self.test_type), self.test_name)

  if(~file_exist(self.test_input_dir)) then message, "Test input directory '" + self.test_input_dir + "' does not exist"
  return, self->iut_test::init()
end

;+
; :description:
;   this procedure cleans this module up
;-
pro stx_scenario_test::cleanup
  self->iut_test::cleanup
end

;+
; :description:
;   this procedure runs the test setup, the data simulation (default mode) and the flight software simulator
;   (default mode)
;-
pro stx_scenario_test::beforeclass
  self->_setup_test

  self->_setup_test_environment

  self->_run_data_simulation

  self->_run_flight_software_simulator
end

;+
; :description:
;   cleanup
;-
pro stx_scenario_test::afterclass
  ;destroy, self.dss
  ;destroy, self.fsw
  fsw = self.fsw
  save, fsw, filename=filepath("fsw.sav",root_dir=self.test_output_dir) 
end

;+
; :description:
;   this procedure sets up the environment (currently: deletion of old data if desired)
;-
pro stx_scenario_test::_setup_test_environment
  ; clean old test data
  if(file_exist(self.test_output_dir) && ~self.keep_detector_eventlist) then begin
    message, "Test output directory '" + self.test_output_dir + "' exists. Deleting old data", /informational
    file_delete, self.test_output_dir, /recursive
  endif

  ; creating test output directory
  mk_dir, self.test_output_dir
end

;+
; :description:
;   this procedure creates a new data simulation object; if a user configuration is present
;   that configuration will be applied
;
; :keywords:
;   dss_user_config : in, optional, type='string'
;     a valid file pointer to a user configuration for the data simulation
;-
pro stx_scenario_test::_setup_dss, dss_user_config=dss_user_config
  if(ppl_typeof(dss_user_config, compareto='string')) then begin
    configuration_manager =  stx_configuration_manager(configfile=dss_user_config)
    self.dss = obj_new('stx_data_simulation', configuration_manager)
  endif else self.dss = obj_new('stx_data_simulation')
  
  self.dss->set, math_error_level=0
end

;+
; :description:
;   this procedure creates a new flight software simulator object; if a user configuration is present
;   that configuration will be applied
;
; :keywords:
;   fsw_user_config : in, optional, type='string'
;     a valid file pointer to a user configuration for the flight software simulator
;-
pro stx_scenario_test::_setup_fsw, fsw_user_config=fsw_user_config, _extra=extra
  if(ppl_typeof(fsw_user_config, compareto='string')) then begin
    configuration_manager =  stx_configuration_manager(configfile=fsw_user_config)
    self.fsw = obj_new('stx_flight_software_simulator', configuration_manager, start_time=stx_construct_time(time=0), _extra=extra)
  endif else self.fsw = obj_new('stx_flight_software_simulator', start_time=stx_construct_time(time=0), _extra=extra)
  
  self.fsw->set, math_error_level=0
end

;+
; :description:
;   this procedure searches the input directory for user configuration (dss/fsw) and one scenario file and
;   configures this test class
;-
pro stx_scenario_test::_setup_test
  ; find all user configurations
  user_configurations = find_file(concat_dir(self.test_input_dir, '*.xml'))

  ; find dss user configuration
  dss_user_config_idx = where(stregex(user_configurations, 'stx_data_simulation_user.xml') ge 0, dss_user_count)

  ; find fsw user configuration
  fsw_user_config_idx = where(stregex(user_configurations, 'stx_flight_software_simulator_user.xml') ge 0, fsw_user_config_count)

  ; create dss user configuration
  if(dss_user_count gt 0) then dss_user_config = user_configurations[dss_user_config_idx]
  self->_setup_dss, dss_user_config=dss_user_config

  ; create fsw user configuration
  if(fsw_user_config_count gt 0) then fsw_user_config = user_configurations[fsw_user_config_idx]
  self->_setup_fsw, fsw_user_config=fsw_user_config 

  ; set the scenario file
  self.scenario_file = find_file(concat_dir(self.test_input_dir, '*.csv'))
  
  self.scenario_name = file_basename(self.scenario_file, '.csv')

  if(n_elements(self.scenario_file) ne 1) then message, 'Please provide only one scenario file per test'
  
  self.dss->set, ds_target_output_directory=self.base_test_output_dir

  self.test_output_dir = self.dss->getdata(scenario_file=self.scenario_file, output_target='scenario_output_path')
end

;+
; :description:
;   this procedure runs the data simulation
;-
pro stx_scenario_test::_run_data_simulation
  result = self.dss->getdata(scenario_file=self.scenario_file)
end

;+
; :description:
;   this procedure runs the flight software simulator (iterative call on the data simualtion to 
;   retrieve data).
;-
pro stx_scenario_test::_run_flight_software_simulator
  
  
  if FILE_TEST(filepath("fsw.sav",root_dir=self.test_output_dir)) then begin
    
    print, "Found old FSW.sav skip rerun of FSW simulation. Delete the fsw.sav to force for reprocessing"
    restore, filename=filepath("fsw.sav",root_dir=self.test_output_dir), /ver, /relaxed_structure_assignment
    self.fsw = fsw
    return
  endif

  if(self.show_fsw_plots) then fsw_p = stx_fsw_plot(self.fsw, /archive, /states, /det, /lightcurve )

  ; set default rate control state and coarse flare row (0 for top, 1 for bottom)
  rcr = 0
  coarse_flare_row = 0b

  no_time_bins = long(self.dss->getdata(scenario_name=self.scenario_name, output_target='scenario_length') / 4d)
  
  for time_bin = 0L, no_time_bins - 1 do begin
    
    ; Check the rcr state
    self.fsw->getproperty, current_rcr = rate_control_str
    rcr = rate_control_str.rcr
    
    ds_result_data = self.dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=self.scenario_name, rate_control_regime=rcr)
    
    if(ds_result_data eq !NULL) then continue

    ; Quickfixes (to be removed later)
    ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0d, 4d])
    ds_result_data.triggers.time_axis = stx_construct_time_axis([0d, 4d])
    
    ; Process the interval and plot
    self.fsw->process, ds_result_data.filtered_eventlist, ds_result_data.triggers, total_source_counts=ds_result_data.total_source_counts;, plotting=self.show_fsw_plots
    
    self.fsw->getproperty, stx_fsw_m_rate_control=rate_control_str
    
    ; Check the rcr state
    rcr = rate_control_str.rcr
    
    
    ;TODO: N.H. moce to top of loop?
    ; If the rcr state is 2, 3 or 4, half of the pixels will be used, so determine whether to use top or bottom row
    if rcr gt 1 and rcr lt 5 then begin
      self.fsw->getproperty, stx_fsw_m_coarse_flare_location=coarse_flare_location, /complete, /combine
      cfl = dblarr(n_elements(coarse_flare_location.x_pos), 2)
      cfl[*, 0] = coarse_flare_location.x_pos
      cfl[*, 1] = coarse_flare_location.y_pos
      ;check if there are any valid locations (also checks if none have been generated yet)
      ;coarse_flare_row is assigned 0 (top) if the y-value of the cfl is below zero, and
      ;1 (bottom) if the y-value of the cfl is above zero  
      if total(finite(cfl)) ne 0 then coarse_flare_row = ((cfl)[-1,1] lt 0) ? 1: 0 
    endif
    
    ; Update all plots
    ;if(self.show_fsw_plots) then fsw_p->plot, /arch, /dete, /light, /states
  endfor
end

pro stx_scenario_test::GetProperty ,$
  dss=dss, $
  fsw=fsw, $
  test_name=test_name , $
  test_type=test_type, $
  scenario_file=scenario_file, $
  scenario_name=scenario_name, $
  base_test_input_dir=base_test_input_dir, $
  base_test_output_dir=base_test_output_dir, $
  test_input_dir=test_input_dir, $
  test_output_dir=test_output_dir, $
  keep_detector_eventlist=keep_detector_eventlist, $
  show_fsw_plots=show_fsw_plots
  
  COMPILE_OPT IDL2

  ; If "self" is defined, then this is an "instance".
  IF (ISA(self)) THEN BEGIN
    ; User asked for an "instance" property.
    IF arg_present(dss)                     THEN dss = self.dss
    IF arg_present(fsw)                     THEN fsw = self.fsw
    IF arg_present(test_name)               THEN test_name = self.test_name
    IF arg_present(test_type)               THEN test_type = self.test_type
    IF arg_present(scenario_file)           THEN scenario_file = self.scenario_file
    IF arg_present(scenario_name)           THEN scenario_name = self.scenario_name
    IF arg_present(base_test_input_dir)     THEN base_test_input_dir = self.base_test_input_dir
    IF arg_present(base_test_output_dir)    THEN base_test_output_dir = self.base_test_output_dir
    IF arg_present(test_input_dir)          THEN test_input_dir = self.test_input_dir
    IF arg_present(test_output_dir)         THEN test_output_dir = self.test_output_dir
    IF arg_present(keep_detector_eventlist) THEN keep_detector_eventlist = self.keep_detector_eventlist
    IF arg_present(show_fsw_plots)          THEN show_fsw_plots = self.show_fsw_plots
  end
end


pro stx_scenario_test__define
  compile_opt idl2, hidden

  void = { $
    stx_scenario_test, $
    dss:                      obj_new(), $
    fsw:                      obj_new(), $
    test_name:                '', $
    test_type:                '', $
    scenario_file:            '', $
    scenario_name:            '', $
    base_test_input_dir:      '', $
    base_test_output_dir:     '', $
    test_input_dir:           '', $
    test_output_dir:          '', $
    keep_detector_eventlist:  0b, $
    show_fsw_plots:           0b, $
    inherits iut_test }
end
