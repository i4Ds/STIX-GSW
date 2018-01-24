;+
; :description:
;   
;   The content of stx_module_sum_over_time_energy::_execute as a standalone function
;   
;-
function  stx_sum_over_time_energy, in  
 
  iv = in.intervals
       
  n_pd = n_elements(in.intervals)     
  pixel_data = replicate(stx_pixel_data(),n_pd) 
  pixel_data.time_range[0] = in.intervals.start_time
  pixel_data.time_range[1] = in.intervals.end_time
  pixel_data.energy_range[0] = in.intervals.start_energy
  pixel_data.energy_range[1] = in.intervals.end_energy
  
  col = stx_time_energy_bin_collection(in.raw_pixel_data)
  
  for i=0L, n_pd-1 do begin
     to_merge_idx = col->select(time=pixel_data[i].time_range ,energy=pixel_data[i].energy_range , count_matches=count_matches, /idx, /strict)
    
     if count_matches gt 0 then begin
       pixel_data[i].counts = count_matches eq 1 ? in.raw_pixel_data[to_merge_idx].counts : total(in.raw_pixel_data[to_merge_idx].counts,3)
       
     end 
  endfor
  
  destroy, col
  return, pixel_data
  
end