;+
; :file_comments:
;   This test class tests the data simulation's count reading and filtering
;   capabilities, particularly the 4s chunk-wise reading
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_dss_io__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_dss_io__test')
;
; :history:
;   18-Jul-2015 - Laszlo I. Etesi (FHNW), initial release
;-

;+
; :description:
;    this function initializes this module; make sure to adjust the variables "self.test_name" and "self.test_type";
;    they will control, where in $STX_SCN_TEST to look for this test's scenario and configuration files
;    (e.g. $STX_SCN_TEST/basic/calib_spec_acc)
;
; :keywords:
;   extra : in, optional
;     extra parameters interpreted by the base class (see stx_scenario_test__define)
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_scenario_dss_io__test::init, _extra=extra
  self.test_name = 'dss_io'
  self.test_type = 'basic'
  
  return, self->stx_scenario_test::init(_extra=extra)
end

;+
; :description:
;   ensure the flight software simulator is not called
;-
pro stx_scenario_dss_io__test::_run_flight_software_simulator
  return
end

;+
; :description:
;   this routine overrides the default beforeclass routine provided by the scenario test class;
;   it first calls stx_scenario_test::beforeclass and then starts readint and filtering all 
;   detector counts, and trigger list so that they can be easily compared in later test routines
;-
pro stx_scenario_dss_io__test::beforeclass
  self->stx_scenario_test::beforeclass
  
  ; read all data in using the DSS object
  no_time_bins = long(self.dss->getdata(scenario_name=self.scenario_name, output_target='scenario_length') / 4d)

  self.total_eventlist_4s_read = ptr_new([])
  self.total_filtered_eventlist_4s_read = ptr_new([])
  self.total_triggers_4s_read = ptr_new([])

  ; extract all data points from the dss
  ; store all events, filtered events, and triggers
  for time_bin = 0L, no_time_bins do begin
    ds_result_data = self.dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario_name=self.scenario_name, rate_control_regime=rcr_next_cycle, finalize_processing=(time_bin+1 eq no_time_bins))

    if(ds_result_data eq !NULL) then continue

    *self.total_eventlist_4s_read = [*self.total_eventlist_4s_read, ds_result_data.eventlist.detector_events]
    *self.total_filtered_eventlist_4s_read = [*self.total_filtered_eventlist_4s_read, ds_result_data.filtered_eventlist.detector_events]
    *self.total_triggers_4s_read = [*self.total_triggers_4s_read, ds_result_data.triggers.trigger_events]
  endfor

  ; call the filtering separately on the complete unfiltered eventlist
  self.total_filtered_eventlist = ptr_new(stx_sim_timefilter_eventlist(*self.total_eventlist_4s_read, triggers_out=total_triggers))
  self.total_triggers = ptr_new(total_triggers)
  
  ; now read the data using a data reader
  fits_det_event_reader = obj_new('stx_sim_detector_events_fits_reader_indexed', concat_dir(self.base_test_output_dir, self.scenario_name))
  self.total_eventlist_all_read = ptr_new(fits_det_event_reader->read(t_start=0, t_end=no_time_bins*4, /sort))
  destroy, fits_det_event_reader
  
  ; call the filtering separately on the complete unfiltered directly read eventlist
  self.total_filtered_eventlist_all_read = ptr_new(stx_sim_timefilter_eventlist(*self.total_eventlist_all_read, triggers_out=total_trigger_all_read))
  self.total_trigger_all_read = ptr_new(total_trigger_all_read)
end

