function stx_fsw_ivs, stx_fsw_archive_buffer, start_time, rcr, rcr_time_axis,  $
  thermalboundary_idx                   = thermalboundary_idx, $
  trimming_max_loss                     = trimming_max_loss, $
  min_time_img                          = min_time_img, $
  min_count_img                         = min_count_img, $
  min_count_spc                         = min_count_spc, $
  min_time_spc                          = min_time_spc, $
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
  energy_axis_background                = energy_axis_background
 

  pixel_counts = stx_fsw_compact_archive_buffer(stx_fsw_archive_buffer, $
    start_time = start_time, $
    detector_mask = detector_mask, $
    ;out
    time_axis = time_axis, $
    time_edges = time_edges, $
    total_counts=total_counts, $
    disabled_detectors_total_counts=disabled_detectors_total_counts)



  n_t = n_elements(time_axis.duration)

  ;TODO: handel attenuator_state/rcr properly
  attenuator_state = bytarr(n_t)
  ids = stx_time_locate(rcr_time_axis,time_axis.mean)
  matches = where(ids gt -1, count_matches)
  if count_matches gt 0 then attenuator_state[matches] = rcr[ids[matches]]


  ;remove background
  if remove_background then begin
    print, "remove background"
    n_active_detectors = total(detector_mask,/integer)

    ;unit from the background module: detector-averaged background counts (counts/sec/detector)

    ;normalice the energy band: counts/sec/detector/keV
    ;do we have that information (energy band with in keV) on the instrument
    ;background /= energy_axis_background.width

    ;normalice the energy band: counts/sec/detector/energy bin
    background /= (energy_axis_background.HIGH_FSW_IDX-energy_axis_background.LOW_FSW_IDX)+1

    ;make a full resolution energy background: counts/sec/detector/1
    full_bkg = background[value_locate(energy_axis_background.low_fsw_idx,indgen(32))]

    ;multiply by number of used detectors: counts/sec/1/1
    full_bkg *= n_active_detectors

    ;multiply by duration of each time bin in the archive buffer: counts/1/1/1
    background_spectrogram = full_bkg # transpose(time_axis.duration)

    ;substract background and set negativ counts to 0
    disabled_detectors_total_counts = ulong((long(disabled_detectors_total_counts) - background_spectrogram) > 0)
  end


  spectrogram = stx_spectrogram(disabled_detectors_total_counts, time_axis, stx_construct_energy_axis(), fltarr(32, n_t), attenuator_state=attenuator_state)

  ;plotting=1

  intervals = stx_ivs(spectrogram, $
    thermalboundary_idx                   = thermalboundary_idx, $
    min_time_img                          = min_time_img, $
    min_count_img                         = min_count_img, $
    min_count_spc                         = min_count_spc, $
    min_time_spc                          = min_time_spc, $
    trimming_max_loss                     = trimming_max_loss, $
    thermal_boundary_lut                  = thermal_boundary_lut, $
    total_flare_magnitude_index_lut       = total_flare_magnitude_index_lut, $
    thermal_flare_magnitude_index_lut     = thermal_flare_magnitude_index_lut, $
    nonthermal_flare_magnitude_index_lut  = nonthermal_flare_magnitude_index_lut, $
    thermal_min_count_lut                 = thermal_min_count_lut, $
    nonthermal_min_count_lut              = nonthermal_min_count_lut, $
    thermal_min_time_lut                  = thermal_min_time_lut, $
    nonthermal_min_time_lut               = nonthermal_min_time_lut, $
    energy_binning_lut                    = energy_binning_lut, $
    plotting                              = plotting, $
    hide_spectroscopy_intervals           = 0, $
    hide_imaging_intervals                = 0)

  return, { type              : "stx_fsw_ivs_result" ,$
    intervals         : intervals ,$
    count_spectrogram : total_counts ,$
    pixel_count_spectrogram : pixel_counts ,$
    ab_time_edges : time_edges $
  }
end