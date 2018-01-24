function stx_fsw_ivs_img, stx_fsw_archive_buffer, start_time, rcr, rcr_time_axis,  $
  thermalboundary_idx                   = thermalboundary_idx, $
  trimming_max_loss                     = trimming_max_loss, $
  min_time_img                          = min_time_img, $
  min_count_img                         = min_count_img, $
  plotting                              = plotting, $
  thermal_boundary_lut                  = thermal_boundary_lut, $
  thermal_min_count_lut                 = thermal_min_count_lut, $
  nonthermal_min_count_lut              = nonthermal_min_count_lut, $
  total_flare_magnitude_index_lut       = total_flare_magnitude_index_lut, $
  thermal_flare_magnitude_index_lut     = thermal_flare_magnitude_index_lut, $
  nonthermal_flare_magnitude_index_lut  = nonthermal_flare_magnitude_index_lut, $
  thermal_min_time_lut                  = thermal_min_time_lut, $
  energy_binning_lut                    = energy_binning_lut, $
  nonthermal_min_time_lut               = nonthermal_min_time_lut, $
  detector_mask                         = detector_mask, $
  remove_background                     = remove_background,$
  background                            = background,$
  energy_axis_background                = energy_axis_background, $
  split_into_rcr_blocks                 = split_into_rcr_blocks

  default, trimming_max_loss, 0.05
  default, split_into_rcr_blocks, 2

  pixel_counts = stx_fsw_compact_archive_buffer(stx_fsw_archive_buffer, $
    start_time = start_time, $
    detector_mask = detector_mask, $
    ;out
    time_axis = time_axis, $
    time_edges = time_edges, $
    total_counts=total_counts, $
    disabled_detectors_total_counts=disabled_detectors_total_counts)



  n_t = n_elements(time_axis.duration)
  n_e = 32

  rcr_resampled = bytarr(n_t)
  ids = stx_time_locate(rcr_time_axis,time_axis.mean)
  matches = where(ids gt -1, count_matches)
  if count_matches gt 0 then rcr_resampled[matches] = rcr[ids[matches]]

  ;TODO: N.H. check background removal
  ;remove background
  ;if remove_background then disabled_detectors_total_counts = stx_fsw_remove_background(disabled_detectors_total_counts, background, energy_axis_background, time_axis, detector_mask)

  spectrogram = stx_fsw_ivs_spectrogram(disabled_detectors_total_counts, time_axis)

  ;Determine the total number of counts, Ntot, (64 bits) within this flare period
  Ntot = total(spectrogram.counts,/PRESERVE_TYPE)

  ;Determine a ‘total flare magnitude index’,
  ;FMtot, to be used as an index for determining the division between thermal and non-thermal energies.
  FMtot = stx_ivs_get_flare_magnitude_index(Ntot, range = "total", total_flare_magnitude_index_lut = total_flare_magnitude_index_lut)

  ;Use the flare magnitude index as an index to a 24-element TC-specified lookup table to
  ;determine the minimum science channel number to be considered as ‘nonthermal’.
  ;Channels below this value are considered themal’.

  thermalboundary_idx = keyword_set(thermalboundary_idx) ? thermalboundary_idx : stx_ivs_get_thermal_boundary(FMtot, thermal_boundary_lut=thermal_boundary_lut)

  all_bands = indgen(n_e)

  thermal_bands = all_bands[0:thermalboundary_idx]
  nonthermal_bands = all_bands[thermalboundary_idx+1:*]

  ;Calculate the energy-summed counts, Nt and Nnt (64 bits) for thermal and nonthermal energy regimes for the entire flare.
  Nt  = total(spectrogram.counts[thermal_bands,*],/PRESERVE_TYPE)
  Nnt = total(spectrogram.counts[nonthermal_bands,*],/PRESERVE_TYPE)

  ;Determine a ‘thermal flare magnitude index’, FMt, and a nonthermal flare magnitude index, FMnt.
  FMt = stx_ivs_get_flare_magnitude_index(Nt, range = 'thermal', thermal_flare_magnitude_index_lut=thermal_flare_magnitude_index_lut)
  FMnt = stx_ivs_get_flare_magnitude_index(Nnt, range = 'nonthermal', nonthermal_flare_magnitude_index_lut=nonthermal_flare_magnitude_index_lut)

  ;get or override minimum counts and times
  if ~keyword_set(min_count_img) then begin
    thermal_min = stx_ivs_get_min_count(FMt, 1, thermal_min_count_lut = thermal_min_count_lut)
    non_thermal_min = stx_ivs_get_min_count(FMnt, 0, nonthermal_min_count_lut = nonthermal_min_count_lut)
    min_count_img = [transpose(thermal_min),transpose(non_thermal_min)]
  endif

  if ~keyword_set(min_time_img) then begin
    thermal_min = stx_ivs_get_min_time(FMt,1,thermal_min_time_lut=thermal_min_time_lut)
    non_thermal_min = stx_ivs_get_min_time(FMnt,0,nonthermal_min_time_lut=nonthermal_min_time_lut)
    min_time_img = [thermal_min,non_thermal_min]
  endif

  print, "","total","thermal","nonthermal",format="(A10,3A20)"
  print, "count",Ntot,Nt,Nnt, format="(A10,3I20)"
  print, "FM",FMtot,FMt,FMnt, format="(A10,3I20)"

  spectrogram_img = stx_fsw_ivs_resample_energy_binning(spectrogram, $
    termal_binning = stx_ivs_get_energy_binning(FMt,1,energy_binning_lut = energy_binning_lut), $
    nontermal_binning = stx_ivs_get_energy_binning(FMnt,0,energy_binning_lut = energy_binning_lut), $
    thermalboundary = thermalboundary_idx)


  spectrogram_img_p = ptr_new(spectrogram_img)
  spectrogram_p = ptr_new(spectrogram)

  n_e_resample = n_elements(spectrogram_img.energy_axis.MEAN)

  ;create RCR blocks
  rcr_blocks = list()
  start_t = 0
  
  
  if split_into_rcr_blocks eq 0 then rcr_resampled[*] = 0b
  if split_into_rcr_blocks eq 1 then begin
    idx = where(rcr_resampled ge 1, count)
    if count gt 0 then rcr_resampled[idx] = 1b
  endif
  

  for t=0, n_t-1 do begin
    if (t eq n_t-1) || (rcr_resampled[t] ne rcr_resampled[t+1])  then begin
      ;found a new RSR block and create a stx_ivs_column object

      rcr_block = stx_fsw_ivs_column_img(start_t, t, indgen(n_e_resample), spectrogram_img_p, $
        level = 0, thermalboundary=thermalboundary, min_time=min_time_img, min_count=min_count_img)

      rcr_block = rcr_block->get_merged_top_energy_channels();



      ;TODO n.h. rest restart here
      rcr_blocks->add, rcr_block

      start_t=t+1
    end
  end


  intervals = []
  all_splits = []
  
  if plotting then begin
    stx_interval_plot, spectrogram_img, thermalboundary = thermalboundary
  endif
  
  ;do a interval selection on each RCR block
  foreach rcr,  rcr_blocks, rcr_idx do begin
    ;concat all found intervals to the result list
    split_times = list()
    new_intervals = rcr->get_intervals(split_times = split_times, inclusion=0)

    split_times = split_times->toarray()

    if n_elements(new_intervals) eq 0 then begin
      split_times = [0,rcr->get_starttime_idx()]
      time_splits = [rcr->get_starttime_idx(), rcr->get_endtime_idx()]
      new_intervals = rcr->get_dafault_intervals()
    end else begin
      if n_elements(split_times) eq 0 then begin
        split_times = [0,rcr->get_starttime_idx()]
        time_splits = [rcr->get_starttime_idx(), rcr->get_endtime_idx()]
      end else begin
        st = split_times[*,1]
        st = st[sort(st)]

        time_splits = [rcr->get_starttime_idx(), st + 1, rcr->get_endtime_idx()]
      end
    end


    ;find all trim candidates
    trims =  where(new_intervals.trim gt 0, count_trims)
    if (count_trims gt 0) && (trimming_max_loss gt 0) then begin
      for i=0, count_trims-1 do begin
        ;replace the trim candidate interval with the trimmed interval
        time_splits_forTrimming = time_splits
        
        
        time_splits_forTrimming[-1]++
        new_intervals[trims[i]] = stx_fsw_ivs_trim_interval_orig(new_intervals[trims[i]],rcr->get_spectrogram(),time_splits_forTrimming, right=new_intervals[trims[i]].trim eq 2,max_loss=trimming_max_loss)
      endfor
    endif

    intervals = [intervals,new_intervals]



    all_splits = [all_splits, time_splits]
    
    if plotting then begin
       stx_interval_plot, rcr->get_spectrogram(), /overplot, intervals=new_intervals, plot_energy_binning = stx_time2any((rcr->get_spectrogram()).time_axis.time_start[rcr->get_starttime_idx()])
    endif
    
  endforeach

   all_splits = all_splits[uniq(all_splits)]
   ;N.H. in order to expand the last interval for spectroscopy to the very end
   all_splits[-1]++
 
  
  return, { type              : "stx_fsw_ivs_img_result" ,$
    intervals         : intervals ,$
    count_spectrogram : total_counts ,$
    pixel_count_spectrogram : pixel_counts ,$
    time_splits : all_splits, $
    spectrogram : spectrogram, $
    thermalboundary : thermalboundary, $
    ab_time_edges : time_edges $
  }

end