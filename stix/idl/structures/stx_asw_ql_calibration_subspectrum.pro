function stx_asw_ql_calibration_subspectrum, subspectra_definition=subspectra_definition, spectral_points=spectral_points, $
  pixel_mask=pixel_mask, detector_mask=detector_mask
  
  ppl_require, in=subspectra_definition, type='int*'
  ppl_require, in=detector_mask, type='byte*'
  ppl_require, in=pixel_mask, type='byte*'
  
 
  nbr_pixels = fix(total(pixel_mask))
  nbr_detector = fix(total(detector_mask))
  if n_elements(spectral_points) eq 0 then spectral_points=lonarr(subspectra_mask[0],nbr_pixels,nbr_detectors)
 
  
   return, { $
    type                            : 'stx_asw_ql_calibration_subspectrum', $
    spectrum                        : spectral_points, $
    lower_energy_bound_channel      : subspectra_definition[0], $
    number_of_summed_channels       : subspectra_definition[1], $
    number_of_spectral_points       : subspectra_definition[2], $
    pixel_mask                      : pixel_mask, $
    detector_mask                   : detector_mask $
  }


end