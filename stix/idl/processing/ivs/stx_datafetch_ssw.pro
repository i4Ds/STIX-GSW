function stx_datafetch_ssw, obs_time,energy_binning,detector_mask
  ; Create a HESSI spectrogram
  spectrogram = hsi_spectrum()
  
  spectrogram->set, obs_time_interval = obs_time
  spectrogram->set, seg_index_mask = detector_mask
  
  if n_elements( energy_binning ) lt 2 then eb = hsi_energy_model( energy_binning ) $
  else eb = energy_binning
  
  spectrogram->set, sp_energy_binning = eb
  
  oo = hsi_obs_summary(obs_time_interval = obs_time )
  roll_period = oo->getdata(class_name='roll_period')
  
  spectrogram->set, sp_time = avg(roll_period.roll_period)
  
  spectrogram->set, /sp_data_structure
  spectrogram->set, sp_data_unit = 'rate'
  count_struct = spectrogram->getdata()
  time_axis = stx_time_axis(spectrogram->getaxis(/ut))
  energy_axis = spectrogram->getaxis(/energy, /edges_1)
  
  out = stx_spectrogram(transpose(count_struct.rate), time_axis, energy_binning, transpose(count_struct.ltime))
  
  destroy, spectrogram
  destroy, oo
  
  return, out
end