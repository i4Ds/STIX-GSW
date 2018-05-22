;+
; :FILE_COMMENTS:
;    This is the main Flight Software Simulator application
;    in a clocked version
;    TODO: Extend description
;
; :CATEGORIES:
;    flight software simulation, software
;
; :EXAMPLES:
;    dss = obj_new('stx_flight_software_simulator')
;    dss->set, /stop_on_error
;    help, dss->getdata(input_data=...)
;
; :HISTORY:
;    18-Jun-2014 - Nicky Hochmuth (FHNW), initial release (documentation)
;    19-Jan-2015 - Laszlo I. Etesi (FHNW), bugfix: allowing histogram to work with one detector event
;    22-Jul-2015 - Laszlo I. Etesi (FHNW), added calibrated event list as an output option
;    30-Oct-2015 - Laszlo I. Etesi (FHNW), - renamed event_list to eventlist, and trigger_list to triggerlist
;                                          - general cleanup and formatting
;    10-May-2016 - Laszlo I. Etesi (FHNW), major update of the FSW SIM
;                                          - not using internal Hash maps anymore for storing data
;                                          - not saving calibrated and temperature corrected event lists anymore (possible upon request)
;                                          - cleaned up function calls (introduced module caller routine)
;    11-May-2016 - Laszlo I. Etesi (FHNW), fixed an IDL 8.5 -> IDL 8.3 compatibility error
;    07-Jun-2016 - Laszlo I. Etesi (FHNW), minor cleanup and adjustment for the new archive buffer accumulator routine
;
; :TODO:
;-

;+
; :DESCRIPTION:
;    this function initialises this module
;
; :PARAMS:
;    configuration_manager : in, optional, type='string', default="stx_configuration_manager(configfile='stx_flight_software_simulator_default.config')"
;      this is a stx_configuration_manager object that has been
;      initialized with a stx_data_simulation configuration
;
; :RETURNS:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_flight_software_simulator::init, configuration_manager, expected_number_time_bins=expected_number_time_bins, keep_temp_and_calib_detector_events=keep_temp_and_calib_detector_events, _extra=ex
  default, configuration_manager, stx_configuration_manager(application_name='stx_flight_software_simulator', initialize=0)
  default, internal_state, stx_fsw_internal_state()
  default, expected_number_time_bins, 100
  default, start_time, stx_time()

  ; initialize configuration manager and state
  res = self->ppl_processor::init(configuration_manager, internal_state)

  ; prepare for a new instance
  self->_inititalize_new_fsw_instance, expected_number_time_bins=expected_number_time_bins, start_time=start_time, keep_temp_and_calib_detector_events=keep_temp_and_calib_detector_events, _extra=ex

  ; inititalize internal state-independent variables
  self.modules = hash()
  self.history = ppl_history() ; TODO: Remove or improve

  ; initialize modules
  (self.modules)['stx_fsw_module_ad_temperature_correction']       = stx_fsw_module_ad_temperature_correction()
  (self.modules)['stx_fsw_module_accumulate_calibration_spectrum'] = stx_fsw_module_accumulate_calibration_spectrum()
  (self.modules)['stx_fsw_module_convert_science_data_channels']   = stx_fsw_module_convert_science_data_channels()
  (self.modules)['stx_fsw_module_eventlist_to_archive_buffer']     = stx_fsw_module_eventlist_to_archive_buffer()
  (self.modules)['stx_fsw_module_triggerlist_to_livetime']         = stx_fsw_module_triggerlist_to_livetime()
  (self.modules)['stx_fsw_module_quicklook_accumulation']          = stx_fsw_module_quicklook_accumulation()
  (self.modules)['stx_fsw_module_intervalselection_img']           = stx_fsw_module_intervalselection_img()
  (self.modules)['stx_fsw_module_intervalselection_spc']           = stx_fsw_module_intervalselection_spc()
  (self.modules)['stx_fsw_module_flare_detection']                 = stx_fsw_module_flare_detection()
  (self.modules)['stx_fsw_module_flare_selection']                 = stx_fsw_module_flare_selection()
  (self.modules)['stx_fsw_module_background_determination']        = stx_fsw_module_background_determination()
  (self.modules)['stx_fsw_module_coarse_flare_locator']            = stx_fsw_module_coarse_flare_locator()
  (self.modules)['stx_fsw_module_variance_calculation']            = stx_fsw_module_variance_calculation()
  (self.modules)['stx_fsw_module_detector_monitor']                = stx_fsw_module_detector_monitor()
  (self.modules)['stx_fsw_module_rate_control_regime']             = stx_fsw_module_rate_control_regime()
  (self.modules)['stx_fsw_module_data_compression']                = stx_fsw_module_data_compression()
  (self.modules)['stx_fsw_module_reduce_ql_spectra']               = stx_fsw_module_reduce_ql_spectra()
  (self.modules)['stx_fsw_module_tmtc']                            = stx_fsw_module_tmtc()

  return, res
end

pro stx_flight_software_simulator::reloadConfig
  print, "reload config"
  

  (*(*self.internal_state).CONFIGURATION_MANAGER)->load_configuration
  
  ;new_conf = stx_configuration_manager(application_name=curent_conf.APPLICATION, initialize=0,configfile=curent_conf.CONFIGURATION_FILE )

  ;self->_inititalize_new_fsw_instance, expected_number_time_bins=expected_number_time_bins, start_time=start_time, keep_temp_and_calib_detector_events=keep_temp_and_calib_detector_events, _extra=ex

  
end

; TODO: Write documtentation
pro stx_flight_software_simulator::_inititalize_new_fsw_instance, expected_number_time_bins=expected_number_time_bins, start_time=start_time, flare_detection_past=flare_detection_past, keep_temp_and_calib_detector_events=keep_temp_and_calib_detector_events
  default, keep_temp_and_calib_detector_events, 1L

  ; initialize internal state
  ;-------------------------------

  ; initialize time
  (*self.internal_state).reference_time = start_time
  (*self.internal_state).time_bin_width = self->get(/base_frequency)

  ; configure internal state
  (*self.internal_state).expected_number_time_bins = expected_number_time_bins

  ; prepare output streams and folders
  self->_inititalize_memory_data_cache

  ; initialize data pre T0
  ;-----------------------

  ; set default calibration spectrum
  self->_write_data, product_type='stx_fsw_m_calibration_spectrum', val=stx_construct_sim_calibration_spectrum(), init_expected_number_time_bins=1, init_auto_inc=1

  ; generate detector monitor structure
  ; TODO: change self->get(/dm_default_yellow_flag_list) to 32 elements
  for i = 0L, 16-1 do begin
    self->_write_data, product_type='stx_fsw_m_detector_monitor', val=stx_fsw_m_detector_monitor(noisy_detectors=bytarr(32)+1b), init_t0=16, init_expected_number_time_bins=100
  endfor

  ; set all detectors to be active
  ;self->_write_data, product_type='stx_fsw_m_active_detectors', val=stx_fsw_m_active_detectors(), init_t0=1, init_expected_number_time_bins=100

  rcr1b = stx_fsw_m_rate_control_regime()
  rcr1b.time_axis = self->_create_single_time_axis_entry(update_frequency=self->get(/rcr_update_frequency), lookahead = 1)
  
  ; set the rate control regime to zero
  self->_write_data, product_type='stx_fsw_m_rate_control_regime', val=rcr1b, init_t0=0, init_expected_number_time_bins=100
  
  ;rcr2b = stx_fsw_m_rate_control_regime()
  ;rcr2b.time_axis = self->_create_single_time_axis_entry(update_frequency=self->get(/rcr_update_frequency), lookahead =  2)
  ;self->_write_data, product_type='stx_fsw_m_rate_control_regime', val=rcr2b

  ; get and set the default background
  self->_write_data, product_type='stx_fsw_m_background', val=stx_fsw_m_background(background=self->get(/bgd_default_background)), init_t0=1, init_expected_number_time_bins=100

  ; set the noisy detector list
  ;self->_write_data, product_type='stx_fsw_m_noisy_detectors', val=stx_fsw_m_noisy_detectors(noisy_detectors=self->get(/dm_default_yellow_flag_list)), init_t0=1, init_expected_number_time_bins=100

  ; set the archive buffer timing
  ;self->_write_data, product_type='archive_buffer_timing', val=0d, init_expected_number_time_bins=1000000L

  ;self->_write_data, product_type='temperature_corrected_eventlist', val=0d, init_expected_number_time_bins=1, init_auto_inc=0

  if(ppl_typeof(flare_detection_past, compareto='stx_fsw_m_flare_detection_context') || ppl_typeof(flare_detection_past, compareto='stx_fsw_flare_detection_context')) then begin ; 2nd is for legacy purposes
    ; get the time duration for each baseline window
    max_duration = max(self->get(/fd_nbl))
    self->getproperty, time_bin_width=time_bin_width
    max_iterations = max_duration / time_bin_width

    flare_detection_past_copy = flare_detection_past

    ;do we have a longer past as nessesary then trim it to the latest data
    if n_elements(flare_detection_past.thermal_cc) gt max_iterations then begin
      flare_detection_past_copy = ppl_replace_tag(flare_detection_past_copy,'THERMAL_CC', flare_detection_past.thermal_cc[-max_iterations:-1])
      flare_detection_past_copy = ppl_replace_tag(flare_detection_past_copy,'NONTHERMAL_CC', flare_detection_past.nonthermal_cc[-max_iterations:-1])
      flare_detection_past_copy = ppl_replace_tag(flare_detection_past_copy,'THERMAL_BG', flare_detection_past.thermal_bg[-max_iterations:-1])
      flare_detection_past_copy = ppl_replace_tag(flare_detection_past_copy,'NONTHERMAL_BG', flare_detection_past.nonthermal_bg[-max_iterations:-1])
    end

    self->_write_data, product_type='stx_fsw_m_flare_flag', val=stx_fsw_m_flare_flag(flare_flag=0, context=flare_detection_past_copy), init_expected_number_time_bins=100, init_t0=1
  endif


  ; initialize positional information
  ;-----------------------------------

  ; temperature corrected eventlist
  ((*self.internal_state).memory_cached_data_pos)['temperature_corrected_eventlist'] = ulong([0, 0, keep_temp_and_calib_detector_events, 0])

  ((*self.internal_state).memory_cached_data_pos)['stx_sim_calibrated_detector_eventlist'] = ulong([0, 0, keep_temp_and_calib_detector_events, 0])


end

