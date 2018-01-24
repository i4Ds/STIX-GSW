function stx_construct_fsw_ivs_interval, start_t, end_t, counts, $
  start_time_idx = start_time_idx,$
  end_time_idx  = end_time_idx,$
  start_energy_idx  = start_energy_idx,$
  end_energy_idx  = end_energy_idx,$
;  orig_start_energy_idx  = orig_start_energy_idx,$
;  orig_end_energy_idx  = orig_end_energy_idx,$
  spectroscopy = spectroscopy, $
  trim = trim
  
  ;default, orig_start_energy_idx, start_energy_idx
  ;default, orig_end_energy_idx, end_energy_idxres 
  
  if ~isa(end_time_idx) && spectroscopy eq 0 then stop

  str = stx_fsw_ivs_interval()

  str.start_time = start_t
  str.end_time = end_t
  str.counts = counts
  if isa(spectroscopy) then str.spectroscopy = spectroscopy
  if isa(trim) then str.trim = trim
  if isa(start_time_idx) then str.start_time_idx = start_time_idx
  if isa(end_time_idx) then str.end_time_idx = end_time_idx
  if isa(start_energy_idx) then str.start_energy_idx = start_energy_idx
  if isa(end_energy_idx) then str.end_energy_idx = end_energy_idx
;  if isa(orig_start_energy_idx) then str.start_energy_idx_orig = orig_start_energy_idx
;  if isa(orig_end_energy_idx) then str.end_energy_idx_orig = orig_end_energy_idx

  
  return, str

end