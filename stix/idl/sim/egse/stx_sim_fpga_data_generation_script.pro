;+
; :description:
;   transforms the ASW/FSW SIM format (32x12x32 [e,p,d]) to the FPGA format (12x32x32 [p,d,e])
;-
function _transform_32x12x32to12x32x32, acc_32x12x32, n_times=n_times
  ; extract dimensions
  acc_dim = size(acc_32x12x32.accumulated_counts)
  n_energies = acc_dim[1]
  n_pixels = acc_dim[2]
  n_detectors = acc_dim[3]
  n_times = acc_dim[0] eq 4 ? acc_dim[4] : 1

  ; the accumulators format is e(32), p(12), d(32), t(N); but the desired
  ; FPGA format is p(12), D(32), E(32), t(N)
  ; copy accumulator structure
  acc_12x32x32 = { $
    type                : 'all123232', $
    time_axis           : acc_32x12x32.time_axis, $
    energy_axis         : acc_32x12x32.energy_axis, $
    accumulated_counts  : ulonarr(12,32,32,n_times) $
  }

  ; stupid copy-over of counts
  for nt_i = 0L, n_times-1 do begin
    for e_i = 0L, n_energies-1 do begin
      for p_i = 0L, n_pixels-1 do begin
        for d_i = 0L, n_detectors-1 do begin
          acc_12x32x32.accumulated_counts[p_i, d_i, e_i, nt_i] = acc_32x12x32.accumulated_counts[e_i, p_i, d_i, nt_i]
        endfor
      endfor
    endfor
  endfor

  return, acc_12x32x32
end

;+
; :description:
;   This function converts a hex string to a binary/array mask.
;   The hex string is interpreted as LSB to MSB -> array_idx_0 to array_idx_n -> det_id_0 - det_id_n (same for detectors, pixels, energiers)
;   0x1 -> [1,0,0,...,0], detector id 1
;   0x80000000 -> [0,0,0,...,1], detector id 32
;   
; :params:
;   hex : in, required, type='string'
;     This is the hex string to be converted to a mask; max lenght is 8 digits
;   
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the mask will have length 12, otherwise length 32
; 
; :returns:
;   A 12 or 32 element array with ones and zeros used as a mask for 
;   enabling/disabling detectors, pixels, or energies
;-
function _str_hex2byte_mask, hex, pixel=pixel
  default, range, [0,-1]
  
  if(keyword_set(pixel)) then range = [0, 11]
  
  number = 0L
  reads, hex, number, format='(Z)'
  
  stx_telemetry_util_encode_decode_structure, input=number, detector_mask=mask
  
  return, (reverse(mask))[range[0]:range[1]]
end

;+
; :description:
;   Reverse function to _str_hex2_byte_mask
;   
; :params:
;   mask : in, required, type='bytarr(12) or bytarr(32)'
;     This is the array to be converted to a list of ids
;
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the resulting hex string will be of length 3, otherwise 8
;
; :returns:
;   An ASCII representation in hex of the input mask
;-
function _byte_mask2hex_str, mask, pixel=pixel
  default, pad, 8
  
  if(keyword_set(pixel)) then pad = 3
  
  stx_telemetry_util_encode_decode_structure, output=number, detector_mask=reverse(mask)
  
  return, to_hex(number, pad)
end

;+
; :description:
;   This routine converts a mask to an array of selected ids
;   The mask is interpreted as such: [1,0,0,...,9] -> id 1 (for detectors/energies)
;   or id 0 for pixels
;   
; :params:
;   mask : in, required, type='bytarr(12) or bytarr(32)'
;     This is the array to be converted to a list of ids
;
; :keywords:
;   pixel : in, optional, type='boolean', default='0'
;     If set, the ids are not shifted, otherwise ids are shifted
;     by 1 (det/chnl: 1-32, pxl: 0-11)
;
; :returns:
;   An array of ids
;-
function _mask2id, mask, pixel=pixel
  default, shft, 1
  if(keyword_set(pixel)) then shft = 0
  
  ids = where(mask eq 1, count) + shft
  
  if(count eq 0) then return, -1 $
  else if(n_elements(ids) eq 1) then return, ids[0] $
  else return, ids
end

;+
; :description:
;   This routine converts an array of numbers to a compact array of strings
;
; :params:
;   arr : in, required, type='array of numbers'
;     This is the array to be converted to an array of strings
;
; :returns:
;   A compact array of strings
;-
function _pretty_nbr_array, arr
  return, '[' + trim(arr2str(trim(string(fix(arr))), delim=',')) + ']'
