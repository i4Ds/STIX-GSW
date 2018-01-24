pro convert_bin_to_fits
  openr, lun, 'c:\users\laszloistvan\flare.bin', /get_lun
 
   det_events=list()
  
  while (~eof(lun)) do begin
    relative_time = 0d
    detector_index = 0b
    pixel_index = 0b
    energy_ad_channel = uint(0)
    attenuator_flag = 0b
    
    readu, lun, relative_time, detector_index, pixel_index, energy_ad_channel, attenuator_flag
    det_event = stx_construct_sim_detector_event(relative_time=relative_time, $
      detector_index=detector_index, $
      pixel_index=pixel_index, $
      energy_ad_channel=energy_ad_channel, $
      attenuator_flag=attenuator_flag)
      
    det_events.add, det_event
  endwhile
  
  free_lun, lun
  
  openr, lun, 'c:\users\laszloistvan\background.bin', /get_lun
    
  while (~eof(lun)) do begin
    relative_time = 0d
    detector_index = 0b
    pixel_index = 0b
    energy_ad_channel = uint(0)
    attenuator_flag = 0b
    
    readu, lun, relative_time, detector_index, pixel_index, energy_ad_channel, attenuator_flag
    det_event = stx_construct_sim_detector_event(relative_time=relative_time, $
      detector_index=detector_index, $
      pixel_index=pixel_index, $
      energy_ad_channel=energy_ad_channel, $
      attenuator_flag=attenuator_flag)
      
      det_event.detector_index += 1
      
    det_events.add, det_event
  endwhile
  
  detector_events = det_events.toarray()
  detector_events = detector_events[bsort(detector_events.relative_time)]
  
  free_lun, lun
  
  src_str = stx_sim_read_scenario(scenario_name='stx_scenario_2', out_bkg_str=bkg_str)
  
  start_time = stx_time()
  
  det_eventlist = stx_construct_sim_detector_eventlist(start_time=start_time,detector_events=detector_events,sources=src_str)
  
  filtered_events = stx_sim_timefilter_eventlist(det_eventlist.detector_events, triggers_out=triggers_out, T_L=T_L, T_R=T_R)
  filtered_eventlist = stx_construct_sim_detector_eventlist(start_time=start_time, detector_events = filtered_events, sources = src_str)
  trigger_eventlist = stx_construct_sim_detector_eventlist( start_time = start_time, detector_events = triggers_out, sources = src_str )

  stx_ds_result_data = stx_construct_ds_result_data(eventlist=det_eventlist, filtered_eventlist=filtered_eventlist, triggers=trigger_eventlist, sources=src_str)

  save, stx_ds_result_data, filename='C:\Users\LaszloIstvan\bg_only.sav'
end
