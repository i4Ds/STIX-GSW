;+
;
; NAME:
;
;   stx_construct_pixel_data_summed
;
; PURPOSE:
;
;   Read a STIX science L1 fits file (and potentially a STIX background L1 fits file) and contruct a 'stx_pixel_data_summed' structure
;
; CALLING SEQUENCE:
;
;   pixel_data_summed = stx_construct_pixel_data_summed(sci_file_path, time_range, energy_range)
;
; INPUTS:
;
;   sci_file_path: path of the STIX science L1 fits file
;
;   time_range: string array containing the start and the end of the time interval to consider
;
;   energy_range: array containing the values of the lower and upper edge of the energy interval to consider
;
; OUTPUTS:
;
;   'stx_pixel_data_summed' (see the header of 'stx_sum_pixel_data' for more details)

;
; KEYWORDS:
;
;   path_bkg_file: if provided, the fields 'COUNT_RATES_BKG', 'COUNT_RATES_ERROR_BKG' and 'LIVE_TIME_BKG' of 
;                  the calibrated pixel data structure are filled with the values read from the background 
;                  measurement file
;                  
;   elut_corr: if set, a correction based on a ELUT table is applied to the measured counts
;   
;   xy_flare: bidimensional array containing the X and Y coordinate of an estimate of the flare location
;              (STIX coordinate frame, arcsec). If set, a correction for the subcollimator transmission is applied 
;              to the measured count rates
;              
;   sumcase: string containing information on the pixels to be summed. See the header of 'stx_calibrate_pixel_data' for 
;            more information
;   
;   silent: if set, no message is printed
;              
;
; HISTORY: July 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_construct_pixel_data_summed, path_sci_file, time_range, energy_range, path_bkg_file=path_bkg_file, $
                                          elut_corr=elut_corr, xy_flare=xy_flare, $
                                          sumcase=sumcase, silent=silent, _extra=extra                                                                           

;;************** Construct pixel data

pixel_data = stx_construct_pixel_data(path_sci_file, time_range, energy_range, elut_corr=elut_corr, $
                                      path_bkg_file=path_bkg_file, _extra=extra)
                                      
;;************** Calibrate pixel data

pixel_data_summed = stx_sum_pixel_data(pixel_data, xy_flare=xy_flare, sumcase=sumcase, silent=silent)

return, pixel_data_summed

end
