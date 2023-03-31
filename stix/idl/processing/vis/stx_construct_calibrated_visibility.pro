;+
;
; NAME:
;
;   stx_construct_calibrated_visibility
;
; PURPOSE:
;
;   Read a STIX science L1 fits file (and potentially a STIX background L1 fits file) and contruct a
;   calibrated 'stx_visibility' structure
;
; CALLING SEQUENCE:
;
;   vis = stx_construct_calibrated_visibility(path_sci_file, time_range, energy_range)
;
; INPUTS:
;
;   path_sci_file: path of the STIX science L1 fits file
;
;   time_range: string array containing the start and the end of the time interval to consider
;
;   energy_range: array containing the values of the lower and upper edge of the energy interval to consider
;   
;   mapcenter: two-element array containing the coordinates of the center of the map to reconstruct
;              from the visibility values (STIX coordinate frame, arcsec)
;
; KEYWORDS:
;
;   path_bkg_file: if provided, the background counts are subtracted before computing the visibility values and the
;                  field 'TOT_COUNTS_BKG' of the visibility structure is filled in
;
;   elut_corr: if set, a correction based on a ELUT table is applied to the measured counts
;
;   xy_flare: two-element array containing the coordinates of the estimated flare location (STIX coordinate frame, arcsec).
;             It is used for computing the grid transmission correction and the phase projection correction.
;             If it is not provided, no correction is applied and the corresponding field in the visibility structure is filled with NaN.
;
;   sumcase: string containing information on the pixels to be considered for computing the visibilities
;            (see the header of 'stx_sum_pixel_data' for more details).
;
;   f2r_sep: distance between the front and the rear grid (mm, used for computing the values of the (u,v) frequencies).
;            Default, 550 mm
;   
;   r2d_sep: distance between the rear grid and the detectors (mm, used for computing the projection correction factors).
;            Default, 47 mm
;   
;   silent: if set, no message is printed
;
;   subc_index: array containing the indexes of the subcollimators to be used for computing the visibilities.
;               Default, subcollimators labelled from 3 to 10.
;
;   phase_calib_factors: 32-element array containing the phase calibration factors. For information on the default
;                        values see the header of 'stx_calibrate_visibility'
;                        
;   amp_calib_factors: 32-element array containing the amplitude calibration factors. For information on the default
;                      values see the header of 'stx_calibrate_visibility'
;                      
;   syserr_sigamp: percentage of systematic error added in quadrature to the error on the visibility amplitudes derived
;                  from statistical and compression errors
;                  
;   no_small: if set, Moire patterns measured by small pixels are not plotted with 'stx_plot_moire_pattern'
;   
;   no_rcr_check: if set, control on RCR change during the selected time interval is not performed
;
; OUTPUTS:
;
;   Calibrated 'stx_visibility' structure. The calibration process consists in the calibration of the visibility
;   amplitudes and phases. For information on the fields of the visibility structure see the header of 'stx_construct_visibility'
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_construct_calibrated_visibility, path_sci_file, time_range, energy_range, mapcenter, $
                                              path_bkg_file=path_bkg_file, elut_corr=elut_corr, xy_flare=xy_flare, $
                                              sumcase=sumcase, f2r_sep=f2r_sep, r2d_sep=r2d_sep, silent=silent, $
                                              subc_index=subc_index, phase_calib_factors=phase_calib_factors, $
                                              amp_calib_factors=amp_calib_factors, syserr_sigamp = syserr_sigamp, $
                                              no_small=no_small, no_rcr_check=no_rcr_check, _extra=extra
                                              


;;*********** Create visibility structure

vis = stx_construct_visibility(path_sci_file, time_range, energy_range, mapcenter, path_bkg_file=path_bkg_file, $
                               elut_corr=elut_corr, xy_flare=xy_flare, $
                               sumcase=sumcase, f2r_sep=f2r_sep, silent=silent, $
                               subc_index=subc_index, no_small=no_small, no_rcr_check=no_rcr_check, _extra=extra)

;;*********** Calibrate visibility

calibrated_vis = stx_calibrate_visibility(vis, phase_calib_factors=phase_calib_factors, $
                                          amp_calib_factors=amp_calib_factors, $
                                          syserr_sigamp = syserr_sigamp, r2d_sep=r2d_sep, f2r_sep=f2r_sep)

;;********** Plot visibility amplitudes vs resolution (if ~silent)

if ~silent then stx_plot_vis_amp_vs_resolution, calibrated_vis


return, calibrated_vis

end
