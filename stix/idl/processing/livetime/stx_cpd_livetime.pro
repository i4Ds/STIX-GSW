;+
;
; NAME:
; 
;   stx_cpd_livetime
;   
; PURPOSE:
;
;   Calculate the live time and associated uncertainty for a Compressed Pixel Data (CPD) file.
;
; CALLING SEQUENCE:
; 
;   live_time_data = stx_cpd_livetime(triggers, triggers_err, t_axis)
;
; INPUTS:
; 
;   triggers: array (dimensions: 16 x num. time bins) containing the trigger values
;   triggers_err: array (dimensions: 16 x num. time bins) containing the uncertainty on the trigger values
;   t_axis: 'stx_time_axis' structure returned by 'stx_read_pixel_data_fits_file'
;
; OUTPUTS:
; 
;   Structure containing:
;   - LIVE_TIME_BINS: array (dimensions: 32 × number of time bins) containing the live time value 
;                     for each time bin in the CPD file
;   - LIVE_TIME_BINS_ERR: array (dimensions: 32 × number of time bins) containing the uncertainty on 
;                         the live time value for each time bin in the CPD file
;   - LIVETIME_FRACTION: array (dimensions: 32 × number of time bins) containing the value of 
;                        the live time fraction for each time bin in the CPD file
;   - LIVETIME_FRACTION_ERR: array (dimensions: 32 × number of time bins) containing the uncertainty on
;                        the live time fraction for each time bin in the CPD file
;
; HISTORY: 
;   May 2025, Massa P. (FHNW), first release
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_cpd_livetime, triggers, triggers_err, t_axis

  triggergram        = stx_triggergram(triggers, triggers_err, t_axis)
 
  livetime_fraction_data = stx_livetime_fraction(triggergram)
  livetime_fraction = livetime_fraction_data.livetime_fraction
  livetime_fraction_err = livetime_fraction_data.livetime_fraction_err
  
  duration_time_bins = t_axis.DURATION
  duration_time_bins = transpose(cmreplicate(duration_time_bins, 32))

  live_time_bins     = livetime_fraction * duration_time_bins
  live_time_bins_err = livetime_fraction_err * duration_time_bins

  return, {live_time_bins: live_time_bins,$
           live_time_bins_err: live_time_bins_err,$
           livetime_fraction: livetime_fraction, $
           livetime_fraction_err: livetime_fraction_err}

end
