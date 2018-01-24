;+
; :description:
;   
;   Make and IVS interval structure from the time and energy binning of a spectrogram structure. 
;   
;-
function stx_img_spec_spectrogram2intervals, spect_struct

  sz = size(spect_struct.data)
  n_e = sz[1]
  n_t = sz[2]
  
  img_spec_ints = replicate( stx_ivs_interval(), n_e, n_t )
  
  for i = 0, n_e-1 do begin
    for j = 0, n_t-1 do begin
    
      img_spec_ints[i,j].start_time = (spect_struct.t_axis.time_start)[j]
      img_spec_ints[i,j].end_time = (spect_struct.t_axis.time_end)[j]
      img_spec_ints[i,j].start_energy = (spect_struct.e_axis.low)[i]
      img_spec_ints[i,j].end_energy = (spect_struct.e_axis.high)[i]
      img_spec_ints[i,j].start_energy_idx = (spect_struct.e_axis.low_fsw_idx)[i]
      img_spec_ints[i,j].end_energy_idx = (spect_struct.e_axis.high_fsw_idx)[i]
      img_spec_ints[i,j].counts = spect_struct.data[i,j]
      
    endfor
  endfor
  
  img_spec_ints = reform(img_spec_ints, n_e*n_t)
  
  return, img_spec_ints
end