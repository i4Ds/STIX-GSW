;+
;
; NAME:
;
;   stx_sum_pixel_data
;
; PURPOSE:
;
;   Construct a summed STIX pixel data structure (i.e., sum the counts to form a 32x4 element matrix, 
;   normalize for livetime, incident area, lenght of the energy interval considered, and correct for grid transmission)
;
; CALLING SEQUENCE:
;
;   pixel_data_summed = stx_sum_pixel_data(pixel_data)
;
; INPUTS:
;
;   pixel_data: STIX pixel data structure to be summed
;
; KEYWORDS:
;              
;   sumcase: string indicating which pixels are summed. Options: 
;            - 'ALL': top row + bottom row + small pixels
;            - 'TOP': top row pixels only
;            - 'BOTTOM': bottom row pixels only
;            - 'TOP+BOT': top row + bottom row pixels
;            - 'SMALL': small pixels only
;            Default, 'TOP+BOT'
;            
;            
;   subc_index: indices of the imaging detectors used. Default, indices of the subcollimators from 10 to 3. 
;               Used just for computing the total number of counts in the image
;   
;   silent: if set, no message is printed
;
; OUTPUTS:
;
;   'stx_pixel_data_summed' structure containing:
;
;   - LIVE_TIME: 32-element array containing the live time of each detector in the considered time interval
;   - TIME_RANGE: two-element STX_TIME array containg the start and the end of the selected time interval
;   - ENERGY_RANGE: array containing the lower and the upper edge of the selected energy interval
;   - COUNT_RATES: array 32x4 containing the value of the countrates A,B,C,D recorded by each subcollimator.
;                  Pixel measurements are summed (from 12 to 4) and countrates are normalized by live time,
;                  incident area and length of the energy interval considered (rates are then in counts s^-1 cm^-2 keV^-2). 
;                  Optionally, they are corrected for the grid internal shadowing and transmission
;   - COUNTS_RATES_ERROR: array 32x4 containing the errors associated with the countrates A,B,C,D recorded by each detector
;                         (compression errors and statistical errors are taken into account, no systematic errors are added)
;   - TOT_COUNTS: total number of counts recorded by the imaging subcollimators selected by means of 'subc_index'
;   - LIVE_TIME_BKG: 32-element array containing the live time of each detector during the background measurement          
;   - COUNT_RATES_BKG: array 32x4 containing the background countrates A,B,C,D recorded by each subcollimator. Pixel measurements 
;                       are summed (from 12 to 4) and countrates are normalized by live time, incident area, length of the considered energy 
;                       interval. Optionally, they are corrected for the grid internal shadowing and transmission
;   - COUNT_RATES_ERROR_BKG: array 32x4 containing the errors associated with the background countrates A,B,C,D recorded by each detector
;                         (compression errors and statistical errors are taken into account, no systematic errors are added)
;   - TOT_COUNTS_BKG: estimate of the total number of background counts recorded by the imaging subcollimators (selected with 'subc_index')
;                     in the considered time and energy interval
;   - RCR: Rate Control Regime status during the flare measurement
;   - XY_FLARE: 2-element array containing the X and Y coordinates of the estimated flare location (STIX coordinate frame, arcsec).
;               If 'xy_flare' is not passed, it is filled with NaN values
;   - SUMCASE: string indicating which pixels are summed (see above comment on 'sumcase' keyword for more details)
;   - DETECTOR_MASKS: 32-element array containing information on the detectors used for the measurement 
;                     (1 if the corresponding detector has been used, 0 otherwise)
;
; HISTORY: August 2022, Massa P., created
;          October 2023, Massa P., fixed bug in the estimation of the total number of bkg counts 
;
; CONTACT:
;   paolo.massa@wku.edu
;-
function stx_sum_pixel_data, pixel_data, subc_index=subc_index, sumcase=sumcase, silent=silent 

default, sumcase, 'TOP+BOT'
default, silent, 0
;; Imaging detectors
default, subc_index, stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
                                     '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

;;************** Sum counts, background counts and errors

case sumcase of

  'TOP':     begin
    pixel_ind = [0]
  end

  'BOT':     begin
    pixel_ind = [1]
  end

  'TOP+BOT': begin
    pixel_ind = [0,1]
  end

  'ALL': begin
    pixel_ind = [0,1,2]
  end

  'SMALL': begin
    pixel_ind = [2]
  end
end

;; Check if 'sumcase' is compatible with pixel masks (i.e., if the selected pixels have been used)
pixel_masks = reform(pixel_data.PIXEL_MASKS,4,3)

if total(pixel_masks[*,pixel_ind]) lt 4.*n_elements(pixel_ind) then message, "Change 'sumcase': one of the selected pixels is not available"

count_rates = reform(pixel_data.COUNTS, 32, 4, 3)
;; Compute total counts: saved in the pixel data structure
tot_counts     = total(count_rates[subc_index,*,pixel_ind])

count_rates = n_elements( pixel_ind ) eq 1 ? reform(count_rates[*, *, pixel_ind]) : $
              total( count_rates[*, *, pixel_ind], 3 )

