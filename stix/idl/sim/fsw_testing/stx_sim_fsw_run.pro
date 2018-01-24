pro stx_sim_fsw_run, dss, fsw, test_name, sequence_name, t_l=t_l, t_r=t_r, t_ig=t_ig
  no_time_bins = long(dss->getdata(scenario_name=sequence_name, output_target='scenario_length') / 4d)

  for time_bin = 0L, no_time_bins - 1 do begin
     
    ds_result_data = dss->getdata(output_target='stx_ds_result_data', time_bin=time_bin, scenario=sequence_name, rate_control_regime=0, t_l=t_l, t_r=t_r, t_ig=t_ig, pileup_type='last')
    
    if(ds_result_data eq !NULL) then begin
      fsw->skip
      continue
    endif

    time_bin_seconds_start = time_bin * 4d
    time_bin_seconds_end = (time_bin + 1) * 4d
    finalize_processing = (time_bin eq no_time_bins - 1)

    ; Quickfixes (to be removed later)
    ds_result_data.filtered_eventlist.time_axis = stx_construct_time_axis([0, 4d])
    ds_result_data.triggers.time_axis = stx_construct_time_axis([0, 4d])
    
    if(min(minmax(ds_result_data.filtered_eventlist.detector_events.relative_time)) eq -1) then stop

    stx_sim_fsw_generate_data, fsw, ds_result_data.eventlist, ds_result_data.filtered_eventlist, ds_result_data.triggers, $
      finalize_processing=finalize_processing, current_time_seconds=time_bin_seconds_start, test_name=test_name
  endfor
  
  ; extract the archive buffer and trigger accumulators
  fsw->getproperty, stx_fsw_m_archive_buffer_group=abgroup, /complete, /combine
  archive_buffer = abgroup.archive_buffer
  triggers = abgroup.triggers

  ; don't check for the moment, must be done globally
  ;if(total(triggers.triggers) ne trigger_eventlist_counter) then stop
  ;goto, skip
  ; create the rotating buffer structure
  rotating_buffer  = stx_fsw_archive2rotatingbuffer(archive_buffer=archive_buffer, trigger_accumulators=triggers, start_time=stx_time2any(0))

  ; write rotating buffer to disk
  rotating_buffer_name = test_name + '_rotating_buffer'
  rotating_buffer_bin = rotating_buffer_name + '.bin'
  stx_rotatingbuffer2file, rotating_buffer=rotating_buffer, filename=rotating_buffer_bin
;skip:
  ; verify that the write procedure worked
  ;rb_verify = stx_file2rotatingbuffer(filename=rotating_buffer_bin)

  ; sanity checks
  ;for rb_v_idx = 0L, n_elements(rotating_buffer)-1 do begin
  ;  same_tr = min(rotating_buffer[rb_v_idx].triggers eq rb_verify[rb_v_idx].triggers)
  ;  same_ct = min(rotating_buffer[rb_v_idx].counts eq rb_verify[rb_v_idx].counts)
  ;  same_ts = min(abs(rotating_buffer[rb_v_idx].timestamp - rb_verify[rb_v_idx].timestamp) lt 2d^(-16))
  ;  if(~(same_tr and same_ct and same_ts)) then stop
  ;endfor
  
  ; combine all QL buffers into one file
  spawn, 'del, ' + test_name + '_combined_qlvar.bin'
  spawn, 'del, ' + test_name + '_combined_qltrg.bin'
  spawn, 'del, ' + test_name + '_combined_qlacc.bin'
  spawn, 'copy /b *_qlvar.bin ' + test_name + '_combined_qlvar.bin'
  spawn, 'copy /b *_qltrg.bin ' + test_name + '_combined_qltrg.bin'
  spawn, 'copy /b *_qlacc.bin ' + test_name + '_combined_qlacc.bin'
end