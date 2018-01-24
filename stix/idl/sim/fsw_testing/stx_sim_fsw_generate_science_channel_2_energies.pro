function stx_sim_fsw_generate_science_channel_2_energies, science_channel, detector_id, pixel_index, scc_file=scc_file
  tbl = stx_energy_lut_get( ad_energy_filename = scc_file, /reset, /full )
    
  energies = list()
  
  for energy_i = 0L, 150 do begin
    n = tbl[detector_id-1, pixel_index, stx_sim_energy_2_pixel_ad(energy_i, detector_id, pixel_index)]
    if(n eq science_channel) then energies->add, energy_i
  endfor

  return, minmax(energies->toarray())
end