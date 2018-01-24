;+
; :FILE_COMMENTS:
;   scales and normalices the background and substracts is from the given spectrogram   
;
; :CATEGORIES:
;   flight software simulation, software
;    
;
; :HISTORY:
;   02-Nov-2015 - Nicky Hochmuth (FHNW), initial release 
;-

;+
; :DESCRIPTION:
;    scales and normalices the background and substracts is from the given spectrogram   
;
; :PARAMS:
;    counts                   : in, required, type="int_array(energy,time)"
;                               the given spectrogram data
;                               
;    background               : in, required, type="int_array(energy_bands)"
;                               the background value for some energy bands (by default there are 5 background bands)
;                               unit detector-averaged background counts (counts/sec/detector)
;    
;    energy_axis_background   : in, required, type="stx_energy_axis"
;                               the definitions of the background energy bands
;    
;    time_axis                : in, required, type="stx_time_axis"
;                               the time dimension of the count spectrogram 
;    
;    detector_mask            : in, required, type="byte_array(32)"
;                               a mask of used detectors for the background determination
;  
;  :RETURNS:
;   a new count spectrogram with removed background
;   negativ counts due to the background removel are set to 0 
;
;-
function stx_fsw_remove_background, counts, background, energy_axis_background, time_axis, detector_mask

  n_e = (size(counts, /dim))[0]
  n_active_detectors = total(detector_mask,/integer)

  ;unit from the background module: detector-averaged background counts (counts/sec/detector)

  ;normalice the energy band: counts/sec/detector/keV
  ;do we have that information (energy band with in keV) on the instrument
  ;background /= energy_axis_background.width

  ;normalice the energy band: counts/sec/detector/energy bin
  background /= (energy_axis_background.HIGH_FSW_IDX-energy_axis_background.LOW_FSW_IDX)+1

  ;make a full resolution energy background: counts/sec/detector/1
  full_bkg = background[value_locate(energy_axis_background.low_fsw_idx,indgen(n_e))]

  ;multiply by number of used detectors: counts/sec/1/1
  full_bkg *= n_active_detectors

  ;multiply by duration of each time bin in the archive buffer: counts/1/1/1
  background_spectrogram = full_bkg # transpose(time_axis.duration)

  ;substract background and set negativ counts to 0
  return, ulong((long(counts) - background_spectrogram) > 0)
  
end