;+
; :description:
;   this test compares the filtered counts, and the triggers from the DSS 4s-read-and-filter routine
;   with manually filtered counts, and triggers provided by the DSS (eventlist, as opposed to filtered eventlist) 
;-
pro stx_scenario_dss_io__test::test_4s_readout_with_total_readout
  ; calculate lengths
  len_total_filtered_eventlist = n_elements(*self.total_filtered_eventlist)
  len_total_filtered_eventslit_4s_read = n_elements(*self.total_filtered_eventlist_4s_read)
  len_total_trigger = n_elements(*self.total_triggers)
  len_total_trigger_4s_read = n_elements(*self.total_triggers_4s_read)
  
  ; compare lengths
  assert_equals, len_total_filtered_eventlist, len_total_filtered_eventslit_4s_read
  assert_equals, len_total_trigger, len_total_trigger_4s_read
  
  ; compare counts
  assert_equals, len_total_filtered_eventlist, total((*self.total_filtered_eventlist).relative_time eq (*self.total_filtered_eventlist_4s_read).relative_time)
  assert_equals, len_total_filtered_eventlist, total((*self.total_filtered_eventlist).detector_index eq (*self.total_filtered_eventlist_4s_read).detector_index)
  assert_equals, len_total_filtered_eventlist, total((*self.total_filtered_eventlist).pixel_index eq (*self.total_filtered_eventlist_4s_read).pixel_index)
  assert_equals, len_total_filtered_eventlist, total((*self.total_filtered_eventlist).energy_ad_channel eq (*self.total_filtered_eventlist_4s_read).energy_ad_channel)
  assert_equals, len_total_filtered_eventlist, total((*self.total_filtered_eventlist).attenuator_flag eq (*self.total_filtered_eventlist_4s_read).attenuator_flag)
  
  ; compare triggers
  assert_equals, len_total_trigger, total((*self.total_triggers).relative_time eq (*self.total_triggers_4s_read).relative_time)
  assert_equals, len_total_trigger, total((*self.total_triggers).adgroup_index eq (*self.total_triggers_4s_read).adgroup_index)
  assert_equals, len_total_trigger, total((*self.total_triggers).detector_index eq (*self.total_triggers_4s_read).detector_index)
end

;+
; :description:
;   this test compares the filtered counts, and the triggers from the DSS 4s-read-and-filter routine
;   with the filtered counts, and triggers from the direct reading (using the FITS counts reader)
;-
pro stx_scenario_dss_io__test::test_4s_readout_with_total_direct_readout
  ; calculate lengths
  len_total_filtered_eventlist_all_read = n_elements(*self.total_filtered_eventlist_all_read)
  len_total_filtered_eventslit_4s_read = n_elements(*self.total_filtered_eventlist_4s_read)
  len_total_trigger_all_read = n_elements(*self.total_trigger_all_read)
  len_total_trigger_4s_read = n_elements(*self.total_triggers_4s_read)

  ; compare lengths
  assert_equals, len_total_filtered_eventlist_all_read, len_total_filtered_eventslit_4s_read
  assert_equals, len_total_trigger_all_read, len_total_trigger_4s_read

  ; compare counts
  assert_equals, len_total_filtered_eventlist_all_read, total((*self.total_filtered_eventlist_all_read).relative_time eq (*self.total_filtered_eventlist_4s_read).relative_time)
  assert_equals, len_total_filtered_eventlist_all_read, total((*self.total_filtered_eventlist_all_read).detector_index eq (*self.total_filtered_eventlist_4s_read).detector_index)
  assert_equals, len_total_filtered_eventlist_all_read, total((*self.total_filtered_eventlist_all_read).pixel_index eq (*self.total_filtered_eventlist_4s_read).pixel_index)
  assert_equals, len_total_filtered_eventlist_all_read, total((*self.total_filtered_eventlist_all_read).energy_ad_channel eq (*self.total_filtered_eventlist_4s_read).energy_ad_channel)
  assert_equals, len_total_filtered_eventlist_all_read, total((*self.total_filtered_eventlist_all_read).attenuator_flag eq (*self.total_filtered_eventlist_4s_read).attenuator_flag)

  ; compare triggers
  assert_equals, len_total_trigger_all_read, total((*self.total_trigger_all_read).relative_time eq (*self.total_triggers_4s_read).relative_time)
  assert_equals, len_total_trigger_all_read, total((*self.total_trigger_all_read).adgroup_index eq (*self.total_triggers_4s_read).adgroup_index)
  assert_equals, len_total_trigger_all_read, total((*self.total_trigger_all_read).detector_index eq (*self.total_triggers_4s_read).detector_index)
end

pro stx_scenario_dss_io__test__define
  compile_opt idl2, hidden

  void = { $
    stx_scenario_dss_io__test, $
    total_eventlist_4s_read: ptr_new(), $
    total_filtered_eventlist_4s_read: ptr_new(), $
    total_triggers_4s_read: ptr_new(), $
    total_filtered_eventlist: ptr_new(), $
    total_triggers: ptr_new(), $
    total_eventlist_all_read: ptr_new(), $
    total_filtered_eventlist_all_read: ptr_new(), $
    total_trigger_all_read: ptr_new(), $
    inherits stx_scenario_test }
end