pro stx_flight_software_simulator::_inititalize_memory_data_cache
  ; initialize internal memory
  (*self.internal_state).memory_cached_data = hash()

  ; quicklook accumulators
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_lightcurve'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_lightcurve_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_spectra'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_spectra_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_bkgd_monitor'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_bkgd_monitor_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_variance'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_variance_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_detection'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_detection_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_location_1'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_location_1_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_location_2'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_flare_location_2_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_detector_anomaly'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_detector_anomaly_lt'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_quicklook'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_ql_quicklook_lt'] = !NULL

  ; register data products
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_flare_flag'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_rate_control_regime'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_calibration_spectrum'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_background'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_variance'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_detector_monitor'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_coarse_flare_location'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_m_archive_buffer_group'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_fsw_total_source_counts'] = !NULL

  ;((*self.internal_state).memory_cached_data)['stx_fsw_m_archive_buffer'] = !NULL
  ;((*self.internal_state).memory_cached_data)['stx_fsw_m_trigger_accumulator'] = !NULL

  ; register intermediate/temporary products
  ((*self.internal_state).memory_cached_data)['temperature_corrected_eventlist'] = !NULL
  ((*self.internal_state).memory_cached_data)['stx_sim_calibrated_detector_eventlist'] = !NULL
  ((*self.internal_state).memory_cached_data)['archive_buffer_leftovers'] = !NULL
  ((*self.internal_state).memory_cached_data)['triggerlist_leftovers'] = !NULL
  ;((*self.internal_state).memory_cached_data)['archive_buffer_total_counts'] = !NULL
  ;((*self.internal_state).memory_cached_data)['flare_detection_context'] = !NULL

  ; register timing information
  ;((*self.internal_state).memory_cached_data)['archive_buffer_timing'] = !NULL
end

pro stx_flight_software_simulator::_write_data, val=val, product_type=product_type, $
  do_update=do_update, do_insert=do_insert, $
  init_auto_inc=init_auto_inc, init_expected_number_time_bins=init_expected_number_time_bins, init_t0=init_t0

  default, do_update, keyword_set(do_insert) ? ~do_insert : 0
  default, do_insert, ~do_update

  if(~is_struct(val) || where(tag_names(val) eq 'TIME_AXIS') eq -1) then print, product_type

  if((do_update && do_insert) || (~do_update && ~do_insert)) then message, 'Either select update or reset!'

  ; the following parameters are only used when write_destination is set to 1
  default, init_auto_inc, (*self.internal_state).expected_number_time_bins ; if set to 0, the cache becomes a rotating buffer
  default, init_expected_number_time_bins, (*self.internal_state).expected_number_time_bins
  default, init_tc, 0
  default, init_t0, 0

  ; 'default' seems not to work as it invokes _current_time_bin, which does not work pre process (no current available)
  if(~isvalid(time_bin)) then self->getproperty, current_bin=time_bin

  ; check if initialization is needed
  if(((*self.internal_state).memory_cached_data)[product_type] eq !NULL) then begin
    ; initialize the internal cache

    ; only default initialize the positional information if none has been defined yet, otherwise extract config
    if(~(*self.internal_state).memory_cached_data_pos->haskey(product_type)) then $
      ((*self.internal_state).memory_cached_data_pos)[product_type] = ulong([init_t0, init_tc, init_expected_number_time_bins, init_auto_inc]) $
    else begin
      pos_info = ((*self.internal_state).memory_cached_data_pos)[product_type]
      init_t0 = pos_info[0]
      init_tc = pos_info[1]
      init_expected_number_time_bins = pos_info[2]
      init_auto_inc = pos_info[3]
    endelse

    ((*self.internal_state).memory_cached_data)[product_type] = ptr_new(ptrarr(init_expected_number_time_bins + init_t0))
  endif

  ; read cache pointers, etc.
  cache_idx = ((*self.internal_state).memory_cached_data_pos)[product_type]
  cache_ptr = ((*self.internal_state).memory_cached_data)[product_type]

  ; in case of an insert, we will write the data and advance the pointer
  ; in case of an update, we decrease the pointer temporarily
  ; in any case we need to take n_val (the number of items to insert) into account
  if(do_insert) then begin
    ; check if the cache has enough space to contain all the values
    ; in case of an update, we reduce the number required since we're reusing a space
    if(cache_idx[1] + 1 - do_update gt cache_idx[2]) then begin

      ; if auto_inc is set to 0, cache is a rotating buffer
      if(cache_idx[3] eq 0) then begin
        cache_idx[0] = 0
        cache_idx[1] = 0
        ((*self.internal_state).memory_cached_data_pos)[product_type] = cache_idx
      endif else begin
        (*((*self.internal_state).memory_cached_data)[product_type]) = [(*((*self.internal_state).memory_cached_data)[product_type]), ptrarr(cache_idx[3])]
        cache_idx[2] += cache_idx[3]
        ((*self.internal_state).memory_cached_data_pos)[product_type] = cache_idx
      endelse
    endif

    ; write the value
    (*cache_ptr)[cache_idx[1]] = ptr_new(val)

    ; increase and update the pointer
    cache_idx[1] += 1
    ((*self.internal_state).memory_cached_data_pos)[product_type] = cache_idx

  endif else begin
    ; temporarily decrease the pointer
    ; write the value
    (*cache_ptr)[cache_idx[1]-1] = ptr_new(val)
  endelse
end

function stx_flight_software_simulator::_read_data, product_type=product_type, most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags
  default, most_n_recent, 1
  default, complete, 0
  default, combine, 0

  ;if(product_type eq 'temperature_corrected_eventlist') then stop

  cache_ptr = ((*self.internal_state).memory_cached_data)[product_type]

  ; handle read request that poll for data
  if(cache_ptr eq !NULL) then return, !NULL
  pos_info = ((*self.internal_state).memory_cached_data_pos)[product_type]

  if(~complete) then val_ptrs = (*cache_ptr)[pos_info[1] - most_n_recent : pos_info[1] - 1] $
  else val_ptrs = (*cache_ptr)[pos_info[0]:pos_info[1]-1]

  if(product_type eq 'stx_fsw_m_archive_buffer_group') then combine = 1

  if(combine) then begin
    vals = (*val_ptrs[0])
    has_time_axis = tag_exist(vals, 'time_axis')

    if(n_elements(vals) eq 1) then begin
      if(isvalid(ignore_tags)) then ignore_tags = [ignore_tags, 'time_axis', 'energy_axis', 'type'] $
      else ignore_tags = ['time_axis', 'energy_axis', 'type']
      all_tags = strlowcase(tag_names(vals))
      copy_tag_flag = ~stregex(all_tags, arr2str(ignore_tags, delimiter='|'), /fold_case, /boolean)
      copy_tag_idx = where(copy_tag_flag eq 1, count_tags)

      if(count_tags eq 0) then stop

      if(has_time_axis) then time_axis_new = vals.time_axis

      copy_data_ptrs = ptrarr(count_tags)

      for i = 0L, count_tags-1 do begin
        no_vals = ulong64(0)
        if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[i]] eq 'archive_buffer') then begin
          for ab_idx = 0L, n_elements(val_ptrs)-1 do begin
            no_vals += n_elements((*val_ptrs[ab_idx]).archive_buffer)
          endfor

          copy_data_ptrs[i] = ptr_new(replicate(vals.(copy_tag_idx[i])[0], no_vals))
        endif else if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[i]] eq 'triggers') then begin
          for tr_idx = 0L, n_elements(val_ptrs)-1 do begin
            no_vals += n_elements((*val_ptrs[tr_idx]).triggers)
          endfor

          copy_data_ptrs[i] = ptr_new(replicate(vals.(copy_tag_idx[i])[0], no_vals))
        endif else if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[i]] eq 'total_counts') then begin
          for tc_idx = 0L, n_elements(val_ptrs)-1 do begin
            no_vals += n_elements((*val_ptrs[tc_idx]).total_counts)
          endfor

          copy_data_ptrs[i] = ptr_new(replicate(vals.(copy_tag_idx[i])[0], no_vals))
        endif else if(product_type eq 'stx_sim_calibrated_detector_eventlist' && all_tags[copy_tag_idx[i]] eq 'sources') then begin
          copy_data_ptrs[i] = ptr_new(vals.(copy_tag_idx[i])[0])
          ;no_vals +=
        endif else if(product_type eq 'stx_sim_calibrated_detector_eventlist' && all_tags[copy_tag_idx[i]] eq 'detector_events') then begin
          for de_idx = 0L, n_elements(val_ptrs)-1 do begin
            no_vals += n_elements((*val_ptrs[de_idx]).detector_events)
          endfor

          copy_data_ptrs[i] = ptr_new(replicate(vals.(copy_tag_idx[i])[0], no_vals))
        endif else begin
          no_vals = n_elements(val_ptrs)
          copy_data_ptrs[i] = ptr_new(reform(reproduce(vals.(copy_tag_idx[i]), no_vals)))
        endelse
      endfor

      ab_ptr = 0
      tr_ptr = 0
      tc_ptr = 0
      de_ptr = 0
      src_ptr = 0

      for val_idx = 0L, n_elements(val_ptrs)-1 do begin
        if(n_elements(time_axis_new) gt 1) then stop
        if(has_time_axis && n_elements((*val_ptrs[val_idx]).time_axis) gt 1) then stop
        if(has_time_axis && val_idx gt 0) then time_axis_new = stx_time_axis_append(time_axis_new, (*val_ptrs[val_idx]).time_axis) ; we already have time axis for t0 (value 0)

        for j = 0L, count_tags-1 do begin
          data_new = reform((*val_ptrs[val_idx]).(copy_tag_idx[j]))
          n_data = n_elements(data_new)
          if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[j]] eq 'archive_buffer') then begin
            (*copy_data_ptrs[j])[ab_ptr : ab_ptr + n_data - 1] = data_new
            ab_ptr += n_data
          endif else if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[j]] eq 'triggers') then begin
            (*copy_data_ptrs[j])[tr_ptr: tr_ptr + n_data - 1] = data_new
            tr_ptr += n_data
          endif else if(product_type eq 'stx_fsw_m_archive_buffer_group' && all_tags[copy_tag_idx[j]] eq 'total_counts') then begin
            (*copy_data_ptrs[j])[tc_ptr: tc_ptr + n_data - 1] = data_new
            tc_ptr += n_data
          endif else if(product_type eq 'stx_sim_calibrated_detector_eventlist' && all_tags[copy_tag_idx[j]] eq 'sources' && j eq 0) then begin
            (*copy_data_ptrs[j])[src_ptr: src_ptr + n_data - 1] = data_new
          endif else if(product_type eq 'stx_sim_calibrated_detector_eventlist' && all_tags[copy_tag_idx[j]] eq 'detector_events') then begin
            (*copy_data_ptrs[j])[de_ptr: de_ptr + n_data - 1] = data_new
            de_ptr += n_data
          endif else begin
            insert_ptr = product(size(vals.(copy_tag_idx[j]), /dimensions) > 1) * val_idx
            (*copy_data_ptrs[j])[insert_ptr : insert_ptr +n_data - 1] = reform((*val_ptrs[val_idx]).(copy_tag_idx[j]))
          endelse
        endfor
      endfor

      if(n_elements(val_ptrs) gt 1) then begin
        if(has_time_axis) then vals = ppl_replace_tag(vals, 'time_axis', time_axis_new)

        for k = 0L, count_tags-1 do begin
          vals = ppl_replace_tag(vals, all_tags[copy_tag_idx[k]], (*copy_data_ptrs[k]))
        endfor
      endif
    endif else begin
      ; naive apending for the moment
      for val_idx = 1L, n_elements(val_ptrs)-1 do begin
        vals = [vals, (*val_ptrs[val_idx])]
      endfor

    endelse
  endif else begin
    vals = []

    for val_idx = 0L, n_elements(val_ptrs)-1 do begin
      if(~isvalid(vals)) then vals = reproduce(*val_ptrs[val_idx], n_elements(val_ptrs))
      vals[val_idx] = *val_ptrs[val_idx]
    endfor
  endelse

  return, vals

  ;  if(combine && stregex(product_type, 'stx_fsw_ql_', /boolean, /fold_case)) then begin
  ;    vals = (*val_ptrs[0])
  ;    time_axis_new = vals.time_axis
  ;    accumulated_counts_new = reform(reproduce(vals.accumulated_counts, n_elements(val_ptrs)))
  ;
  ;    for val_idx = 1L, n_elements(val_ptrs)-1 do begin
  ;      time_axis_new = stx_time_axis_append((*val_ptrs[val_idx]).time_axis, time_axis_new)
  ;      accumulated_counts_new[product(size(vals.accumulated_counts, /dimensions)) * val_idx] = reform((*val_ptrs[val_idx]).accumulated_counts)
  ;    endfor
  ;
  ;    if(n_elements(val_ptrs) gt 1) then begin
  ;      vals = ppl_replace_tag(vals, 'time_axis', time_axis_new)
  ;      vals = ppl_replace_tag(vals, 'accumulated_counts', accumulated_counts_new)
  ;    endif
  ;  endif else begin
  ;    vals = []
  ;
  ;    for val_idx = 0L, n_elements(val_ptrs)-1 do begin
  ;      if(~isvalid(vals)) then vals = reproduce(*val_ptrs[val_idx], n_elements(val_ptrs))
  ;      vals[val_idx] = *val_ptrs[val_idx]
  ;    endfor
  ;  endelse
  ;
  ;  return, vals
