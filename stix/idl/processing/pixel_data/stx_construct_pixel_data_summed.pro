;+
;
; NAME:
;
;   stx_construct_pixel_data_summed
;
; PURPOSE:
;
;   Read a STIX science L1 fits file (and optionally a STIX background L1 fits file) and contruct a 
;   'stx_pixel_data_summed' structure
;
; CALLING SEQUENCE:
;
;   pixel_data_summed = stx_construct_pixel_data_summed(path_sci_file, time_range, energy_range)
;
; INPUTS:
;
;   path_sci_file: path of the STIX science L1 fits file
;
;   time_range: string array containing the start and the end of the time interval to consider
;
;   energy_range: two-element array containing the lower and upper edges of the energy interval to consider
;
; OUTPUTS:
;
;   'stx_pixel_data_summed' (see the header of 'stx_sum_pixel_data' for more details)

;
; KEYWORDS:
;
;   path_bkg_file: path of a background L1 fits file. If provided, the fields 'COUNT_RATES_BKG', 'COUNT_RATES_ERROR_BKG' 
;                  and 'LIVE_TIME_BKG' of the output 'stx_pixel_data_summed' structure are filled with the values read from the 
;                  background measurement file               
;   
;   subc_index:  array containing the indices of the selected imginging detectors. Used only for plotting the lightcurve by means of
;             'stx_plot_selected_time_range' and for computing the total number of counts in the image. Default, indices of
;             the detectors from 10 to 3
;   
;   sumcase: string indicating which pixels are summed. See the header of 'stx_sum_pixel_data' for 
;            more information
;   
;   silent: if set, no message is printed and no plot is displayed
;   
;   no_small: if set, Moire patterns measured by small pixels are not plotted with 'stx_plot_moire_pattern'
;   
;   no_rcr_check: if set, control on RCR change during the selected time interval is not performed
;
; HISTORY: July 2022, Massa P., created
;          January 2026, Massa P., removed 'xy_flare' keyword. Grid transmission correction is not performed 
;                                  at this stage
;          March 2026, Massa P., removed 'elut_corr' keyword as not necessary
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_construct_pixel_data_summed, path_sci_file, time_range, energy_range, path_bkg_file=path_bkg_file, $
                                          subc_index=subc_index, sumcase=sumcase, silent=silent, no_small=no_small,$
                                          no_rcr_check=no_rcr_check, _extra=extra                                                                           

;;************** Construct pixel data

pixel_data = stx_construct_pixel_data(path_sci_file, time_range, energy_range, $
                                      path_bkg_file=path_bkg_file, subc_index=subc_index, sumcase=sumcase, $
                                      silent=silent, no_small=no_small, no_rcr_check=no_rcr_check, _extra=extra)                                     
;;************** Sum pixel data
  
pixel_data_summed = stx_sum_pixel_data(pixel_data, subc_index=subc_index, sumcase=sumcase, silent=silent)

return, pixel_data_summed

end
