;+
;
; NAME:
;
;   stx_construct_visibility
;
; PURPOSE:
; 
;   Read a STIX science L1 fits file (and optionally a STIX background L1 fits file) and contruct a 
;   'stx_visibility' structure
;
; CALLING SEQUENCE:
;
;   vis = stx_construct_visibility(path_sci_file, time_range, energy_range, mapcenter)
;
; INPUTS:
;   
;   path_sci_file: path of the STIX science L1 fits file
;   
;   time_range: string array containing the start and the end of the time interval to consider
;   
;   energy_range: array containing the values of the lower and upper edge of the energy interval to consider
;
; KEYWORDS:
;   
;   path_bkg_file: if provided, the background counts are subtracted to the countrates before computing the visibility values.
;                  Further, the field 'TOT_COUNTS_BKG' of the visibility structure is filled in with an estimate of the total
;                  number of background counts that are measured in the selected time and energy intervals
;             
;   sumcase: string indicating which pixels are summed for computing the visibilities (see the header of 
;            'stx_calibrate_pixel_data' for more information). Default, 'TOP+BOT'
;   
;   silent: if set, no message is printed
;   
;   subc_index: array containing the indices of the subcollimators that are used for computing the visibilities.
;               Default, subcollimators labelled from 10 to 3.
;
;   no_small: if set, Moire patterns measured by small pixels are not plotted with 'stx_plot_moire_pattern'
;   
;   no_rcr_check: if set, control on RCR change during the selected time interval is not performed
;
; OUTPUTS:
;
;   Uncalibrated 'stx_visibility' structure containing:
;
;   - ISC: indices of the considered subcollimators
;   - LABEL: labels of the considered subcollimators
;   - LIVE_TIME: detector livetime 
;   - ENERGY_RANGE: two-element array containing the lower and upper edge of the considered energy interval
;   - TIME_RANGE: two-element 'stx_time' array containing the lower and upper edge of the considered time interval
;   - OBSVIS: complex array containing the visibility values
;   - TOT_COUNTS: total number of counts recorded by STIX during the flaring events
;   - TOT_COUNTS_BKG: estimate of the total number of background counts recorded during the flaring events
;   - TOTFLUX: estimate of the total flux recorded by each detector, i.e., A+B+C+D
;   - SIGAMP: estimate of the errors on the visibility amplitudes
;   - U: u coordinate of the frequencies sampled by the sub-collimators
;   - V: v coordinate of the frequencies sampled by the sub-collimators
;   - PHASE_SENSE: array containing the sense of the phase measured by the sub-collimator (-1 or 1 values)
;   - XYOFFSET: two-element array containing the coordinates of the center of the map to renconstruct from the
;               visibility values (Default, (0,0))
;   - XY_FLARE: two-element array containing the coordinates of the estimated flare location (STIX coordinate frame, arcsec), 
;               which is used for computing the grid transmission correction. It is initialized with NaN values. 
;               If no correction is applied later (see stx_calibrate_visibility.pro), it remains filled with NaNs. 
;               Otherwise, it will contain the coordinates of the location that is used for grid transmission correction.
;   - CALIBRATED: 0 if the values of the visibility amplitudes and phases are not calibrated, 1 otherwise
;
; HISTORY: August 2022, Massa P., created
;          January 2026, Massa P., removed 'xy_flare' keyword. Grid transmission correction is used only for visibility amplitude calibration
;          March 2026, Massa P., removed 'mapcenter', 'elut_corr', and 'f2r_sep' keywords as not necessary
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-
function stx_construct_visibility, path_sci_file, time_range, energy_range, path_bkg_file=path_bkg_file, $
                                   sumcase=sumcase, silent=silent, subc_index=subc_index, no_small=no_small, $
                                   no_rcr_check=no_rcr_check, _extra=extra

;;************** Construct a 'stx_pixel_data_summed' structure
                             
pixel_data_summed = stx_construct_pixel_data_summed(path_sci_file, time_range, energy_range, $
                                                    path_bkg_file=path_bkg_file, subc_index=subc_index, $
                                                    sumcase=sumcase, silent=silent,no_small=no_small, $
                                                    no_rcr_check=no_rcr_check, _extra=extra)

;;************** Create an uncalibrated 'stx_visibility' structure from a the correpsonding 'stx_pixel_data_summed' structure

vis = stx_pixel_data_summed2visibility(pixel_data_summed, subc_index=subc_index, _extra=extra)                                                         
                                       
return, vis

end