end

function stx_flight_software_simulator::_data_directory, product_type=product_type
  if(~((*self.internal_state).output_directories)->haskey(product_type)) then message, 'Selected product type not available for saving: ' + product_type
  return, ((*self.internal_state).output_directories)[product_type]
end

function stx_flight_software_simulator::_data_product_file_path, product_type=product_type, time_bin=time_bin,  most_n_recent=most_n_recent
  ; fetch output directory
  output_dir = self->_data_directory(product_type=product_type)

  ; respect the "most recent" keyword and try finding the most recent...
  if(keyword_set(most_n_recent)) then most_recent_files = (loc_file(path=output_dir, product_type + '*'))[-1]

  ; ... if there is no most recent, create a new file with the current time bin, otherwise use most recent and extract time bin
  if(isvalid(most_recent_files) && most_recent_files[0] ne '') then begin
    candidates = stregex(most_recent_files, '.*\[(-?[0-9]*(\.[0-9]+)?)\]', /subexpr, /fold_case, /extract)

    n_candidates = n_elements(candidates) - 2
    n_select = n_candidates < most_n_recent
    time_bin_string = candidates[1:n_select]

    ; check if it needs to be cast as int, or in exceptional cases to float
    time_bin = fix(time_bin_string, type=(2 + 2*stregex(time_bin_string, '[0-9]+\.[0-9]+', /boolean)))
    return, most_recent_files
  endif $
    ; check if time bin was set
  else if(~isvalid(time_bin)) then return, !NULL $
  else begin
    ; making sure we don't keep superfluous zeros
    if(ppl_typeof(time_bin, compareto='float', /raw)) then time_bin = trim(string(time_bin, format='(F20.2)'))

    return, concat_dir(output_dir, product_type + '[' + trim(string(time_bin)) + ']')
  endelse
end

;+
;  :DESCRIPTION:
;    The purpose of this routine is to process detector events in "one go" in by 4s time bin;
;    in any case, the detector events are binned and processed in 4 seconds. Every time
;    this routine finishes processing a batch of events, the flight software simulator
;    provides updated sets of accumulators and/or data products.
;
;  :PARAMS:
;    eventlist : in, required, type='stx_sim_detector_eventlist'
;      This is a detector eventlist containing events for an arbitrary long period
;
;    triggerlist : in, required, type='stx_sim_event_triggerlist'
;      This is a trigger list containing events for the same period as the eventlist
;
;    total_source_counts : in, optional, type='long*'
;      the number of total counts per detector bevore RCR and time filtering
;      
;      
;    finalize_processing ; in, optional, type='boolean', default='0'
;      By setting this keyword to 1, the flight software simulator tells all its
;      modules to close off the data stream and buffers after this bin
;
;    relative_time_final_event : in, optional, type='double'
;      This keyword can be set to the relative time of the last event; by doing so
;      the flight software simulator will be able to set the keyword finalize_processing
;      automatically to close of all open data streams and buffers at the appropriate time
;
;    _extra : in, optional, type='any'
;      any extra parameters
;
;  :HISTORY:
;    07-Jul-2015 - Laszlo I. Etesi (FHNW), added two keywords: finalize_processing, relative_time_final_event
;    07-Oct-2015 - Laszlo I. Etesi (FHNW), major cleanup
;-
pro stx_flight_software_simulator::process, eventlist, triggerlist, total_source_counts=total_source_counts, finalize_processing=finalize_processing, relative_time_final_event=relative_time_final_event, _extra=extra
  ; detect level of this call on stack
  help, /traceback, out=tb
  ; only install error handler if this routine has not been previously called
  ppl_state_info, out_filename=this_file_name
  found = where(stregex(tb, this_file_name) ne -1, level)
  
  default, total_source_counts, indgen(32)
  
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

  ; set default values
  default, finalize_processing, 0b
  default, relative_time_final_event, -1d

  ; verify inputs
  ppl_require, in=eventlist, type='stx_sim_detector_eventlist'
  ppl_require, in=triggerlist, type='stx_sim_event_triggerlist'

  ; the following few lines calculate the number of 4s time bins for the given eventlist, then loops over every 4s separately
   t_bin_width = (*self.internal_state).time_bin_width
  density = histogram([eventlist.detector_events.relative_time], binsize=t_bin_width, reverse_indices=time_bin_idx, locations=locations, min=0, /l64)
  density_trigger = histogram([triggerlist.trigger_events.relative_time], binsize=t_bin_width, reverse_indices=time_bin_idx_triggers, locations=locations_triggers, min=0, /l64)

  ; loop over all 4 seconds in the data
  for n=0L, n_elements(locations)-1 do begin
    if time_bin_idx[n] ne time_bin_idx[n+1] then begin
      current_time_bin_eventlist = stx_construct_sim_detector_eventlist(start_time=eventlist.time_axis.time_start, detector_events=eventlist.detector_events[time_bin_idx[time_bin_idx[n] : time_bin_idx[n+1]-1]])

      ; update finalize processing if necessary
      finalize_processing = finalize_processing or max((current_time_bin_eventlist.detector_events.relative_time eq relative_time_final_event eq 1)) eq 1

      ; check if the projected number of events is the same as the actual number of events for this 4s time bin
      if(density[n] ne n_elements(current_time_bin_eventlist.detector_events)) then message, 'The number of detector events for this time bin does not agree with the total histogram elements'

      ; construct a new triggerlist for this time bin
      current_time_bin_triggerlist = stx_construct_sim_detector_eventlist( $
        start_time=triggerlist.time_axis.time_start, $
        detector_events=time_bin_idx_triggers[n] ne time_bin_idx_triggers[n+1] ? triggerlist.trigger_events[time_bin_idx_triggers[time_bin_idx_triggers[n] : time_bin_idx_triggers[n+1]-1]] : [], $
        sources=triggerlist.sources)

      ; check if the projected number of triggers is the same as the actual number of triggers for this 4s time bin
      if(density_trigger[n] ne n_elements(current_time_bin_triggerlist.trigger_events)) then message, 'The number of trigger events for this time bin does not agree with the total histogram elements'

      ; Update timing information
      (*self.internal_state).current_bin++
      (*self.internal_state).relative_time = (*self.internal_state).current_bin * (*self.internal_state).time_bin_width
      (*self.internal_state).current_time = stx_time_add((*self.internal_state).reference_time, seconds=(*self.internal_state).relative_time)

      ; TODO: better logging
      print, "Starting time_bin #: ", + trim(string((*self.internal_state).current_bin))

      self->_process, current_time_bin_eventlist, current_time_bin_triggerlist, finalize_processing=finalize_processing, _extra=extra
      
      
      tsc_struct = { $
        type      : "stx_fsw_total_source_counts", $
        time_axis : self->_create_single_time_axis_entry(update_frequency = 1), $
        counts    : total_source_counts $
      }
      
      self->_write_data, product_type='stx_fsw_total_source_counts', val = tsc_struct
            
      ; TODO: better logging
      print, "Finished time_bin #: ", + trim(string((*self.internal_state).current_bin))
    endif
  end
end

function stx_flight_software_simulator::_do_module_action, module=module, do_update=do_update, do_reset=do_reset, do_quicklook_reset=do_quicklook_reset
  default, do_update, 0
  default, do_reset, 0
  default, do_quicklook_reset, 0

  ; for modules this modifier must be 1 to ensure they are not triggered on T = 0 (if execution frequecy > 4s) but triggered during
  ; the appropriate cycle; for a do_quicklook_reset the modifier is set to 0 to ensure proper execution of the ql accumulation
  default, modifier, 1

  self->getproperty, current_bin=current_time_bin

  base_frequency = self->get(/base_frequency)

  ; by default check for an update cycle
  if(do_update) then $
    clock = self->get(module=module, /update_frequency, /single) $
    ; if do_close is set, check if this module's product needs to be closed off (only a few modules have this option)
  else if(do_reset) then $
    clock = self->get(module=module, /reset_frequency, /single) $
  else if(do_quicklook_reset) then begin
    ; extract the clock for the ql accumulation module
    conf = self->get(module='stx_fsw_module_quicklook_accumulation')
    tag_nms = strlowcase(tag_names(conf))

    is_trigger = max(stregex(module, '^.*(_lt)$', /subexpr, length=length)) ge 0

    if(~is_trigger) then use_name=module $
    else use_name = strmid(module, 0, length[0]-length[1])

    tag_idx = where(tag_nms eq 'reset_frequency_' + use_name)
    if(tag_idx eq -1) then stop
    clock = conf.(tag_idx)
    modifier = 0
  endif else $
    message, 'Please choose either do_update or do_close, or set module to a quicklook accumulator and activate do_quicklook_reset'

  ; make sure we execute everything "at the right time"
  return, ((current_time_bin + modifier) mod (clock/base_frequency)) eq 0
