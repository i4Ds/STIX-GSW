function stx_construct_pixel_data_summed, pixel_data=pixel_data, live_time, time_range, energy_range, counts=counts
  pixel_data_summed = stx_pixel_data_summed()
  
  if(keyword_set(pixel_data)) then begin
    default, live_time, pixel_data.live_time
    default, time_range, pixel_data.time_range
    default, energy_range, pixel_data.energy_range
  endif
  
  pixel_data_summed.live_time = live_time
  pixel_data_summed.time_range = time_range
  pixel_data_summed.energy_range = energy_range
  pixel_data_summed.counts = counts
  
  return, pixel_data_summed
end