;+
;
; NAME:
;
;   stx_construct_visibility
;
; PURPOSE:
; 
;   Read a STIX science L1 fits file (and potentially a STIX background L1 fits file) and contruct a 
;   'stx_visibility' structure
;
; CALLING SEQUENCE:
;
;   vis = stx_construct_visibility(path_sci_file, time_range, energy_range)
;
; INPUTS:
;   
;   path_sci_file: path of the STIX science L1 fits file
;   
;   time_range: string array containing the start and the end of the time interval to consider
;   
;   energy_range: array containing the values of the lower and upper edge of the energy interval to consider
;   
;   mapcenter: bi-dimensional array containing the coordinates of the center of the map to reconstruct
;              from the visibility values (STIX coordinate frame, arcsec)
;
; KEYWORDS:
;   
;   bkg_file_path: if provided, the background counts are subtracted before computing the visibility values and the
;                  field 'TOT_COUNTS_BKG' of the visibility structure is filled in
;   
;   elut_corr: if set, a correction based on a ELUT table is applied to the measured counts
;   
;   xy_flare: bi-dimensional array containing the coordinates of the estimated flare location (STIX coordinate frame, arcsec). 
;             It is used for computing the grid transmission correction and the phase projection correction. 
;             If it is not provided, no correction is applied and the corresponding field in the visibility structure is filled with NaN.
;             
;   sumcase: string containing information on the pixels to be considered for computing the visibilities (see
;            the header of 'stx_calibrate_pixel_data' for more information). Default, 'ALL'
;            
;   f2r_sep: distance between the front and the rear grid (mm, used for computing the values of the (u,v) frequencies). 
;            Default, 550 mm
;   
;   silent: if set, no message is printed
;   
;   subc_index: array containing the indexes of the subcollimators to be used for computing the visibilities.
;               Default, subcollimators labelled from 3 to 10.
;
;
; OUTPUTS:
;
;   Uncalibrated 'stx_visibility' structure containing:
;
;   - ISC: indexes of the considered subcollimators
;   - LABEL: labels of the considered subcollimators
;   - LIVE_TIME: detectors' livetime
;   - ENERGY_RANGE: bi-dimensional array containing the lower and upper edge of the considered energy interval
;   - TIME_RANGE: bi-dimensional 'stx_time' array containing the lower and upper edge of the considered time interval
;   - OBSVIS: complex array containing the visibility values
;   - TOT_COUNTS: total number of counts recorded by the STIX imaging subcollimators (labelled from 3 to 10) 
;                 during the flaring event
;   - TOT_COUNTS_BKG: if 'bkg_file_path' is provided, it contains an estimate of the total number of background counts 
;                     recorded by the STIX imaging subcollimators (labelled from 3 to 10) during the flaring event
;   - SIGAMP: estimate of the errors on the visibility amplitudes
;   - U: u coordinate of the frequencies sampled by the sub-collimators
;   - V: v coordinate of the frequencies sampled by the sub-collimators
;   - PHASE_SENSE: array containing the sense of the phase measured by the sub-collimator (-1 or 1 values)
;   - MAPCENTER: bi-dimensional array containing the coordinates of the center of the map to renconstruct from the
;                visibiity values
;   - XY_FLARE: bi-dimensional array containing the coordinates of the estimated flare location. It is used for computing
;               the grid transmission correction and the phase projection correction. If the values are NaN, no correction
;               is applied
;   - CALIBRATED: 0 if the values of the visibility amplitudes and phases are not calibrated, 1 otherwise
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-
function stx_construct_visibility, path_sci_file, time_range, energy_range, mapcenter, bkg_file_path=bkg_file_path, $
                                   elut_corr=elut_corr, xy_flare=xy_flare, $
                                   sumcase=sumcase, f2r_sep=f2r_sep, silent=silent, $
                                   subc_index=subc_index, _extra=extra

calibrated_pixel_data = stx_construct_calibrated_pixel_data(path_sci_file, time_range, energy_range, $
                                                            bkg_file_path=bkg_file_path, $
                                                            elut_corr=elut_corr, xy_flare=xy_flare, $
                                                            sumcase=sumcase, silent=silent, _extra=extra)

vis = stx_calibrated_pixel_data2visibility(calibrated_pixel_data, subc_index=subc_index, $
                                           f2r_sep=f2r_sep, mapcenter=mapcenter)                                                         
                                       
return, vis

end
