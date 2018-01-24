function stx_fsw_ivs_resample_energy_binning, spectrogram, $
  termal_binning =  termal_binning, $
  nontermal_binning = nontermal_binning, $
  thermalboundary = thermalboundary
  
  default, thermalboundary, 10 
  default, termal_binning, [transpose(indgen(32)),transpose(indgen(32))+1]
  default, nontermal_binning, [transpose(indgen(32)),transpose(indgen(32))+1]
  
  ;merge both binnings
  
  cut = where(termal_binning[1,*] le thermalboundary, n_cuts)
  if n_cuts eq 0 then cut=0
  
  termal_binning_cut = termal_binning[*,cut]
  nontermal_binning_cut = nontermal_binning[*,where(nontermal_binning[0,*] ge termal_binning_cut[n_elements(termal_binning_cut)-1])]
  merged_bins = [[termal_binning_cut],[nontermal_binning_cut]]
  merged_edges = [reform(merged_bins[0,*]),merged_bins[1,n_elements(merged_bins[1,*])-1]]
  
  new_n_e = N_ELEMENTS(merged_edges)-1
  
  
  spg_data = make_array(new_n_e,n_elements(spectrogram.time_axis.time_start),/DOUBLE)

  for e=0, new_n_e - 1 do begin
    e_start = merged_edges[e]
    e_end   = merged_edges[e + 1] - 1
    if e_start lt e_end then spg_data[e,*]=total(spectrogram.counts[e_start:e_end,*], 1, /preserve_type) $
    else  spg_data[e, *] = spectrogram.counts[e_start, *]

  end
  
  merged_edges_orig_idx = [spectrogram.energy_axis.LOW_FSW_IDX[merged_edges[0:-2]], spectrogram.energy_axis.HIGH_FSW_IDX[merged_edges[-1]-1] +1 ] 
  
  new_spec =  stx_fsw_ivs_spectrogram(spg_data, spectrogram.time_axis, energy_edges=merged_edges_orig_idx)
  return, new_spec
end
