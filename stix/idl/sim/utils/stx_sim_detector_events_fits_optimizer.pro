pro stx_sim_detector_events_fits_optimizer, input_directory=input_directory, output_directory=output_directory
  ; create a data reader
  defr = obj_new('stx_sim_detector_events_fits_reader_indexed', input_directory)

  ; define a counter for t_start
  t_start = 0

  ; read the first bin, i.e. from 0 to 4s
  detector_events = defr->read(t_start=t_start, t_end=(t_start + 4), /sort)

  ; keep looping as long as there are data
  while (detector_events[0].relative_time ge 0) do begin
    prefix = trim(string(t_start)) + '-' + trim(string((t_start + 4)))
    
    ; write data to disk
    stx_sim_detector_events_fits_writer, detector_events, prefix, base_dir=output_directory, /optimized  
    ; reset data to next bin
    t_start += 4
    detector_events = defr->read(t_start=t_start, t_end=(t_start + 4))
  endwhile

end