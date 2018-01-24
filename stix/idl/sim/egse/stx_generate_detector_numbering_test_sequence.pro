function _flip_flop_strategy, array
  new_array = intarr(n_elements(array))
  for index = 0L, (n_elements(array) / 2) do begin
    new_array[index] = array[index]
    new_array[index] = array[-(index+1)]
  endfor
  
  return, new_array
end

function _random_strategy, array
  return, array[sort(randomu(seed, n_elements(array)))]
end

function stx_generate_detector_numbering_test_sequence, td=td, ts=ts, t0=t0, ad_value=ad_value, strategy_detector=strategy_detector, strategy_pixel=strategy_pixel, write_dss=write_dss, output_folder=output_folder
  ; timing in seconds, space between events
  default, td, 0.001

  ; stable detector and pixel sequence in seconds
  default, ts, 0.5
  
  ; t0 to shift the sequence
  default, t0, 0.5
  
  ; default energy in AD value
  default, ad_value, 3000

  ; strategy to generate patterns for detectors: random, flip_flop, bottom_up
  default, strategy_detector, 'bottom_up'

  ; strategy to generate patterns for pixels: random, flip_flop, bottom_up
  default, strategy_pixel, 'bottom_up'
  
  ; autosave dss file
  default, write_dss, 0
  
  ; where to save the dss
  default, output_folder, 'C:\Temp'

  ; END of configuration parameters
  ; --------------------------------------------------------------------

  ; total number of pixel and detector combinations
  total_combinations = 32 * 12
  
  ; total repeaters for sequence
  repeaters = round(ts / td)
  
  ; total number of events
  total_events = total_combinations * repeaters

  ; generate number of detector events needed
  detector_events = replicate(stx_sim_detector_event(), total_events)

  ; detector indices in subcollimator numbering
  detector_indices = indgen(32) + 1

  ; pixel indices
  pixel_indices = indgen(12)

  switch(strategy_detector) of
    'bottom_up': begin
        ; do nothing
      break
    end
    'random': begin
      detector_indices = _random_strategy(detector_indices)
      break
    end
    'flip_flop': begin
      detector_indices = _flip_flop_strategy(detector_indices)
      break
    end
    else: begin
      message, 'Detector sequence strategy not recognized'
    end
  endswitch
  
  switch(strategy_pixel) of
    'bottom_up': begin
        ; do nothing
      break
    end
    'random': begin
      pixel_indices = _random_strategy(pixel_indices)
      break
    end
    'flip_flop': begin
      pixel_indices = _flip_flop_strategy(pixel_indices)
      break
    end
    else: begin
      message, 'Pixel sequence strategy not recognized'
    end
  endswitch

  detector_events.relative_time = dindgen(total_events) * td + t0
  detector_events.energy_ad_channel = uintarr(total_events) + ad_value * randomu(seed, total_events)
  
  ; pointer into the detector events
  ptr = 0
  
  for detector_idx = 0L, 32-1 do begin
    for pixel_idx = 0L, 12-1 do begin
      detector_events[ptr:ptr+repeaters-1].detector_index = intarr(repeaters) + detector_indices[detector_idx]
      detector_events[ptr:ptr+repeaters-1].pixel_index = intarr(repeaters) + pixel_indices[pixel_idx]
      ptr += repeaters
    endfor
  endfor
  
  print, 'Number of detector events: ', n_elements(detector_events)
  print, 'Min-max detector index: ', minmax(detector_events.detector_index)
  print, 'Min-max pixel index: ', minmax(detector_events.pixel_index)
  print, 'Min-max time [s]: ', minmax(detector_events.relative_time)
  print, 'Time spacing [s]: ', td
  print, 'Sequence length [s]: ', ts
  print, 'Strategy detector and pixel: ' + strategy_detector + ' ' + strategy_pixel
  
  ttemp = shift(detector_events.relative_time, 1) - detector_events.relative_time
  ttemp_idx = where(abs(ttemp[1:-1]) ne td, count)
  print, 'Time monotonically increasing: ', (count eq 0) ? 'TRUE' : 'FALSE'
  
  if(write_dss) then begin
    target = concat_dir(output_folder, 'detector-numbering-test-sequence-' + strategy_detector + '-' + strategy_pixel + '-' + trim(string(n_elements(detector_events))) + '.dss')
    print, 'Writing detector sequence as ' + target
    stx_sim_dss_events_writer, target, detector_events, constant=1850  
  endif

  return, detector_events
end