end
;+
; :file_comments:
;   The purpose of this file is to provide routines to automatically (re-)generate
;   test input data for the FPGA testing; the routine 'stx_sim_fpga_data_generation_script'
;   (see below) contains the test descriptions with the input specification, links to ELUT and TLUT,
;   etc.; at several points in time, sanity checks are executed to verify the data integrity
;   and consistency (as far as this can be verified).
;   NB: All ELUT, TLUT, detector counts, output files, rotating buffer structures, etc. are assumed
;   to be in subcollimator numbering format!
;   
;   The following files are required:
;   * ELUT
;   * TLUT
;   * Sequences
;   
;   The following output files are generated (per test):
;   * TEST_NAME.log : this is an overview file, showing some key information s.a. number of counts, etc.
;   * TEST_NAME_rotating_buffer.bin : this file contains the actual binary rotating buffer data
;   * TEST_NAME_rotating_buffer.log : this file contains an ASCII printout of the rotating buffer
;   * TEST_NAME.dssevs : this file contains the test sequence (counts) in the Detector Simulation (DSS) format (binary)
;   * TEST_NAME_accumulators_ACC_NUMBER.log : this file contains the contents of the 12 x 32 x 32 accumulator cells (pixel, detector, channel) (block: channel, left: pixel, down: detector)
;
; :categories:
;   Flight software simulation, data export, FPGA testing
;
; :examples:
;   stx_sim_fpga_data_generation_script
;
; :history:
;   22-Jul-2015 - Laszlo I. Etesi (FHNW), initial release (later: added accumulator cells ASCII printout and replaced close with free_lun)
;   27-Jul-2015 - Laszlo I. Etesi (FHNW), changed accumulators from e(32) x p(12) x d(32) x t(n) to p(12) x d(32) x e(32) x t(n)
;   28-Jul-2015 - Laszlo I. Etesi (FHNW), added the configuration manager to set parameters
;   04-Aug-2015 - Laszlo I. Etesi (FHNW), updated file list (writing out binary files, big endian!), bugfixes
;   13-Aug-2015 - Laszlo I. Etesi (FHNW), - fixed endianness
;                                         - removed the log file generation
;                                         - added (hard-coded) option for setting a start time
;                                         - mapping detectors to FPGA scheme 
;   20-Aug-2015 - Laszlo I. Etesi (FHNW), - added readout time and latency time as parameters
;   25-Aug-2015 - Laszlo I. Etesi (FHNW), - added new sequence and configuration for new test
;   26-Aug-2015 - Laszlo I. Etesi (FHNW), - added new tests
;                                         - bugfix for TL/TR eq -1
;   16-Sep-2015 - Laszlo I. Etesi (FHNW), - added sequence ACCFull-2
;                                         
;   02-Sep-2015 - Laszlo I. Etesi (FHNW), updated parameters for tests (TL/TR)
;   24-Sep-2015 - Laszlo I. Etesi (FHNW), bugfix: mistakenly used pixel index 1 - 12 for QLVAR
;   07-Oct-2015 - Laszlo I. Etesi (FHNW), - added printout of number of calibration spectrum counts
;                                         - changed integration times of QLTRG and QLACC to be last_event.relative_time - 
;                                           first_event.relative_time rounded up to the next 4s bin, which will give one time bin          
;                                         - updated T_L and T_R to the latest values                        
;                                         - added more tests
;                                         - added proper mask handling
;                                         - added better logging
;                                         - added support for new tests (masks, etc.) 
;                                         - caldmask is now using hardware enabled detectors mask
;   21-Oct-2015 - Laszlo I. Etesi (FHNW), added new sequences and tests
;   12-Nov-2015 - Laszlo I. Etesi (FHNW), adjusted TR for testing and added logging for triggers
;   24-Nov-2015 - Laszlo I. ETesi (FHNW), - added T ignore time as keyword
;                                         - minor log writing bugfix (ELUT/TLUT path fixed)
;                                         - printing all events, not just triggers
;                                         - disabled once more detectors 18/19
;   26-Nov-2015 - Laszlo I. Etesi (FHNW), - added better test selection and saving calibration 
;   10-Dez-2015 - Laszlo I. Etesi (FHNW), - added provision to write out calibration events
;                                         - added new sequences and activated tests
;                                         - updated timing for 50 MHz (+ DSS 'delay)
;   18-Dec-2015 - Laszlo I. Etesi (FHNW), - bugfix in qlvar accumulation
;                                         - failover for tablout reading (errors in detector numbering, etc.)
;   22-Dec-2015 - Laszlo I. Etesi (FHNW), - failover, cosmetic changes and better output incl. calibration buffer and QLVAR
;   22-Feb-2016 - Laszlo I. Etesi (FHNW), - bugfix: 'fix' routine was casting a long to an integer for QLVAR
;   10-May-2016 - Laszlo I. Etesi (FHNW), - minor updates to accomodate new FSW SIM and structures
;   07-Jun-2016 - Laszlo I. Etesi (FHNW), - added new sequences
;   12-Jul-2016 - Laszlo I. Etesi (FHNW), - added new sequences
;                                         - the new baseline parameter (const.) is provided to the dss writer
;                                         - minor bugfixes when printing log
;   13-Jul-2016 - Laszlo I. Etesi (FHNW), - small update: writing all lowercase file names
;   16-Aug-2016 - Laszlo I. Etesi (FHNW), - QLVAR now fixed to 16 bits with correct overflow behaviour
;                                         - added new sequences
;   05-Oct-2016 - Laszlo I. Etesi (FHNW), - updated the script to be able to repeatedly run a sequence in sequence
;                                         - minor updates
;   06-Mar-2017 - Laszlo I. Etesi (FHNW), - minor updates
;-
;+
; :description:
;   this internal routine actually generates the test data; it takes parameters that
;   explicitely specify the test (name, sequence, LUTs, etc.); first the DSS binary file
;   is generated using the input sequence; then the sequence is executed with the Flight
;   Software Simulator (FSW SIM) to arrive at the rotating buffer structure(s) that
;   then is written to disk (binary).
;
; :params:;
;   test_name : in, required, type='string'
;     the name of the current test, used to prepend to file names
;
;   selected_sequence : in, required, type='string'
;     a file path pointing to a save file containing one of
;     Gordon's random sequences
;
;   selected_elut : in, required, type='string'
;     a file name and path pointing to the selected ELUT (energy) in CSV file format;
;     the format is [detector IDX, pixel IDX, 32 x ad energy boundaries]
;     
;   selected_tlut : in, required, type='string'
;     a file name and path pointing to the selected TLUT (temperature) in CSV file format;
;     the format is detector (|) x pixel (->), comma separated; the values specify
;     a temperature correction
;     
;   timestamp : in, required, type='string'
;     the timestamp when the data generation started
;     
;   extra_file_ref : in, required, type='string'
;     a timesamp-based id to identify files
;     
;   hw_enabled_detector_mask : in, required, type='bytearr(32)'
;     a mask of hardware enabled detectors (used to handle HW enabled/disabled detectors during the testing)
;   
;   t_l_in : in, required, type='double'
;     the latency time (filtering)
;     
;   t_r_in : in, required, type='double'
;     the readout time (filtering)
;     
;   t_i_in : in, required, type='double'
;     the t ignore time (filtering)
;     
;   vardmask : in, required, type='string'
;     this is a hex representation of enabled/disabled detectors for QLVAR (8 digits)
;     
;   varpmask: in, required, type='string'
;     this is a hex representation of enabled/disabled pixels for QLVAR (3 digits)
;   
;   varemask: in, required, type='string'
;     this is a hex representation of enabled/disabled energy channels for QLVAR (8 digits)
;-
pro _execute_test_data_gen, test_name, selected_sequence, configuration_file, timestamp, extra_file_ref, fsw_only_start_time, delay, hw_enabled_detector_mask, t_l_in, t_r_in, t_i_in, vardmask, varpmask, varemask, fpga_root=fpga_root, repeat_sequence=repeat_sequence, repeat_delay=repeat_delay
  ; set defaults
  default, repeat_sequence, 1
  default, repeat_delay, 0 ; in ms
  
  ; mapping between "straight-up" subcollimator numbering and "FPGA" order
  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
  
  ; make test name lowercase for easier handling on Linux
  test_name = strlowcase(test_name)
  
  ; restore sequence
  restore, selected_sequence
  
  ; reset t_l and t_r if they are -1
  if(t_l_in gt -1) then t_l = t_l_in
  if(t_r_in gt -1) then t_r = t_r_in
  if(t_i_in gt -1) then t_ig = t_i_in
  
  inv_det_idx = where(tableout.det ge 33 or tableout.det lt 1, complement=val_det_idx)
  if(inv_det_idx ne -1) then begin
    stop
    print, 'Removing events (invalid detector index): ' + arr2str(inv_det_idx, delimiter=',')
    tableout = tableout[val_det_idx]
  endif
  
  inv_pxl_idx = where(tableout.pixel ge 12 or tableout.pixel lt 0, complement=val_pxl_idx)
  if(inv_pxl_idx ne -1) then begin
    stop
    print, 'Removing events (invalid pixel index): ' + arr2str(inv_pxl_idx, delimiter=',')
    tableout = tableout[val_pxl_idx]
  endif
  
  ; convert Gordon's random sequence to a flat array of events
  eventlist = stx_fsw_convert_rnd_events2eventlist(rnd_events=tableout)

  ; write random event list to disk using DSS export
  dssevs_file = test_name + '_' + extra_file_ref + '.dssevs'
  stx_sim_dss_events_writer, dssevs_file, eventlist.detector_events, constant=1850 

  ; generate start time
  start_time = stx_construct_time(time=fsw_only_start_time)

  ; quickfix to disable detectors BEFORE filtering
  enabled_detector_idx = where(hw_enabled_detector_mask eq 1, complement=disabled_detector_idx)+1
  disabled_detector_idx++
  
  sequence_folder = '../' + test_name + '/' + 'sequence'
  
  if(~file_exist(sequence_folder)) then mk_dir, sequence_folder
  
  ff = find_file(sequence_folder + '/*.fits', count=file_count)

  de = eventlist.detector_events
  
  for ddi = 0L, n_elements(disabled_detector_idx)-1 do begin
    de = de[where(de.detector_index ne disabled_detector_idx[ddi])]
  endfor
  
  de_copy = de
  
  answer = 1
  
  if(file_count gt 0) then input, 'Existing data found. Do you want to reuse [0] or delete and regenerate them [1]?', answer, 0, 0, 1
  
  if(answer eq 1) then begin
    if(file_count gt 0) then file_delete, ff
    for repeat_i = 0L, repeat_sequence-1 do begin
      stx_sim_detector_events_fits_writer, de_copy, test_name + '_' + trim(string(repeat_i)), base_dir=sequence_folder, warn_not_empty=0
      de_copy.relative_time += de[-1].relative_time + repeat_delay / 1000d
    endfor
  endif
  
  ; create a configuration manager to override some default parameters
  config_manager = stx_configuration_manager(configfile=configuration_file) 
  
  ; read out SUMDMASK from the archive buffer module
  sumdmask = config_manager->get(/eab_m_acc, /single) and hw_enabled_detector_mask
  
  ; adjust sumdmask with hw_enabled_detector_mask
  config_manager->set, eab_m_acc=sumdmask
  
  ; read out SUMEMASK from the archive buffer module
  sumemask = config_manager->get(/eab_m_channel, /single)
  
  ; read out CALDMASK from the archive buffer module and adjust it with hw_enabled_detector_mask
  caldmask = config_manager->get(/acs_active_detectors, /single) and hw_enabled_detector_mask
  
  ; write CALDMASK back
  config_manager->set, acs_active_detectors=caldmask
  
  ; adjust the trigger accumulators with the hardware enabled mask
  config_manager->set, t2l_det_index_list=where(hw_enabled_detector_mask eq 1)+1
  
  ; update (if desired) TQ to TQ max
  ;tq_diff = 15.26d*10d^(-6)
  ;tq_max = config_manager->get(/acs_tq, /single) + tq_diff
  ;config_manager->set, acs_tq=tq_max
  
  ;config_manager->set, acs_ts=tq_diff*21d
  ;config_manager->set, acs_ts=0.000311d
  ;config_manager->set, acs_ts=tq_diff * 20d
  
  ; create a FSW SIM object and run the simulation
  fsw = obj_new('stx_flight_software_simulator', config_manager, start_time=start_time, keep_temp_and_calib_detector_events=100L)
  fsw->set, /stop_on_error
  fsw->set, math_error_level=0
  
  fits_reader = obj_new('stx_sim_detector_events_fits_reader_indexed', curdir() + '/' + sequence_folder)
  
  loop_ctr = 0
  
  trigger_eventlist_counter = 0
  filtered_counts_eventlist_counter = 0
  
  dt_integration_total = 0
  
  de = fits_reader->read(t_start=loop_ctr*4, t_end=(loop_ctr+1)*4, /safe)
  
  while (isvalid(de) && de[0].relative_time gt -1) do begin  
    de_next = fits_reader->read(t_start=(loop_ctr+1)*4, t_end=(loop_ctr+2)*4, /safe)
    
    eventlist = rem_tag(eventlist, 'detector_events')
    eventlist = add_tag(eventlist, de, 'detector_events')

    ; adjust event times
    eventlist.time_axis = stx_construct_time_axis([fsw_only_start_time, max(eventlist.detector_events.relative_time) + fsw_only_start_time])
    eventlist.detector_events.relative_time += delay

    ; filter events
    filtered_events = stx_sim_timefilter_eventlist(eventlist.detector_events, triggers_out=triggers_out, t_l=t_l, t_r=t_r, t_ig=t_ig, event=event, pileup_type='last')

    ; convert the filtered events and the triggers to lists
    filtered_eventlist = stx_construct_sim_detector_eventlist(detector_events=filtered_events, start_time=start_time)
    trigger_eventlist = stx_construct_sim_detector_eventlist(detector_events=triggers_out, start_time=start_time)
    
    trigger_eventlist_counter += n_elements(trigger_eventlist.trigger_events)
    filtered_counts_eventlist_counter += n_elements(filtered_eventlist.detector_events)
    
    fsw->process, filtered_eventlist, trigger_eventlist, finalize_processing=(~isvalid(de_next) || de_next[0].relative_time eq -1)
    
    ; calculate max integration time for "one time bin" criterion
    dt_integration = ceil(filtered_events[-1].relative_time) - floor(filtered_events[0].relative_time)

    ; now round up to the next 4 seconds
    dt_integration = 4 - dt_integration mod 4 + dt_integration
    
    dt_integration_total += dt_integration
        
    ; generate the QLTRG (200s integration time)
    ; fixing qltrg to one time bin
    qltrg_tmp = stx_fsw_eventlist_accumulator(trigger_eventlist, /livetime, /a2d_only, accumulator='qltrg', /no_prefix, sum_det=0, dt=dt_integration, active_detectors=hw_enabled_detector_mask, /exclude_bad_detectors)

    if(~isvalid(qltrg)) then begin
      qltrg = qltrg_tmp
    endif else begin      
      qltrg.accumulated_counts += qltrg_tmp.accumulated_counts[*,*,*,-1]
    endelse
    
    de = de_next
    loop_ctr++
  endwhile
  
  qltrg = rem_tag(qltrg, 'time_axis')
  qltrg = add_tag(qltrg, qltrg_tmp.time_axis, 'time_axis')
  
  ; extract all 32 x 12 x 32 accumulator cells for given integration interval
  fsw->getproperty, stx_sim_calibrated_detector_eventlist=calib_events, /combine, /complete
  ;calib_events = fsw.calibrated_detector_events
  calib_eventlist = stx_construct_sim_calibrated_detector_eventlist(detector_events=calib_events.detector_events, start_time=start_time)

  ; generate the QLACC and transform it to the FPGA format; not affectd by SUMDMASK
  ; fixing qlacc to one time bin
  qlacc_32x12x32 = stx_fsw_eventlist_accumulator(calib_eventlist, channel_bin=indgen(33), dt=dt_integration_total, sum_pix=0, sum_det=0, livetime=0, /no_prefix, accumulator='all32x12x32', active_detectors=hw_enabled_detector_mask, /exclude_bad_detectors)

  ;if(~isvalid(qlacc_32x12x32)) then begin
  ;  qlacc_32x12x32 = qlacc_32x12x32_tmp
  ;endif else begin
  ;  qlacc_32x12x32.time_axis = stx_time_axis_append(qlacc_32x12x32.time_axis, qlacc_32x12x32_tmp.time_axis)
  ;  qlacc_32x12x32.accumulated_counts += qlacc_32x12x32_tmp.accumulated_counts
  ;endelse
  
  qlacc_12x32x32 = _transform_32x12x32to12x32x32(qlacc_32x12x32, n_times=n_times)
  
  ; generate the QLVAR
  varem = _mask2id(_str_hex2byte_mask(varemask))
  vardm = _mask2id(_str_hex2byte_mask(vardmask) and hw_enabled_detector_mask)
  varpm = _mask2id(_str_hex2byte_mask(varpmask, /pixel), /pixel)

  ; hackedy-hack-hack
  ; this takes care of the proper varemask handling in case we have not all energies included
  if(n_elements(varem) ne 32) then begin
    energy_prepped_detector_events = []
    for varem_idx = 0L, n_elements(varem)-1 do begin
      found_idx = where(calib_eventlist.detector_events.energy_science_channel eq varem[varem_idx], count)

      if(count gt 0) then energy_prepped_detector_events = [energy_prepped_detector_events, calib_eventlist.detector_events[found_idx]]
    endfor
    energy_prepped_detector_events = energy_prepped_detector_events[bsort(energy_prepped_detector_events.relative_time)]
    qlvar_input_calib_eventlist = stx_construct_sim_calibrated_detector_eventlist(detector_events=energy_prepped_detector_events, start_time=start_time)
  endif else qlvar_input_calib_eventlist = calib_eventlist

  qlvar = stx_fsw_eventlist_accumulator(qlvar_input_calib_eventlist, channel_bin=indgen(33), sum_pix=1, sum_det=1, livetime=0, accumulator='qlvar', dt=0.1d, det_index_list=vardm, pixel_index_list=varpm, /no_prefix)

  ;if(~isvalid(qlvar)) then begin
  ;  qlvar = qlvar_tmp
  ;endif else begin
  ;  qlvar.time_axis = stx_time_axis_append(qlvar.time_axis, qlvar_tmp.time_axis)
  ;  qlvar.accumulated_counts += qlvar_tmp.accumulated_counts
  ;endelse

  ; writing qlac to binary file, BIG ENDIAN
  qlacc_bin = test_name + '_qlacc_' + extra_file_ref + '.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qlacc_bin)
  
  ; QLACC is forced to one time bin
  for nt_i = 0L, 1L-1 do begin
    for p_i = 0L, 12-1 do begin
      for d_i = 0L, 32-1 do begin
        mapped_detector_idx = detector_mapping[d_i]
        for c_i = 0L, 32-1 do begin
          writer->write, qlacc_12x32x32.accumulated_counts[p_i,mapped_detector_idx,c_i,nt_i], bits=16, debug=debug, silent=silent
        endfor
      endfor
    endfor
  endfor
  writer->flushtofile
  destroy, writer
  
  ; writing qltrg to binary file
  qltrg_bin = test_name + '_qltrg_' + extra_file_ref + '.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qltrg_bin)
  
  ; qltrg is forced to one bin
  for nt_i = 0L, 1L-1 do begin
    for trg_i = 0L, 16-1 do begin
      writer->write, qltrg.accumulated_counts[0,0,trg_i,nt_i], bits=32, debug=debug, silent=silent
    endfor
  endfor
  writer->flushtofile
  destroy, writer
  
  ; writing qlvar to binary file
  qlvar_bin = test_name + '_qlvar_' + extra_file_ref + '.bin'
  writer = stx_bitstream_writer(size=2L^25, filename=qlvar_bin)
  n_dim = (size(qlvar.accumulated_counts))[0]
  n_dp = n_dim eq 1 ? 1 : (size(qlvar.accumulated_counts))[4]
  for nt_i = 0L, n_times-1 do begin
    for trg_i = nt_i*40L, ((nt_i+1)*40L)-1 do begin
      if(trg_i ge n_dp) then cts = 0 $
      else cts = fix(total(qlvar.accumulated_counts[*,0,0,trg_i]), type=12)
      writer->write, cts, bits=32, debug=debug, silent=silent
    endfor
  endfor
  writer->flushtofile
  destroy, writer

  ; extract the archive buffer and trigger accumulators
  fsw->getproperty, stx_fsw_m_archive_buffer_group=abgroup, /complete, /combine
  archive_buffer = abgroup.archive_buffer
  triggers = abgroup.triggers

  if(total(triggers.triggers) ne trigger_eventlist_counter) then stop

  ; create the rotating buffer structure
  rotating_buffer  = stx_fsw_archive2rotatingbuffer(archive_buffer=archive_buffer, trigger_accumulators=triggers, start_time=stx_time2any(start_time))

  ; write rotating buffer to disk
  rotating_buffer_name = test_name + '_rotating_buffer_' + extra_file_ref
  rotating_buffer_bin = rotating_buffer_name + '.bin'
  stx_rotatingbuffer2file, rotating_buffer=rotating_buffer, filename=rotating_buffer_bin
  
  ; verify that the write procedure worked
  rb_verify = stx_file2rotatingbuffer(filename=rotating_buffer_bin, /silent)
  
  ; sanity checks
  for rb_v_idx = 0L, n_elements(rotating_buffer)-1 do begin
    same_tr = min(rotating_buffer[rb_v_idx].triggers eq rb_verify[rb_v_idx].triggers)
    same_ct = min(rotating_buffer[rb_v_idx].counts eq rb_verify[rb_v_idx].counts)
    same_ts = min(abs(rotating_buffer[rb_v_idx].timestamp - rb_verify[rb_v_idx].timestamp) lt 2d^(-16))
    if(~(same_tr and same_ct and same_ts)) then stop
  endfor
  
  ; reading out calibration spectrum to print the counts
  fsw->getproperty, stx_fsw_m_calibration_spectrum=calib_spectrum
  ;calib_spectrum = fsw.calib_spec
  n_calib_counts = total(calib_spectrum.accumulated_counts)
  
  ; save calibration spectrum for later comparison
  calibration_spectrum_file = test_name + '_calibration_spectrum_' + extra_file_ref + '.sav'
  save, calib_spectrum, file=calibration_spectrum_file
  
  ; try  to locate hardware (FPGA) data
  if(isvalid(fpga_root) && file_exist(fpga_root)) then begin
    info = file_info(file_search(fpga_root + '\*'))
   
    ; reverse is important as the keyword reverse does not work in case of ABC_1 and ABC_2
    sorted_info = info[reverse(bsort(info.ctime))]
    
    fpga_test_name = str_replace(strlowcase(test_name), '-', '')
    fpga_test_name = str_replace(fpga_test_name, 'prochek', 'procheck')
    
    latest_fpga_calibration_bins = (file_search(sorted_info.name, fpga_test_name + '_[0-9]*\' + 'calibration.bin', /nosort))
    
    if(isvalid(latest_fpga_calibration_bins) && file_exist(latest_fpga_calibration_bins[0])) then fpga_calibration = stx_sim_dss_read_calibration_bin(calibration_bin_file=latest_fpga_calibration_bins[0], /silent) $
    else latest_fpga_calibration_bins = 'N/A'
  endif
  
  abbrev_at = 10

  ; print some statistics
  openw, lun, test_name + '.log', /get_lun, width=500 
  
  printf, lun, 'TEST NAME:                    ' + test_name
  printf, lun, 'TIMESTAMP:                    ' + timestamp
  printf, lun, 'EXTRA FILE REF:               ' + extra_file_ref
  printf, lun, 'FSW SIM CFG:                  ' + file_basename(configuration_file)
  
  printf, lun, '***************************************************************************'
  printf, lun, 'CONVENTIONS USED
  printf, lun, 'HEX MASK:                     Hex masks for detectors/pixels/energies are interpreted from LSB to MSB as Lowest Index to Highest Index. 0x1 -> detector 1, 0x80000000 -> detector 32
  printf, lun, 'ARRAY MASK:                   Array (binary) masks are interpreted from LEFT to RIGHT as Lowest Index to Highest Index. [1,0,0,0,...,0] -> detector 1, [0,0,...,1] -> detector 32
  printf, lun, 'DETECTOR ID:                  Detector numbers go from 1 to 32 and are sub-collimator numbering'
  printf, lun, 'PIXEL ID:                     Pixel numbers go from 0 to 11'
  printf, lun, 'ENERGY CHANNEL ID:            Energy numbers go from 1 to 32'
  
  printf, lun, '***************************************************************************'
  
  printf, lun, 'REPEATED:                     ' + trim(string(repeat_sequence))
  printf, lun, 'REPEAT DELAY:                 ' + trim(string(repeat_delay)) + 'ms'
  printf, lun, 'SEQUENCE:                     ' + file_basename(selected_sequence, '')
  printf, lun, 'TLUT:                         ' + file_basename(config_manager->get(/atc_temperature_correction_table_file, /single, /to_string))
  printf, lun, 'ELUT:                         ' + file_basename(config_manager->get(/csc_science_channel_conversion_table_file, /single, /to_string))
  printf, lun, 'START_TIME FSW:               ' + trim(string(fsw_only_start_time))
  printf, lun, 'DELAY FSW:                    ' + trim(string(delay))
  printf, lun, 'HW ENA DETS:                  ' + '(' + _byte_mask2hex_str(hw_enabled_detector_mask) + '): ' + _pretty_nbr_array(hw_enabled_detector_mask) + ' -> ' + _pretty_nbr_array(_mask2id(hw_enabled_detector_mask))
  
  printf, lun, '***************************************************************************'
  
  printf, lun, 'T Latency:                    ' + trim(string(t_l)) + ' s'
  printf, lun, 'T Read out:                   ' + trim(string(t_r)) + ' s'
  printf, lun, 'T Ignore:                     ' + trim(string(t_ig)) + ' s'
  printf, lun, 'TACCmin:                      ' + config_manager->get(/eab_t_min, /single, /to_string)  + ' s'
  printf, lun, 'TACCmax:                      ' + trim(string(config_manager->get(/eab_t_max, /single, /to_string)/10d))  + ' s'
  printf, lun, 'NEVENTmin:                    ' + config_manager->get(/eab_n_min, /single, /to_string)
  printf, lun, 'CALINT:                       ' + config_manager->get(/acs_reset_frequency, /single, /to_string)
  printf, lun, 'CALTQ:                        ' + config_manager->get(/acs_tq, /single, /to_string) + ' s'
  printf, lun, 'CALTS:                        ' + config_manager->get(/acs_ts, /single, /to_string) + ' s'
  printf, lun, 'SUMEMASK:                     ' + '(' + _byte_mask2hex_str(config_manager->get(/eab_m_channel, /single)) + '): ' + _pretty_nbr_array(config_manager->get(/eab_m_channel, /single)) + ' -> ' + _pretty_nbr_array(_mask2id(config_manager->get(/eab_m_channel, /single)))
  printf, lun, 'SUMDMASK (incl HW ENA DETS):  ' + '(' + _byte_mask2hex_str(config_manager->get(/eab_m_acc, /single)) + '): ' + _pretty_nbr_array(config_manager->get(/eab_m_acc, /single)) + ' -> ' + _pretty_nbr_array(_mask2id(config_manager->get(/eab_m_acc, /single)))
  printf, lun, 'CALDMASK (incl HW ENA DETS):  ' + '(' + _byte_mask2hex_str(config_manager->get(/acs_active_detectors, /single)) + '): ' + _pretty_nbr_array(config_manager->get(/acs_active_detectors, /single)) + ' -> ' + _pretty_nbr_array(_mask2id(config_manager->get(/acs_active_detectors, /single)))
  printf, lun, 'CALDMASK USED:                ' + config_manager->get(/acs_exclude_bad_detectors, /single, /to_string)
  printf, lun, 'VAREMASK:                     ' + '(' + varemask + '): ' + _pretty_nbr_array(_str_hex2byte_mask(varemask)) + ' -> ' + _pretty_nbr_array(_mask2id(_str_hex2byte_mask(varemask)))
  printf, lun, 'VARDMASK (incl HW ENA DETS):  ' + '(' + vardmask + '): ' + _pretty_nbr_array(_str_hex2byte_mask(vardmask)) + ' -> ' + _pretty_nbr_array(_mask2id(_str_hex2byte_mask(vardmask)))
  printf, lun, 'VARPMASK:                     ' + '(' + varpmask + '): ' + _pretty_nbr_array(_str_hex2byte_mask(varpmask, /pixel)) + ' -> ' + _pretty_nbr_array(_mask2id(_str_hex2byte_mask(varpmask, /pixel), /pixel))
  printf, lun, 'QLACC/QLTRG INTEGRATION TIME: ' + trim(string(dt_integration)) + 's (covers first to last event, and rounded up to next 4s boundary)'
  
  printf, lun, '***************************************************************************'
  
  printf, lun, 'QLACC:                        ' + trim(string(ulong64(total(qlacc_12x32x32.accumulated_counts))))
  printf, lun, 'QLTRG:                        ' + trim(string(ulong64(total(qltrg.accumulated_counts))))
  printf, lun, 'EACC:                         ' + trim(string(ulong64(total(rotating_buffer.counts))))
  printf, lun, 'ETRG:                         ' + trim(string(ulong64(total(rotating_buffer.triggers))))
  printf, lun, 'QLVAR COUNTS 40:              ' + trim(string(ulong64(total(total((fix(total(reform(qlvar.accumulated_counts),1),type=12))[0:(39 < (size(reform(qlvar.accumulated_counts), /dimension))[1]-1)])))))
  printf, lun, 'CALBUF FSW SIM:               ' + trim(string(ulong64(n_calib_counts)))
  printf, lun, 'CALBUF FPGA:                  ' + ((isvalid(fpga_calibration)) ? trim(string(ulong64(total(fpga_calibration.accumulated_counts)))) : 'N/A')
  printf, lun, 'CALBUF FPGA FILE:             ' + latest_fpga_calibration_bins[0]
  printf, lun, '***************************************************************************'
  
  printf, lun, 'GH RND COUNTS:                ' + trim(string(n_elements(tableout)))
  printf, lun, 'AB COUNTS:                    ' + trim(string(ulong64(total(archive_buffer.counts))))
  printf, lun, 'RB COUNTS:                    ' + trim(string(ulong64(total(rotating_buffer.counts))))
  printf, lun, 'TRGR ACCUMULATORS:            ' + trim(string(ulong64(total(triggers.triggers))))
  printf, lun, 'FILTERED COUNTS:              ' + trim(string(filtered_counts_eventlist_counter))
  printf, lun, 'TRIGGERS (FLTR):              ' + trim(string(trigger_eventlist_counter))
  printf, lun, 'QLVAR COUNTS TOTAL:           ' + trim(string(ulong64(total(qlvar.accumulated_counts))))  
  
  printf, lun, '***************************************************************************'
 
  printf, lun, 'SEQUENCE (BASED ON EVENTLIST):'
  
  printf, lun, ['            RELATIVE TIME', '   DET (SC)', '      PIXEL', '         AD']
  for i = 0L, n_elements(eventlist.detector_events)-1 do begin
    rt = trim(string(eventlist.detector_events[i].relative_time))
    d = '         ' + trim(string(fix(eventlist.detector_events[i].detector_index)))
    p = '         ' + trim(string(fix(eventlist.detector_events[i].pixel_index)))
    ad = '          ' + trim(string(fix(eventlist.detector_events[i].energy_ad_channel)))
    printf, lun, [rt, d, p, ad], format='(d, i, i, i)'
    
    if(i ge abbrev_at) then begin
      printf, lun, 'TOO MANY EVENTS, ABBREVIATING.'
      break
    endif
  endfor
  
  printf, lun, '***************************************************************************'

  printf, lun, 'SEQUENCE (BASED ON CALIBRATED_EVENTLIST):'

  printf, lun, ['            RELATIVE TIME', '   DET (SC)', '      PIXEL', '         CHANNEL']
  for i = 0L, n_elements(calib_eventlist.detector_events)-1 do begin
    rt = trim(string(calib_eventlist.detector_events[i].relative_time))
    d = '         ' + trim(string(fix(calib_eventlist.detector_events[i].detector_index)))
    p = '         ' + trim(string(fix(calib_eventlist.detector_events[i].pixel_index)))
    ad = '          ' + trim(string(fix(calib_eventlist.detector_events[i].energy_science_channel+1)))
    printf, lun, [rt, d, p, ad], format='(d, i, i, i)'

    if(i ge abbrev_at) then begin
      printf, lun, 'TOO MANY EVENTS, ABBREVIATING.'
      break
    endif
    
  endfor

  printf, lun, '***************************************************************************'

  printf, lun, 'ALL EVENTS:'

  printf, lun, ['            RELATIVE TIME', '   DET (SC)', '        PIXEL', '   AD CHANNEL', '   ADGROUP', '      TRG']
  for i = 0L, n_elements(event)-1 do begin
    ;if(~event[i].trigger) then continue
    rt = trim(string(event[i].relative_time))
    d = '         ' + trim(string(fix(event[i].detector_index)))
    p = '         ' + trim(string(fix(event[i].pixel_index)))
    adc = '          ' + trim(string(fix(event[i].energy_ad_channel)))
    adg = '          ' + trim(string(fix(event[i].adgroup_index)))
    trg = '          ' + trim(string(fix(event[i].trigger)))
    printf, lun, [rt, d, p, adc, adg, trg], format='(d, i, i, i, i, i)'
    
    if(i ge abbrev_at) then begin
      printf, lun, 'TOO MANY EVENTS, ABBREVIATING.'
      break
    endif
  endfor
  
  printf, lun, '***************************************************************************'

  printf, lun, 'QLVAR:'
  
  qlvar_40_cts = (total(reform(qlvar.accumulated_counts), 1))[0:(39 < (size(reform(qlvar.accumulated_counts), /dimension))[1]-1)]
  qlvar_40_t = stx_time2any(qlvar.time_axis.time_start)
  
  printf, lun, ['      RELATIVE START TIME', '      COUNTS']
  for i = 0L, n_elements(qlvar_40_cts)-1 do begin
    printf, lun, [qlvar_40_t[i], qlvar_40_cts[i]], format='(d, i)'
  endfor  

  printf, lun, '***************************************************************************'
  
  printf, lun, "DSSEVS     : " + dssevs_file
  
  printf, lun, "RB BIN     : " + rotating_buffer_bin
  printf, lun, "QLACC BIN  : " + qlacc_bin
  printf, lun, "QLTRG BIN  : " + qltrg_bin
  printf, lun, "QLVAR BIN  : " + qlvar_bin
  printf, lun, "EACC BIN   : encoded in rotating buffer"
  printf, lun, "CAL SPEC   : " + calibration_spectrum_file
  
  free_lun, lun
end

;+
; :description:
;   this routine starts the generation of all FPGA test sequences, including all binary and ASCII
;   output formats
;-
pro stx_sim_fpga_data_generation_script, output_folder=output_folder 
  ; generate timestamp
  timestamp = trim(ut_time(/to_local)); 'now'; trim(ut_time(/to_local))
  
  ; generate file reference
  extra_file_ref = time2file(timestamp, /seconds); 'orig' ;'orig';time2file(timestamp, /seconds)
  
  ; save current dir
  currdir = curdir()
  
  default, output_folder, currdir
  
  ; cdir into output_folder
  mk_dir, output_folder
  cd, output_folder
  
  ; create extra directory
  mk_dir, extra_file_ref
  cd, extra_file_ref
  
  data_dir = concat_dir(getenv('STX_FPGA'), 'rnd_seq_testing')
  
  es4 = (loc_file(path=data_dir, 'ES4*'))[-1]
  es5= (loc_file(path=data_dir, 'ES5*'))[-1]
  es6 = (loc_file(path=data_dir, 'ES6*'))[-1]
  es7 = (loc_file(path=data_dir, 'ES7*'))[-1]
  es10 = (loc_file(path=data_dir, 'ES10*'))[-1]
  es11 = (loc_file(path=data_dir, 'ES11*'))[-1]
  es12 = (loc_file(path=data_dir, 'ES12*'))[-1]
  es13 = (loc_file(path=data_dir, 'ES13*'))[-1]
  es14 = (loc_file(path=data_dir, 'ES14*'))[-1]
  es15 = (loc_file(path=data_dir, 'ES15*'))[-1]
  es16 = (loc_file(path=data_dir, 'ES16*'))[-1]
  es17 = (loc_file(path=data_dir, 'ES17*'))[-1]
  es25 = (loc_file(path=data_dir, 'ES25*'))[-1]
  es35 = (loc_file(path=data_dir, 'ES35*'))[-1]
  es36 = (loc_file(path=data_dir, 'ES36*'))[-1]
  es37 = (loc_file(path=data_dir, 'ES37*'))[-1]
  es40 = (loc_file(path=data_dir, 'ES40*'))[-1]
  es41 = (loc_file(path=data_dir, 'ES41*'))[-1]
  es42 = (loc_file(path=data_dir, 'ES42*'))[-1]
  es43 = (loc_file(path=data_dir, 'ES43*'))[-1]
  es44 = (loc_file(path=data_dir, 'ES44*'))[-1]
  es45 = (loc_file(path=data_dir, 'ES45*'))[-1]
  es46 = (loc_file(path=data_dir, 'ES46*'))[-1]
  es47 = (loc_file(path=data_dir, 'ES47*'))[-1]
  es48 = (loc_file(path=data_dir, 'ES48*'))[-1]
  es49 = (loc_file(path=data_dir, 'ES49*'))[-1]
  
  default_tl = '5.19d-6' ;'1.39d-6'
  default_tr = '9.91d-6' ;'9.44d-6'
  default_ti = '0.35d-6' ;'0.4d-6'
  default_t_shift = '0d'
  default_vardmask = 'FFFFFFFF'
  default_varemask = 'FFFFFFFF'
  default_varpmask = 'FFF'
  fpga_root = 'C:\Users\LaszloIstvan\Development\stix\fpga'

  test_setup = [ $
    ['PROCHEK-1',       es4,    string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCSHORT-1',      es5,    string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCSHORT-2',      es14,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $ 
    ['ACCSHORT-3',      es40,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCfull-1',       es15,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCfull-2',       es25,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCfull-3',       es36,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['ACCfull-4',       es41,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TREFshort-1',     es16,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TCORshort-1',     es16,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TREFlong-1',      es17,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TCORlong-1',      es17,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TREFlong-2',      es37,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TCORlong-2',      es37,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TREFlong-3',      es42,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TCORlong-3',      es42,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopMin-1',      es15,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopCnt-1',      es15,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopMin-2',      es35,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopCnt-2',      es35,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopMin-3',      es43,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['AstopCnt-3',      es43,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ;['TIMCALu-1',      es9,    string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask]   $
    ['TIMCALr-1',       es10,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['TIMCALr-2',       es44,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['LOWrate-1',       es11,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['LOWrate-2',       es45,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['MEDrate-1',       es12,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['MEDrate-2',       es46,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['HIrate-1',        es13,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['HIrate-2',        es47,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['HIrate-3',        es48,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask],  $
    ['OneMask-1',       es15,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         '00400000',         '100',              '02000000'],  $
    ['OneMask-2',       es41,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         '00400000',         '100',              '02000000'],  $
    ['RanMask-1',       es15,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         '808AFF17',         '52A',              '45976D86'],   $
    ['RanMask-2',       es41,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         '808AFF17',         '52A',              '45976D86'],   $
    ['Xrate-1',         es49,   string(0),   default_t_shift,    default_tl,     default_tr,   default_ti,         default_vardmask,   default_varpmask,   default_varemask]   $
    ]
    
  ;hw_enabled_detectors = byte([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1,1,1,1])
  hw_enabled_detectors = bytarr(32)+1b
  ;hw_enabled_detectors = byte([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1])

  n_tests = n_elements(test_setup) / 22

  selected_test_idx = indgen(n_tests) ; <- all
  selected_test_idx = [3, 7, 14, 15, 20, 21, 23, 25, 27, 29, 30, 32, 34, 35]
  selected_test_idx = 0
  
  repeat_sequence = 1
  repeat_delay = 0

  for sidx = 0, n_elements(selected_test_idx)-1 do begin
    tidx = selected_test_idx[sidx]
    configuration_file = (loc_file(path=concat_dir(data_dir, 'parameters'), test_setup[0,tidx] + '_stx_fsw_sim_config*'))[-1]
    _execute_test_data_gen, test_setup[0,tidx], test_setup[1,tidx], configuration_file, timestamp, extra_file_ref, double(test_setup[2,tidx]), double(test_setup[3,tidx]), hw_enabled_detectors, double(test_setup[4,tidx]), double(test_setup[5,tidx]), double(test_setup[6,tidx]), test_setup[7,tidx], test_setup[8,tidx], test_setup[9,tidx], fpga_root=fpga_root, repeat_sequence=repeat_sequence, repeat_delay=repeat_delay
    if(file_exist('calibration_spectrum_events.csv')) then file_move, 'calibration_spectrum_events.csv', strlowcase(test_setup[0,tidx]) + '_calibration_spectrum_events_' + extra_file_ref + '.csv'
  endfor
  
  cd, currdir
end  