end

function stx_flight_software_simulator::_execute_module, module=module, _extra=extra
  if(self->_do_module_action(module=module, /do_update)) then begin
    return, call_method('_execute_' + module, self, module=module, _extra=extra)
  end
end

function stx_flight_software_simulator::_execute_stx_fsw_module_ad_temperature_correction, module=module, $
  eventlist=eventlist

  success = (self.modules)[module]->execute(eventlist, ad_temperature_corrected_eventlist, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; write temperature corrected data
  self->_write_data, product_type='temperature_corrected_eventlist', val=ad_temperature_corrected_eventlist.detector_events, /do_insert

  return, ad_temperature_corrected_eventlist
end

function stx_flight_software_simulator::_execute_stx_fsw_module_accumulate_calibration_spectrum, module=module, $
  ad_temperature_corrected_eventlist=ad_temperature_corrected_eventlist, absolute_bin_start_time=absolute_bin_start_time, $
  absolute_bin_end_time=absolute_bin_end_time

  current_product = 'stx_fsw_m_calibration_spectrum'

  ; check if we have a previous calibration spectrum
  previous_calibration_spectrum = self->_read_data(product_type=current_product, /most_n_recent)

  acs_in = { $
    eventlist                     : ad_temperature_corrected_eventlist , $
    previous_calibration_spectrum : previous_calibration_spectrum $ ; read in the most recent spectrogram
  }

  success = (self.modules)[module]->execute(acs_in, updated_calibration_spectrum, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module calibration spectrum accumulation executed unsuccessfully'

  ; check if anyone set the start time properly
  if(updated_calibration_spectrum.start_time.value.mjd eq 0) then updated_calibration_spectrum.start_time = absolute_bin_start_time

  self->_write_data, product_type=current_product, val=updated_calibration_spectrum, /do_update

  ; check to see if we need to close off the spectrogram and start a new one
  if(self->_do_module_action(module=module, /do_reset)) then begin
    ; update parameters
    current_calibration_spectrum = self->_read_data(product_type=current_product, /most_n_recent)
    current_calibration_spectrum.end_time = absolute_bin_end_time
    self->_write_data, product_type=current_product, val=current_calibration_spectrum, /do_update

    ; write a new calibration spectrum
    self->_write_data, product_type=current_product, val=stx_construct_sim_calibration_spectrum(), /do_insert
  endif

  ; in any case pass the "old" spectrogram on, since we're still in THIS bin
  return, updated_calibration_spectrum
end

function stx_flight_software_simulator::_execute_stx_fsw_module_convert_science_data_channels, module=module, $
  ad_temperature_corrected_eventlist=ad_temperature_corrected_eventlist

  success = (self.modules)[module]->execute(ad_temperature_corrected_eventlist, calibrated_detector_eventlist, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; write temperature corrected data
  self->_write_data, product_type='stx_sim_calibrated_detector_eventlist', val=calibrated_detector_eventlist

  return, calibrated_detector_eventlist
end

function stx_flight_software_simulator::_execute_stx_fsw_module_quicklook_accumulation, module=module, $
  calibrated_detector_eventlist=calibrated_detector_eventlist, triggerlist=triggerlist, $
  time_bin_start=time_bin_start

  ; get active detectors
  detector_monitor = self->_read_data(product_type='stx_fsw_m_detector_monitor', /most_n_recent)

  ; prepare input
  qla_in = { $
    eventlist           : calibrated_detector_eventlist, $
    triggerlist         : triggerlist, $
    interval_start_time : time_bin_start, $
    detector_monitor    : detector_monitor $
  }

  success = (self.modules)[module]->execute(qla_in, quicklook_accumulators, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ;  self->getproperty, current_bin=current_bin
  ;
  ;  foreach accumulator, quicklook_accumulators, accumulator_name do begin
  ;    self->_write_data, product_type=accumulator_name, val=accumulator
  ;  endforeach

  return, quicklook_accumulators
end

;function stx_flight_software_simulator::_calculate_archive_buffer_timing, get_start_time_seconds=get_start_time_seconds, start_time_millis2time_bin=start_time_millis2time_bin
;  if(keyword_set(get_start_time_seconds)) then begin
;    ; generate last archive buffer start time
;    filename = self->_data_product_file_path(product_type='archive_buffer', time_bin=time_bin, /most_n_recent)
;    if(isvalid(time_bin)) then time_bin = max([time_bin]) $
;    else time_bin = 0 ; TODO Check if this is valid
;
;    ; extract time bin (major), add one for a correct calculation of time (bin 0 -> 4s), since
;    ; we're using end times
;    major_time_bin = fix(time_bin, type=3)
;
;    ; extract time bin (minor)
;    ; the idea of the minor time bin is to represent sub-time bin units in sub-seconds, because the archive buffer will have sub-time bin resolution
;    ; the time is AT THE END OF THE INTEGRATION so that this time can serve as the start time for the next bin
;    ; this will be maximum 40 (in case of a time bin width of 4s), as 1/10s is the highest resolution
;    ; 0.1 means major 0 (time bin 0) and minor 10 (10 * 0.1s => 1s), a total of 1 second
;    ; 4.05 means major 4 (time bin 4) and minor 5 (5 * 0.1s => 0.5s), a total of 16.5 seconds (assuming major 4 translates to 16 using 4s wide time binds)
;    minor_time_bin = round(100d * (time_bin - major_time_bin)) / 10d
;
;    ; calculate start time
;    return, major_time_bin * self->get(/base_frequency) + minor_time_bin
;  endif else if(keyword_set(start_time_millis2time_bin)) then begin
;    ; calculate minor and major
;    major_time_bin_new = fix(start_time_millis2time_bin / (1000d * self->get(/base_frequency)))
;    minor_time_bin_new = fix(((start_time_millis2time_bin / 1000d) mod self->get(/base_frequency)) / 10d, type=4)
;    return, major_time_bin_new + minor_time_bin_new
;  endif else $
;    message, 'Please choose either get_start_time_seconds or start_time_millis2time_bin'
;end

function stx_flight_software_simulator::_execute_stx_fsw_module_eventlist_to_archive_buffer, module=module, $
  calibrated_detector_eventlist=calibrated_detector_eventlist, finalize_processing=finalize_processing, $
  triggerlist=triggerlist

  ; get active detectors
  detector_monitor = self->_read_data(product_type='stx_fsw_m_detector_monitor', /most_n_recent)

  ; calculate start time based on exising data
  archive_buffer_group = self->_read_data(product_type='stx_fsw_m_archive_buffer_group', /most_n_recent)

  ; set start time to zero if !NULL
  ; TODO use the real start time in ms that is calculated by the AB accumulation routine!
  archive_buffer_start_time_seconds = archive_buffer_group eq !NULL ? 0d : max(stx_time2any(archive_buffer_group.time_axis.time_end))

  ; read leftovers
  archive_buffer_leftovers = self->_read_data(product_type='archive_buffer_leftovers', /most_n_recent)

  ; prepare input
  e2ab_in = { $
    eventlist             : calibrated_detector_eventlist, $
    leftovers             : archive_buffer_leftovers ne !NULL ? archive_buffer_leftovers : stx_sim_calibrated_detector_event(), $
    starttime             : double(round(archive_buffer_start_time_seconds * 1000)), $
    detector_monitor      : detector_monitor, $
    close_last_time_bin   : finalize_processing $
  }

  success = (self.modules)[module]->execute(e2ab_in, archive_buffer_result, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; read leftovers
  triggerlist_leftovers = self->_read_data(product_type='triggerlist_leftovers', /most_n_recent)

  self->getproperty, current_bin=bin

  if(archive_buffer_result.n_entries gt 0) then begin
    ;time_bin_save = self->_calculate_archive_buffer_timing(start_time_millis2time_bin=archive_buffer_result.starttime)
    ;help, archive_buffer_result
    ;stop
    ; first handle triggers too
    ; if we're looking at the last bin, make sure all triggers are included
    t2lt_in = {$
      triggers      : triggerlist, $
      leftovers     : triggerlist_leftovers ne !NULL ? triggerlist_leftovers : stx_sim_event_trigger(), $
      starttime     : archive_buffer_start_time_seconds, $
      endtime       : finalize_processing ? calibrated_detector_eventlist.detector_events[-1].relative_time + 1 : archive_buffer_result.starttime / 1000d, $
      timing        : archive_buffer_result.total_counts_times $
    }
    success = (self.modules)['stx_fsw_module_triggerlist_to_livetime']->execute(t2lt_in, trigger_accumulators, self.history, ((*self.internal_state).configuration_manager))
    if(~success) then message, 'Module stx_fsw_module_triggerlist_to_livetime executed unsuccessfully'

    ; now write trigger data and archive buffer data
    ;self->_write_data, product_type='stx_fsw_m_trigger_accumulator', val=trigger_accumulators.triggers
    ;self->_write_data, product_type='stx_fsw_m_archive_buffer', val=archive_buffer_result.archive_buffer
    ;self->_write_data, product_type='archive_buffer_total_counts', val=archive_buffer_result.total_counts

    ; TODO: shortcut not quite sure if that's ok
    ;tr = archive_buffer_result.archive_buffer
    tr_s = archive_buffer_result.archive_buffer.relative_time_range[0,*]
    unique_time_bins = [tr_s[uniq(tr_s, bsort(tr_s))], max(archive_buffer_result.archive_buffer.relative_time_range)]
    new_archive_buffer_group = stx_fsw_m_archive_buffer_group( $
      archive_buffer=archive_buffer_result.archive_buffer, $
      triggers=trigger_accumulators.triggers, $
      time_axis=stx_construct_time_axis(unique_time_bins), $
      ;time_axis=stx_construct_time_axis(archive_buffer_result.total_counts_times), $
      total_counts = archive_buffer_result.total_counts $
      )

    self->_write_data, product_type='stx_fsw_m_archive_buffer_group', val=new_archive_buffer_group

    ; save archive buffer timing
    ;self->_write_data, product_type='archive_buffer_timing', val=(archive_buffer_result.starttime / 1000d), /do_insert
  endif else begin
    ; no time bins have been generated, thus add current triggers and last leftover triggers
    trigger_accumulators = { $
      leftovers : (triggerlist_leftovers ne !NULL ? [triggerlist_leftovers, triggerlist.trigger_events] : triggerlist.trigger_events) $
    }
  end

  ; write leftover archive buffer
  self->_write_data, product_type='archive_buffer_leftovers', val=archive_buffer_result.leftovers, /do_insert

  ; write leftover triggers
  self->_write_data, product_type='triggerlist_leftovers', val=trigger_accumulators.leftovers, /do_insert

  ; return archive buffer result even if no data was accumulated, the trigger accumulation needs that information
  return, archive_buffer_result
end

function stx_flight_software_simulator::_execute_stx_fsw_module_rate_control_regime, module=module
  ; read quicklook triggers
  ql_trigger_accumulator = self->_read_data(product_type='stx_fsw_ql_quicklook_lt', /most_n_recent)

  ; read background triggers
  ql_background_monitor_trigger_accumulator = self->_read_data(product_type='stx_fsw_ql_bkgd_monitor_lt', /most_n_recent)

  ; read the rate control regime state
  ;self->getproperty, current_rcr = rate_control_regime_in
  rate_control_regime_in = self->_read_data(product_type='stx_fsw_m_rate_control_regime', /most_n_recent)
   
   self->getproperty, current_bin = current_bin  
   
   if current_bin gt 47 then begin
    print, current_bin
   endif
    
  rcr_in = { $
    live_time       : ql_trigger_accumulator, $
    live_time_bkgd  : ql_background_monitor_trigger_accumulator, $
    rcr             : rate_control_regime_in $
  }

  success = (self.modules)[module]->execute(rcr_in, rate_control_regime_out, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'


 

  ; set time axis
  rate_control_regime_out.time_axis = self->_create_single_time_axis_entry(update_frequency=self->get(/rcr_update_frequency),lookahead = 1)
  
  
  
  ;rate_control_regime_out.rcr = max([min([current_bin, 7]),0]) 
    
  self->_write_data, product_type='stx_fsw_m_rate_control_regime', val=rate_control_regime_out

  return, rate_control_regime_out
end

function stx_flight_software_simulator::_execute_stx_fsw_module_flare_detection, module=module, $
  rate_control_regime=rate_control_regime

  ; read flare detection quicklook accumulator
  ql_flare_detection_accumulator = self->_read_data(product_type='stx_fsw_ql_flare_detection', /most_n_recent)

  ; get last background
  background = self->_read_data(product_type='stx_fsw_m_background', /most_n_recent)

  ; read flare detection context
  last_flare_flag = self->_read_data(product_type='stx_fsw_m_flare_flag', /most_n_recent)
  context = last_flare_flag eq !NULL || ~tag_exist(last_flare_flag, 'context') ? -1 : last_flare_flag.context

  ; get update frequency
  update_frequency = self->get(/fd_update_frequency)

  fd_in = { $
    ql_counts    : ql_flare_detection_accumulator, $
    background   : long(background.background[0:1]), $ ; <- I have no idea why ; TODO: WHY?
    context      : context, $
    rcr          : rate_control_regime.rcr, $
    int_time     : update_frequency $
  }

  success = (self.modules)[module]->execute(fd_in, flare_flag, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'
  
   self->getproperty, current_bin = current_bin  
   
   ;if (current_bin gt 5 AND current_bin lt 10) OR (current_bin gt 17 AND current_bin lt 30) or (current_bin gt 35 ) then flare_flag.FLARE_FLAG = 1b
  
  ; set time axis
  flare_flag.time_axis = self->_create_single_time_axis_entry(update_frequency=update_frequency)
  
    
  
  
  self->_write_data, product_type='stx_fsw_m_flare_flag', val=flare_flag
  ;self->_write_data, product_type='flare_detection_context', val=flare_detection.context

  return, flare_flag
end

function stx_flight_software_simulator::_execute_stx_fsw_module_coarse_flare_locator, module=module

  ; read flare detection quicklook accumulators
  ql_flare_location_accumulator_1 = self->_read_data(product_type='stx_fsw_ql_flare_location_1', /most_n_recent)
  ql_flare_location_accumulator_2 = self->_read_data(product_type='stx_fsw_ql_flare_location_2', /most_n_recent)

  ; get the number of backgrounds to read
  no_backgrounds = self->get(/cfl_use_last_n_intervals, /single)

  ; get last background
  background = self->_read_data(product_type='stx_fsw_m_background', most_n_recent=no_backgrounds)

  cfl_in = { $
    background    :   background, $
    ql_cfl1_acc   :   ql_flare_location_accumulator_1, $
    ql_cfl2_acc   :   ql_flare_location_accumulator_2 $
  }

  success = (self.modules)[module]->execute(cfl_in, coarse_flare_location, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; set time_axis
  coarse_flare_location.time_axis = self->_create_single_time_axis_entry(update_frequency=self->get(/cfl_update_frequency))

  self->_write_data, product_type='stx_fsw_m_coarse_flare_location', val=coarse_flare_location

  return, coarse_flare_location
end

function stx_flight_software_simulator::_execute_stx_fsw_module_background_determination, module=module

  ; read the background monitor accumulator data
  ql_background_monitor_accumulator = self->_read_data(product_type='stx_fsw_ql_bkgd_monitor', /most_n_recent)
  
  ; get most recent background
  background = self->_read_data(product_type='stx_fsw_m_background', /most_n_recent)

  ; get update frequency
  update_frequency = self->get(/bgd_update_frequency)

  bgd_in = { $
    ql_bkgd_acc   :   ql_background_monitor_accumulator, $
    previous_bkgd :   background, $
    int_time      :   double(update_frequency) $
  }

  success = (self.modules)[module]->execute(bgd_in, new_background, self.history, ((*self.internal_state).configuration_manager))
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; set time_axis
  new_background.time_axis = self->_create_single_time_axis_entry(update_frequency=update_frequency)

  ; write background
  self->_write_data, product_type='stx_fsw_m_background', val=new_background

  return, new_background
end

function stx_flight_software_simulator::_execute_stx_fsw_module_detector_monitor, module=module, $
  flare_flag=flare_flag

  self->getproperty, current_bin=time_bin

  ; get active detectors and yellow flaged detectors
  ; the module needs the last 16 yellow flags
  detector_monitor = self->_read_data(product_type='stx_fsw_m_detector_monitor', most_n_recent=16)

  ; read the anomaly accumulators
  ql_detector_anomaly_accumulator = self->_read_data(product_type='stx_fsw_ql_detector_anomaly', /most_n_recent)
  ql_detector_anomaly_trigger_accumulator = self->_read_data(product_type='stx_fsw_ql_detector_anomaly_lt', /most_n_recent)

  ; read update frequency for this module
  update_frequency = double(self->get(/dm_update_frequency))

  dm_in = { $
    ql_counts          : ql_detector_anomaly_accumulator, $
    lt_counts          : ql_detector_anomaly_trigger_accumulator, $
    detector_monitor   : detector_monitor, $
    flare_flag         : flare_flag, $
    int_time           : update_frequency $
  }

  success = (self.modules)[module]->execute(dm_in, dm_out, self.history, (*self.internal_state).configuration_manager)

  ;openw, lun, 'C:\Temp\new\' + trim(string(time_bin)) + '.txt', /get_lun
  ;printf, lun, dm_out.active_detectors
  ;printf, lun, dm_out.noisy_detectors
  ;close, lun
  ;free_lun, lun
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; compress detector state into one byte: 0 disabled, 1 Enabled, 10 yellow disabled, 11 yellow enabled
  ;TODO: new_active_detectors = (byte(dm_out.active_detectors + reform((~dm_out.noisy_detectors[*, 0]) * 10)))

  ; create time axis
  dm_out.time_axis = self->_create_single_time_axis_entry(update_frequency=update_frequency)

  ; write data
  self->_write_data, product_type='stx_fsw_m_detector_monitor', val=dm_out ;stx_fsw_m_detector_monitor(active_detectors=new_active_detectors, noisy_detectors=dm_out.noisy_detectors, time_axis=time_axis)

  return, dm_out
end

function stx_flight_software_simulator::_execute_stx_fsw_module_variance_calculation, module=module
  ; read the anomaly accumulators
  ql_variance = self->_read_data(product_type='stx_fsw_ql_variance', /most_n_recent)

  vc_in = { $
    ql_data     : ql_variance $
  }

  success = (self.modules)[module]->execute(vc_in, variance, self.history, (*self.internal_state).configuration_manager)
  if(~success) then message, 'Module '  + module + ' executed unsuccessfully'

  ; set time_axis
  variance.time_axis = self->_create_single_time_axis_entry(update_frequency=self->get(/vc_update_frequency))

  ; write data
  self->_write_data, product_type='stx_fsw_m_variance', val=variance

  return, variance
end

pro stx_flight_software_simulator::_update_quicklook_accumulator, accumulators=accumulators
  ; process each accumulator
  foreach accumulator, accumulators, accumulator_name do begin
    ;if(accumulator_name eq 'stx_fsw_ql_bkgd_monitor') then stop
    do_reset = self->_do_module_action(module=accumulator_name, /do_quicklook_reset)

    open_accumulator_data = self->_read_data(product_type=accumulator_name, /most_n_recent)

    if(do_reset || open_accumulator_data eq !NULL) then begin

      ;new_time_axis = stx_time_axis_append(open_accumulator_data.time_axis, accumulator.time_axis)
      ;open_accumulator_data = rem_tag(open_accumulator_data, 'time_axis')
      ;open_accumulator_data = add_tag(open_accumulator_data, new_time_axis, 'time_axis', index='type')

      self->_write_data, product_type=accumulator_name, val=accumulator, do_update=(~do_reset && open_accumulator_data ne !NULL)
    endif else begin
      ; update the counts and timing inforamtion of the accumulator
      open_accumulator_data.accumulated_counts += accumulator.accumulated_counts
      open_accumulator_data.time_axis.time_end = accumulator.time_axis.time_end
      open_accumulator_data.time_axis.duration += accumulator.time_axis.duration
      open_accumulator_data.time_axis.mean = stx_time_mean(open_accumulator_data.time_axis.time_start, accumulator.time_axis.time_end)

      self->_write_data, product_type=accumulator_name, val=open_accumulator_data, /do_update
    endelse
  endforeach
end

function stx_flight_software_simulator::_create_single_time_axis_entry, update_frequency=update_frequency, lookahead=lookahead
  default, lookahead, 0

  self->getproperty, time_bin_width=time_bin_width, current_bin=current_bin
  time_bin_end = time_bin_width * (current_bin + 1)
  return, stx_construct_time_axis([time_bin_end - update_frequency + (lookahead * time_bin_width), time_bin_end + (lookahead * time_bin_width)])
end

;+
; :HISTORY:
;   30-Jun-2015 - Laszlo I. Etesi (FHNW), changed CFL module execution: passing in a sequence of backgrounds
;   07-Jul-2015 - Laszlo I. ETesi (FHNW), added finalize_processing keyword to tell the pipeline that this is the last data bin
;-
pro stx_flight_software_simulator::_process, eventlist, triggerlist, plotting=plotting, finalize_processing=finalize_processing, _extra=extra
  default, finalize_processing, 0b

  ; extract time_bin and timing information
  ;time_bin_start = ((*self.internal_state).current_relative_start_time)
  ;time_bin_end = stx_construct_time(time=((*self.internal_state).current_relative_start_time) + ((*self.internal_state).time_bin_width))
  ;absolute_start_time = (*self.internal_state).absolute_start_time
  ;absolute_bin_start_time = stx_time_add(absolute_start_time, seconds=time_bin_start)
  ;absolute_bin_end_time = stx_time_add(absolute_start_time, add_time=time_bin_end)

  self->getproperty, current_time=current_time, time_bin_width=time_bin_width ;, current_time_bin=current_time_bin

  ; >>> TEMPERATURE CORRECTION, every time_bin

  ad_temperature_corrected_eventlist = self->_execute_module( $
    module='stx_fsw_module_ad_temperature_correction', $
    eventlist=eventlist)

  ; <<< TEMPERATURE CORRECTION

  ; >>> CALIBRATION SPECTRUM ACCUMULATION

  calibration_spectrum = self->_execute_module( $
    module='stx_fsw_module_accumulate_calibration_spectrum', $
    ad_temperature_corrected_eventlist=ad_temperature_corrected_eventlist, $
    absolute_bin_start_time=current_time, $
    absolute_bin_end_time=stx_time_add(current_time, seconds=time_bin_width))

  ; <<< CALIBRATION SPECTRUM ACCUMULATION

  ; >>> AD TO SCIENCE CHANNEL CONVERSION

  calibrated_detector_eventlist = self->_execute_module( $
    module='stx_fsw_module_convert_science_data_channels', $
    ad_temperature_corrected_eventlist=ad_temperature_corrected_eventlist)

  ; <<< AD TO SCIENCE CHANNEL CONVERSION

  ; <<< QUICKLOOK ACCUMULATION

  quicklook_accumulators = self->_execute_module( $
    module='stx_fsw_module_quicklook_accumulation', $
    calibrated_detector_eventlist=calibrated_detector_eventlist, $
    triggerlist=triggerlist, $
    time_bin_start=current_time)

  ; >>> QUICKLOOK ACCUMULATION

  ; >>> ARCHIVE BUFFER ACCUMULATION

  archive_buffer_result = self->_execute_module( $
    module='stx_fsw_module_eventlist_to_archive_buffer', $
    calibrated_detector_eventlist=calibrated_detector_eventlist, $
    finalize_processing=finalize_processing, $
    triggerlist=triggerlist)

  ; <<< ARCHIVE BUFFER ACCUMULATION

  ; >>> TRIGGER ACCUMULATORS (LIVETIME)

  ; triggers are implicitly calculated in archive buffer module

  ; <<< TRIGGER ACCUMULATORS (LIVETIME)

  ; >>> QUICKLOOK ACCUMULATOR UPDATE

  self->_update_quicklook_accumulator, accumulators=quicklook_accumulators

  ; << QUICKLOOK ACCUMULATOR UPDATE
  
  
  ; read the rate control regime state from last round
  self->getproperty, current_rcr=rate_control_regime
 
  ; >>> FLARE DETECTION

  flare_flag = self->_execute_module( $
    module='stx_fsw_module_flare_detection', $
    rate_control_regime=rate_control_regime $
    )

  ; <<< FLARE DETECTION

  ; >>> COARSE FLARE LOCATOR

  flare_location = self->_execute_module( $
    module='stx_fsw_module_coarse_flare_locator' $
    )

  ; <<< COARSE FLARE LOCATOR

  ; >>> BACKGROUND MONITOR

  flare_location = self->_execute_module( $
    module='stx_fsw_module_background_determination', $
    flare_flag=flare_flag $
    )

  ; <<< BACKGROUND MONITOR

  ; >>> DETECTOR MONITOR

  flare_location = self->_execute_module( $
    module='stx_fsw_module_detector_monitor', $
    flare_flag=flare_flag $
    )

  ; <<< DETECTOR MONITOR

  ; >>> VARIANCE

  flare_location = self->_execute_module( $
    module='stx_fsw_module_variance_calculation' $
    )

  ; <<< VARIANCE
  
  
  ; >>> RATE CONTROL REGIME

  rate_control_regime = self->_execute_module( $
    module='stx_fsw_module_rate_control_regime' $
    )

  ; <<< RATE CONTROL REGIME
  
end


; *************************************** ROUTINES NOT OPTIMIZED YET ***************************************************
; |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
; v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v





pro stx_flight_software_simulator::cleanup
  ; TODO: check if we need to clean up the state
  destroy, self.internal_state
  destroy, self.modules

  ; Call our superclass Cleanup method
  self->ppl_processor::cleanup
end

pro stx_flight_software_simulator::getproperty, $
  current_bin=current_bin, $
  current_time=current_time, $
  reference_time=reference_time, $
  relative_time=relative_time, $
  time_bin_width=time_bin_width, $
  current_rcr=current_rcr, $

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
  stx_fsw_total_source_counts=stx_fsw_total_source_counts, $

  stx_fsw_m_flare_flag=stx_fsw_m_flare_flag, $
  stx_fsw_m_rate_control_regime=stx_fsw_m_rate_control_regime, $
  stx_fsw_m_calibration_spectrum=stx_fsw_m_calibration_spectrum, $
  stx_fsw_m_background=stx_fsw_m_background, $
  stx_fsw_m_variance=stx_fsw_m_variance, $
  stx_fsw_m_detector_monitor=stx_fsw_m_detector_monitor, $
  stx_fsw_m_coarse_flare_location=stx_fsw_m_coarse_flare_location, $
  stx_fsw_m_archive_buffer_group=stx_fsw_m_archive_buffer_group, $
  stx_fsw_m_lightcurve=stx_fsw_m_lightcurve, $
  
  
  temperature_corrected_eventlist=temperature_corrected_eventlist, $
  stx_sim_calibrated_detector_eventlist=stx_sim_calibrated_detector_eventlist, $
  archive_buffer_leftovers=archive_buffer_leftovers, $
  triggerlist_leftovers=triggerlist_leftovers, $
  ;archive_buffer_total_counts=archive_buffer_total_counts, $
  ;flare_detection_context=flare_detection_context, $
  ;stx_fsw_m_noisy_detectors=stx_fsw_m_noisy_detectors, $
  ;archive_buffer_timing=archive_buffer_timing, $
  most_n_recent=most_n_recent, $
  complete=complete, $
  combine=combine

  if(~isvalid(self)) then return

  default, most_n_recent, 1
  default, complete, 0

  if(arg_present(current_bin)) then current_bin = (*self.internal_state).current_bin
  if(arg_present(current_rcr)) then current_rcr = (self->_read_data(product_type='stx_fsw_m_rate_control_regime', /most_n_recent))
  if(arg_present(current_time)) then current_time = (*self.internal_state).current_time
  if(arg_present(reference_time)) then reference_time = (*self.internal_state).reference_time
  if(arg_present(relative_time)) then relative_time = (*self.internal_state).relative_time
  if(arg_present(time_bin_width)) then time_bin_width = (*self.internal_state).time_bin_width

  if(arg_present(stx_fsw_ql_lightcurve)) then stx_fsw_ql_lightcurve = self->_read_data(product_type='stx_fsw_ql_lightcurve', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_lightcurve)) then stx_fsw_ql_lt_lightcurve = self->_read_data(product_type='stx_fsw_ql_lightcurve_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_spectra)) then stx_fsw_ql_spectra = self->_read_data(product_type='stx_fsw_ql_spectra', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_spectra)) then stx_fsw_ql_lt_spectra = self->_read_data(product_type='stx_fsw_ql_spectra_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_bkgd_monitor)) then stx_fsw_ql_bkgd_monitor = self->_read_data(product_type='stx_fsw_ql_bkgd_monitor', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_bkgd_monitor)) then stx_fsw_ql_lt_bkgd_monitor = self->_read_data(product_type='stx_fsw_ql_bkgd_monitor_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_variance)) then stx_fsw_ql_variance = self->_read_data(product_type='stx_fsw_ql_variance', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_variance)) then stx_fsw_ql_lt_variance = self->_read_data(product_type='stx_fsw_ql_variance_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_flare_detection)) then stx_fsw_ql_flare_detection = self->_read_data(product_type='stx_fsw_ql_flare_detection', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_flare_detection)) then stx_fsw_ql_lt_flare_detection = self->_read_data(product_type='stx_fsw_ql_flare_detection_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_flare_location_1)) then stx_fsw_ql_flare_location_1 = self->_read_data(product_type='stx_fsw_ql_flare_location_1', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_flare_location_1)) then stx_fsw_ql_lt_flare_location_1 = self->_read_data(product_type='stx_fsw_ql_flare_location_1_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_flare_location_2)) then stx_fsw_ql_flare_location_2 = self->_read_data(product_type='stx_fsw_ql_flare_location_2', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_flare_location_2)) then stx_fsw_ql_lt_flare_location_2 = self->_read_data(product_type='stx_fsw_ql_flare_location_2_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_detector_anomaly)) then stx_fsw_ql_detector_anomaly = self->_read_data(product_type='stx_fsw_ql_detector_anomaly', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_detector_anomaly)) then stx_fsw_ql_lt_detector_anomaly = self->_read_data(product_type='stx_fsw_ql_detector_anomaly_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_quicklook)) then stx_fsw_ql_quicklook = self->_read_data(product_type='stx_fsw_ql_quicklook', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_ql_lt_quicklook)) then stx_fsw_ql_lt_quicklook = self->_read_data(product_type='stx_fsw_ql_quicklook_lt', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)


  if(arg_present(stx_fsw_total_source_counts)) then stx_fsw_total_source_counts = self->_read_data(product_type='stx_fsw_total_source_counts', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_archive_buffer_group)) then stx_fsw_m_archive_buffer_group = self->_read_data(product_type='stx_fsw_m_archive_buffer_group', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_flare_flag)) then stx_fsw_m_flare_flag = self->_read_data(product_type='stx_fsw_m_flare_flag', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=['context'])
  if(arg_present(stx_fsw_m_rate_control_regime)) then stx_fsw_m_rate_control_regime = self->_read_data(product_type='stx_fsw_m_rate_control_regime', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  ;if(arg_present(stx_fsw_m_archive_buffer)) then stx_fsw_m_archive_buffer = self->_read_data(product_type='stx_fsw_m_archive_buffer', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_calibration_spectrum)) then stx_fsw_m_calibration_spectrum = self->_read_data(product_type='stx_fsw_m_calibration_spectrum', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_detector_monitor)) then stx_fsw_m_detector_monitor = self->_read_data(product_type='stx_fsw_m_detector_monitor', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_coarse_flare_location)) then stx_fsw_m_coarse_flare_location = self->_read_data(product_type='stx_fsw_m_coarse_flare_location', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_fsw_m_trigger_accumulator)) then stx_fsw_m_trigger_accumulator = self->_read_data(product_type='stx_fsw_m_trigger_accumulator', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(temperature_corrected_eventlist)) then temperature_corrected_eventlist = self->_read_data(product_type='temperature_corrected_eventlist', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(stx_sim_calibrated_detector_eventlist)) then stx_sim_calibrated_detector_eventlist = self->_read_data(product_type='stx_sim_calibrated_detector_eventlist', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(archive_buffer_leftovers)) then archive_buffer_leftovers = self->_read_data(product_type='archive_buffer_leftovers', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  if(arg_present(triggerlist_leftovers)) then triggerlist_leftovers = self->_read_data(product_type='triggerlist_leftovers', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  
  ;special case for lightcurve
  ;there is no lightcurve module so input is equal output
  if(arg_present(stx_fsw_m_lightcurve)) then begin
    self->getproperty, stx_fsw_ql_lightcurve=lq, stx_fsw_ql_lt_lightcurve = lq_lt, stx_fsw_m_rate_control_regime=rcr, most_n_recent=most_n_recent, combine=combine, complete=complete
    
    stx_fsw_m_lightcurve = {$
      type                : 'stx_fsw_m_lightcurve', $
      time_axis           : lq.time_axis, $
      accumulated_counts  : lq.accumulated_counts, $ 
      rcr                 : rcr.rcr, $
      triggers            : lq_lt.accumulated_counts, $
      DETECTOR_MASK       : lq.DETECTOR_MASK, $
      PIXEL_MASK          : lq.PIXEL_MASK, $
      ENERGY_AXIS         : lq.ENERGY_AXIS $
    }
    
  end
  
  if(arg_present(stx_fsw_m_background)) then begin
    stx_fsw_m_background = self->_read_data(product_type='stx_fsw_m_background', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
    self->getproperty, stx_fsw_ql_bkgd_monitor=bg, stx_fsw_ql_lt_bkgd_monitor=bg_lt, most_n_recent=most_n_recent, combine=combine, complete=complete
    
    n_t = n_elements(stx_fsw_m_background.time_axis.duration) - 1
    
    stx_fsw_m_background = add_tag(stx_fsw_m_background, bg_lt.accumulated_counts[0:n_t], "triggers")
    stx_fsw_m_background = add_tag(stx_fsw_m_background, bg.detector_mask[0:n_t], "detector_mask")
    stx_fsw_m_background = add_tag(stx_fsw_m_background, bg.pixel_mask[0:n_t], "pixel_mask")
    stx_fsw_m_background = add_tag(stx_fsw_m_background, bg.energy_axis, "energy_axis")
    
  end
  
  if(arg_present(stx_fsw_m_variance)) then begin
    stx_fsw_m_variance = self->_read_data(product_type='stx_fsw_m_variance', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
    self->getproperty, stx_fsw_ql_variance=va, stx_fsw_ql_lt_variance=va_lt, most_n_recent=most_n_recent, combine=combine, complete=complete

    n_t = n_elements(stx_fsw_m_variance.time_axis.duration) - 1

    stx_fsw_m_variance = add_tag(stx_fsw_m_variance, va_lt.accumulated_counts[0:n_t], "triggers")
    stx_fsw_m_variance = add_tag(stx_fsw_m_variance, va.detector_mask[0:n_t], "detector_mask")
    stx_fsw_m_variance = add_tag(stx_fsw_m_variance, va.pixel_mask[0:n_t], "pixel_mask")
    stx_fsw_m_variance = add_tag(stx_fsw_m_variance, va.energy_axis, "energy_axis")
    stx_fsw_m_variance = add_tag(stx_fsw_m_variance, (size(va.accumulated_counts, /dimensions))[0], "var_times")
  end
  
  
  ;if(arg_present(archive_buffer_total_counts)) then archive_buffer_total_counts = self->_read_data(product_type='archive_buffer_total_counts', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  ;if(arg_present(flare_detection_context)) then flare_detection_context = self->_read_data(product_type='flare_detection_context', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  ;if(arg_present(stx_fsw_m_noisy_detectors)) then stx_fsw_m_noisy_detectors = self->_read_data(product_type='stx_fsw_m_noisy_detectors', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)
  ;if(arg_present(archive_buffer_timing)) then archive_buffer_timing = self->_read_data(product_type='archive_buffer_timing', most_n_recent=most_n_recent, combine=combine, complete=complete, ignore_tags=ignore_tags)

  ;  step=step, $
  ;  clock_duration=clock_duration, $
  ;  flare_flag=flare_flag, $
  ;  archive_buffer=archive_buffer, $
  ;  rate_control=rate_control, $
  ;  current_time=current_time, $
  ;  calib_spectra = calib_spectra, $
  ;  start_time=start_time, $
  ;  background=background, $
  ;  total_counts = total_counts, $
  ;  variance=variance, $
  ;  active_detectors=active_detectors, $
  ;  coarse_flare_location=coarse_flare_location, $
  ;  ql_data=ql_data, $
  ;  livetime = livetime, $
  ;  open_tasks = open_tasks, $
  ;  calibrated_detector_events=calibrated_detector_events
  ;
  ;
  ;  compile_opt IDL2
  ;
  ;  ; If "self" is defined, then this is an "instance".
  ;  if (isa(self)) then begin
  ;    ; User asked for an "instance" property.
  ;    if arg_present(step)                 then step = self.step
  ;    if arg_present(clock_duration)        then clock_duration = self->get(/clock_duration)
  ;
  ;    if arg_present(flare_flag)            then flare_flag = self->_pack_result("flare_flag")
  ;    if arg_present(archive_buffer)        then archive_buffer = (self.results)["archive_buffer"]->toarray()
  ;    if arg_present(rate_control)          then rate_control = self->_pack_result("rate_control")
  ;    if arg_present(total_counts)          then total_counts = self->_pack_result("total_counts")
  ;    if arg_present(calib_spectra)         then calib_spectra = self->_pack_result("calib_spectra")
  ;    if arg_present(livetime)              then livetime = self->_pack_result("livetime")
  ;    if arg_present(background)            then begin
  ;      background = self->_pack_result("background")
  ;      background = add_tag(background, (self.results)["ql_data", "stx_fsw_ql_bkgd_monitor", -1].energy_axis, "energy_axis")
  ;    end
  ;    if arg_present(coarse_flare_location) then coarse_flare_location = self->_pack_result("coarse_flare_location")
  ;    if arg_present(variance)              then variance = self->_pack_result("variance")
  ;    if arg_present(active_detectors)      then active_detectors = self->_pack_result("active_detectors")
  ;    if arg_present(ql_data)               then ql_data = (self.results)["ql_data"]
  ;
  ;    if arg_present(current_time)          then current_time = stx_time_add((*self.start_time), seconds=(self->get(/clock_duration)*self.step))
  ;    if arg_present(start_time)            then start_time = *self.start_time
  ;    if arg_present(open_tasks)            then open_tasks = (self.accumulator)->keys()
  ;    if arg_present(calibrated_detector_events) then calibrated_detector_events = self->_pack_result('calibrated_detector_events')
  ;  endif
end

function stx_flight_software_simulator::_generate_time_axis, most_n_recent=most_n_recent
  self->getproperty, reference_time=reference_time, current_bin=current_bin, time_bin_width=time_bin_width

  if(current_bin eq 0) then return, !NULL

  return, stx_construct_time_axis(stx_time2any(reference_time) + dindgen(current_bin+1) * time_bin_width)
end

; :HISTORY:
;   02-Jul-2015 - Aidan O'Flannagain (TCD), requested result will now always be converted to an array,
;       which will prevent the output to be unintentionally transposed when there is only one result

function stx_flight_software_simulator::_pack_result, key
  compile_opt IDL2, HIDDEN

  self->getproperty, current_time=current_time

  ;TODO: ensure this commented line isn't needed and remove it.
  ;result = n_elements((self.results)[key]) gt 1 ? (self.results)[key]->toArray() : ((self.results)[key])[0]
  result = n_elements((self.results)[key]) gt 0 ? (self.results)[key]->toarray() : !VALUES.f_nan
  t_axis = stx_construct_time_axis( n_elements((self.times)[key]) gt 1 ? (self.times)[key]->toarray() : [*self.start_time, current_time])

  return, { type      : "stx_fsw_result_"+key ,$
    data      : result ,$
    time_axis : t_axis $
  }
end

pro stx_flight_software_simulator::setproperty
  ;, $
  ;  step=step, $
  ;  flare_flag=flare_flag, $
  ;  archive_buffer=archive_buffer, $
  ;  rate_control=rate_control, $
  ;  calib_spectra=calib_spectra, $
  ;  start_time=start_time, $
  ;  background=background, $
  ;  variance=variance, $
  ;  active_detectors=active_detectors, $
  ;  coarse_flare_location=coarse_flare_location
  ;  compile_opt IDL2
  ;
  ;  ; If user passed in a property, then set it.
  ;  if (isa(step,/number))                 then self.step = step
  ;
  ;  if (isa(flare_flag, /array))            then (self.results)["flare_flag"] = list(flare_flag, /extract, /no_copy)
  ;  if (isa(flare_flag, 'LIST'))            then (self.results)["flare_flag"] = flare_flag
  ;
  ;  if (isa(archive_buffer, /array))        then (self.results)["archive_buffer"] = list(archive_buffer, /extract, /no_copy)
  ;  if (isa(archive_buffer, 'LIST'))        then (self.results)["archive_buffer"] = archive_buffer
  ;
  ;  if (isa(rate_control, /array))          then (self.results)["rate_control"] = list(rate_control, /extract, /no_copy)
  ;  if (isa(rate_control, 'LIST'))          then (self.results)["rate_control"] = rate_control
  ;
  ;  if (isa(calib_spectra, /array))         then (self.results)["calib_spectra"] = list(calib_spectra)
  ;  if (isa(calib_spectra, 'LIST'))         then (self.results)["calib_spectra"] = calib_spectra
  ;
  ;  if (isa(background, /array))            then (self.results)["background"] = list(background)
  ;  if (isa(background, 'LIST'))            then (self.results)["background"] = background
  ;
  ;  if (isa(variance, /array))              then (self.results)["variance"] = list(variance)
  ;  if (isa(variance, 'LIST'))              then (self.results)["variance"] = variance
  ;
  ;  if (isa(active_detectors, /array))      then (self.results)["active_detectors"] = list(active_detectors)
  ;  if (isa(active_detectors, 'LIST'))      then (self.results)["active_detectors"] = active_detectors
  ;
  ;  if (isa(coarse_flare_location, /array)) then (self.results)["coarse_flare_location"] = list(coarse_flare_location)
  ;  if (isa(coarse_flare_location, 'LIST')) then (self.results)["coarse_flare_location"] = coarse_flare_location
  ;
  ;  if (ppl_typeof(start_time, compareto='stx_time')) then self.start_time = ptr_new(start_time)

end

function stx_flight_software_simulator::getconfigmanager
  return, *((*self.internal_state).configuration_manager)
end  

function stx_flight_software_simulator::getdata, input_data=input_data, output_target=output_target, solo_packets=solo_packets, _extra=extra
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
        return, error
      endif
    endif
  endif

  default, output_target, 'GetProperty'

  case (output_target) of
    'stx_fsw_flare_selection_result': begin
      return, self->_flare_selection()
    end
    'stx_fsw_ql_spectra': begin
         self->getproperty, stx_fsw_ql_spectra=ql_spectra, stx_fsw_ql_lt_spectra=lt_spectra, stx_fsw_m_rate_control = rate_control,  /complete, /combine
         
         
         spec_in = { $
            rcr              : rate_control, $
            spectra          : ql_spectra, $
            spectra_lt       : lt_spectra $
         }
         
         suc = (self.modules)["stx_fsw_module_reduce_ql_spectra"]->execute(spec_in, comp_data, self.history, ((*self.internal_state).configuration_manager))
         return, comp_data
    end
    'stx_fsw_ivs_result': begin
      flare_list = ppl_typeof(input_data, compareto="stx_fsw_flare_list_entry") ? input_data : self->_flare_selection()

      self->getproperty,   /complete, /combine,  $
        stx_fsw_m_archive_buffer_group = archive_buffer_group, $
        stx_fsw_m_detector_monitor = detector_monitor, $
        stx_fsw_m_rate_control = rate_control, $
        stx_fsw_m_coarse_flare_location = coarse_flare_location, $
        reference_time = reference_time

      comp_data_flares = list()

      foreach flare, flare_list do begin
        
        if ~flare.ended then continue
        
        ;crop the archive buffer to the current processed event
        flare_ab = stx_fsw_crop_archive_buffer(archive_buffer_group, reference_time, flare.fstart, flare.fend)


        ivs_result = self->_ivs(flare_ab, start_time = flare.fstart, end_time=flare.fend)

        ;compress archive buffer
        dcom_in = { $
          archive_buffer        : flare_ab, $
          triggers              : archive_buffer_group.triggers, $
          rcr                   : rate_control, $
          cfl                   : coarse_flare_location, $
          detector_monitor      : detector_monitor, $
          archive_buffer_times  : ivs_result.ab_time_edges, $
          ivs_intervals_img     : ivs_result.intervals_img, $
          ivs_intervals_spc     : ivs_result.intervals_spc, $
          count_spectrogram     : ivs_result.count_spectrogram ,$
          pixel_count_spectrogram : ivs_result.pixel_count_spectrogram ,$
          flare_start           : flare.fstart, $
          flare_end             : flare.fend, $
          start_time            : reference_time $
        }
        suc = (self.modules)["stx_fsw_module_data_compression"]->execute(dcom_in, comp_data, self.history, ((*self.internal_state).configuration_manager))

        ;        ivs_result = add_tag(ivs_result, ab[flare_ab_idx], 'archive_buffer')
        ;
        ;        ;convert pixel data to summed pixel
        ;        suc = (self.modules)["psum"]->execute(ivs_result.IMG_COMBINED_ARCHIVE_BUFFER, sum_pixel, self.history, configuration_manager)
        ;        ivs_result = add_tag(ivs_result, sum_pixel, 'IMG_COMBINED_SUMMED_PIXEL')
        ;
        ;        ;convert summed pixel visibility
        ;        ivs_result = add_tag(ivs_result, "vis", 'IMG_COMBINED_VISIBILTIES')

        comp_data_flares->add, comp_data, /no_copy
      endforeach

      case (n_elements(comp_data_flares)) of
        0:    return, []
        1:    return, comp_data_flares[0]
        else: return, comp_data_flares
      endcase
    end
    'stx_fsw_ascpect': begin
      default, summing,  tag_exist(extra, "summing", /quiet) ? extra.summing : 100
      
      self->getproperty, reference_time = start_time, current_time = end_time
      
      duration = stx_time_diff(start_time, end_time, /abs )
      times = duration / double(summing) * 1000
      edges = indgen(times+1, /double)*(summing/1000d)
      time_axis = stx_construct_time_axis(stx_time_add(start_time,seconds=edges))
      
      cha1=indgen(times)
      cha2=indgen(times)*2
      chb1=indgen(times)*3
      chb2=indgen(times)*4
            
      ;aspect = stx_fsw_m_aspect(time_axis=time_axis, summing=summing,cha1=cha1, cha2=cha2,chb1=chb1,chb2=chb2)
      
      return, aspect 
      
    end
    
    'stx_fsw_tmtc': begin
      
      sd_all = tag_exist(extra, "sd_all", /quiet)
      ql_all = tag_exist(extra, "ql_all", /quiet)
      
      tmtc_in = { $
        fsw : self, $
        filename                : tag_exist(extra, "filename", /quiet) ? extra.filename : "", $
        ql_light_curves         : tag_exist(extra, "ql_light_curves", /quiet) OR ql_all, $ 
        ql_background_monitor   : tag_exist(extra, "ql_background_monitor", /quiet) OR ql_all, $
        ql_calibration_spectrum : tag_exist(extra, "ql_calibration_spectrum", /quiet) OR ql_all, $
        ql_flare_flag_location  : tag_exist(extra, "ql_flare_flag_location", /quiet) OR ql_all, $
        ql_spectra              : tag_exist(extra, "ql_spectra", /quiet) OR ql_all, $
        ql_variance             : tag_exist(extra, "ql_variance", /quiet) OR ql_all, $
        sd_xray_0               : tag_exist(extra, "sd_xray_0", /quiet) OR sd_all, $
        sd_xray_1               : tag_exist(extra, "sd_xray_1", /quiet) OR sd_all, $
        sd_xray_2               : tag_exist(extra, "sd_xray_2", /quiet) OR sd_all, $
        sd_xray_3               : tag_exist(extra, "sd_xray_3", /quiet) OR sd_all, $
        sd_spectrogram          : tag_exist(extra, "sd_spectrogram", /quiet) OR sd_all $
      }  
      
      if tag_exist(extra, "rel_flare_time", /quiet) then tmtc_in = add_tag(tmtc_in, extra.rel_flare_time, "rel_flare_time")  
      
      suc = (self.modules)["stx_fsw_module_tmtc"]->execute(tmtc_in, tmtc_out, self.history, ((*self.internal_state).configuration_manager))
      if arg_present(solo_packets) then solo_packets = tmtc_out.solo_packets
      return, tmtc_out.data
    end  
    
    else: begin
      return, self->_read_data(product_type=output_target)
    end
  endcase
end

function stx_flight_software_simulator::_ivs, flare_ab, start_time=start_time, end_time=end_time
  compile_opt IDL2, HIDDEN

  self->getproperty, reference_time = reference_time, current_time  = current_time, $
    stx_fsw_m_detector_monitor = detector_monitor, $
    stx_fsw_m_rate_control = rate_control, $
    stx_fsw_ql_lightcurve = lightcurve, $
    stx_fsw_m_coarse_flare_location = coarse_flare_location, $
    stx_fsw_m_background = background, $
    /complete, /combine

  default, start_time, reference_time
  default, end_time, current_time

  if n_elements(flare_ab) lt 1 then return, ppl_construct_error("no archive buffer data to combine in ivs")

  print, "run IVS: "
  ptim, start_time.value, end_time.value
  duration = stx_time_diff(start_time,end_time,/ABS )
  print, "duration: ", duration



  ;chop rcr data to current flare time
  rcr_flare = stx_fsw_crop_rcr(rate_control, start_time, end_time)

  bkg_flare = where(stx_time_le(background.time_axis.time_start, end_time), bkg_flare_count)
  ;use the backgroundvalue closest before the flare
  bkg_flare = max(bkg_flare)
  assert_true, bkg_flare_count gt 0

  active_detectors_flare = where(stx_time_ge(detector_monitor.time_axis.time_start, start_time), ad_flare_count)
  assert_true, ad_flare_count gt 0
  ;take the first active detector entry as constant for the entire flare
  ;the list of active detectors should not change within a flare anyway
  active_detectors_flare = reform(detector_monitor.active_detectors[*, max(active_detectors_flare)])

  ;remove yellow flags
  ;active_detectors_flare = active_detectors_flare eq 1 or active_detectors_flare eq 11

  ;self->getproperty, flare_flag=ff
  ;utplot, ff.time_axis.time_start.value, ff.data, psym=10, yrange=[0,2]
  ;outplot, rcr_data.time_axis.time_start.value, rcr_data.data.rcr+1.5
  ;outplot, replicate(start_time.value,2) , [1.8,1.9]
  ;outplot, replicate(end_time.value,2) , [1.8,1.9]

  ;TODO N.H. remove later just for testing purposes
  ;rcr_flare.rcr[14:20] = 1
  ;rcr_flare.rcr[21:-1] = 2

  ivs_in = {archive_buffer        : flare_ab ,$
    start_time            : reference_time, $
    rcr                   : rcr_flare.rcr, $
    rcr_time_axis         : rcr_flare.time_axis, $
    active_detectors      : active_detectors_flare, $
    background            : reform(background.background[*,bkg_flare]), $
    background_energy_axis: lightcurve.energy_axis      $
  }
  success = (self.modules)["stx_fsw_module_intervalselection_img"]->execute(ivs_in ,ivs_img_out, self.history,  ((*self.internal_state).configuration_manager))

  success = (self.modules)["stx_fsw_module_intervalselection_spc"]->execute(ivs_img_out ,ivs_spc_out, self.history, ((*self.internal_state).configuration_manager))


  print, "Intervals IMG:",  n_elements(ivs_img_out.intervals)
  print, "Intervals SPC:",  n_elements(ivs_spc_out.intervals)

  ivs_out = {type : 'stx_fsw_ivs_result', $
    intervals_img           : ivs_img_out.intervals,  $
    intervals_spc           : ivs_spc_out.intervals, $
    count_spectrogram       : ivs_img_out.count_spectrogram ,$
    pixel_count_spectrogram : ivs_img_out.pixel_count_spectrogram ,$
    ab_time_edges           : ivs_img_out.ab_time_edges $
  }

  return, ivs_out

end


function stx_flight_software_simulator::_flare_selection
  compile_opt IDL2, HIDDEN



  self->getproperty, stx_fsw_m_flare_flag = flare_flag, stx_fsw_m_coarse_flare_location=cfl, /complete, /combine

  if n_elements(flare_flag.time_axis.duration) lt 1 then begin
    message, "no data to process", /continue
    return, -1
  end
  
  flare_list_in = { $
     flare_flag : flare_flag, $
     cfl : cfl $ 
  }
  
  succes = (self.modules)["stx_fsw_module_flare_selection"]->execute(flare_list_in, flare_times, self.history, ((*self.internal_state).configuration_manager))

  return, flare_times
end



pro stx_flight_software_simulator__define
  void = { stx_flight_software_simulator, $
    modules                   : hash(), $
    history                   : ppl_history(), $
    inherits        ppl_processor  $
  }
end