counts_rates_error = reform(pixel_data.COUNTS_ERROR, 32, 4, 3)
counts_rates_error = n_elements( pixel_ind ) eq 1 ? reform(counts_rates_error[*, *, pixel_ind]) : $
                     sqrt(total( counts_rates_error[*, *, pixel_ind]^2, 3 ))

count_rates_bkg = reform(pixel_data.COUNTS_BKG, 32, 4, 3)
;; Compute total background counts: saved in the pixel data structure
tot_counts_bkg  = n_elements(pixel_ind) eq 1 ? total(reform(count_rates_bkg[subc_index,*,pixel_ind]),2) : $
                  total(total(count_rates_bkg[subc_index,*,pixel_ind],2),2)

count_rates_bkg = n_elements( pixel_ind ) eq 1 ? reform(count_rates_bkg[*, *, pixel_ind]) : $
                  total( count_rates_bkg[*, *, pixel_ind], 3 )
              
count_rates_error_bkg = reform(pixel_data.COUNTS_ERROR_BKG, 32, 4, 3)
count_rates_error_bkg = n_elements( pixel_ind ) eq 1 ? reform(count_rates_error_bkg[*, *, pixel_ind]) : $
                        sqrt(total( count_rates_error_bkg[*, *, pixel_ind]^2, 3 ))

;;************** Livetime correction: units are counts s^-1

live_time          = cmreplicate(pixel_data.LIVE_TIME, 4)
count_rates        = f_div(count_rates,live_time)
counts_rates_error = f_div(counts_rates_error,live_time)

;; Compute live time fraction of each detector. It is used for computing the total number of bkg counts 
time_range = stx_time2any(pixel_data.TIME_RANGE)
live_time_fraction = pixel_data.LIVE_TIME/(time_range[1]-time_range[0])

live_time_bkg         = pixel_data.LIVE_TIME_BKG
;; Estimate of the background counts in the image: only a fraction proportional to the time range
;; Multiply total number of bkg counts by the live time fraction of the science data. 
;; In this way, we keep into account that the live time fraction can be different between science and bkg data  
tot_counts_bkg = total(f_div(tot_counts_bkg*live_time_fraction[subc_index],live_time_bkg[subc_index])) $
                  * (time_range[1]-time_range[0])

live_time_bkg         = cmreplicate(pixel_data.LIVE_TIME_BKG, 4)
count_rates_bkg       = f_div(count_rates_bkg,live_time_bkg)
count_rates_error_bkg = f_div(count_rates_error_bkg,live_time_bkg)

;;************** Print total number of counts

if ~silent then begin
  
  print
  print
  print,'***********************************************************************'
  print,'Total number of counts in image:  '+strtrim(tot_counts)
  print,'Background counts:                '+strtrim(tot_counts_bkg)
  print,'Counts above background:          '+strtrim(tot_counts-tot_counts_bkg)
  print,'Total to background:              '+strtrim(tot_counts/tot_counts_bkg)
  print,'***********************************************************************'
  print
  print

endif

;;************** Normalization per keV: units are counts s^-1 keV^-1

energy_range = pixel_data.ENERGY_RANGE
count_rates        = count_rates/(energy_range[1]-energy_range[0])
counts_rates_error = counts_rates_error/(energy_range[1]-energy_range[0])

count_rates_bkg       = count_rates_bkg/(energy_range[1]-energy_range[0])
count_rates_error_bkg = count_rates_error_bkg/(energy_range[1]-energy_range[0])

;;************** Normalization for effective area: units are counts s^-1 keV^-1 cm^-2

subc_str = stx_construct_subcollimator()
eff_area = subc_str.det.pixel.area
eff_area = reform(transpose(eff_area), 32, 4, 3)
eff_area = n_elements( pixel_ind ) eq 1 ? reform(eff_area[*, *, pixel_ind]) : total(eff_area[*,*,pixel_ind], 3)

count_rates           = count_rates/eff_area
counts_rates_error    = counts_rates_error/eff_area
count_rates_bkg       = count_rates_bkg/eff_area
count_rates_error_bkg = count_rates_error_bkg/eff_area

;;************** Fill in calibrated pixel data structure

pixel_data_summed = stx_pixel_data_summed()

pixel_data_summed.LIVE_TIME    = pixel_data.LIVE_TIME
pixel_data_summed.TIME_RANGE   = pixel_data.TIME_RANGE
pixel_data_summed.ENERGY_RANGE = pixel_data.ENERGY_RANGE
pixel_data_summed.COUNT_RATES  = count_rates
pixel_data_summed.COUNTS_RATES_ERROR = counts_rates_error
pixel_data_summed.TOT_COUNTS      = tot_counts
pixel_data_summed.LIVE_TIME_BKG   = pixel_data.LIVE_TIME_BKG
pixel_data_summed.COUNT_RATES_BKG = count_rates_bkg
pixel_data_summed.COUNT_RATES_ERROR_BKG = count_rates_error_bkg
pixel_data_summed.TOT_COUNTS_BKG = tot_counts_bkg
pixel_data_summed.RCR            = pixel_data.RCR                
pixel_data_summed.XY_FLARE       = pixel_data.XY_FLARE
pixel_data_summed.SUMCASE        = sumcase
pixel_data_summed.DETECTOR_MASKS = pixel_data.DETECTOR_MASKS

return, pixel_data_summed

end