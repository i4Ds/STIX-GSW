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
;            - 'BOT': bottom row pixels only
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
;   - TOT_COUNTS_BKG: estimate of the total number of background counts recorded by the imaging subcollimators (selected with 'subc_index')
;                     in the considered time and energy interval
;   - RCR: Rate Control Regime status during the flare measurement
;   - SUMCASE: string indicating which pixels are summed (see above comment on 'sumcase' keyword for more details)
;   - DETECTOR_MASKS: 32-element array containing information on the detectors used for the measurement 
;                     (1 if the corresponding detector has been used, 0 otherwise)
;
; HISTORY: August 2022, Massa P., created
;          October 2023, Massa P., fixed bug in the estimation of the total number of bkg counts 
;          January 2026, Massa P., removed 'xy_flare' entry as grid transmission correction is not applied anymore to the raw counts
;          March 2026, Massa P., made it compatible with new ELUT correction
;
; CONTACT:
;   paolo.massa@fhnw.ch
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

counts = reform(pixel_data.COUNTS, 32, 4, 3)
;; Compute total counts: saved in the pixel data structure
tot_counts     = total(counts[subc_index,*,pixel_ind])

counts = n_elements( pixel_ind ) eq 1 ? reform(counts[*, *, pixel_ind]) : $
              total( counts[*, *, pixel_ind], 3 )

counts_error = reform(pixel_data.COUNTS_ERROR, 32, 4, 3)
counts_error = n_elements( pixel_ind ) eq 1 ? reform(counts_error[*, *, pixel_ind]) : $
                     sqrt(total( counts_error[*, *, pixel_ind]^2, 3 ))

;;************** Livetime correction: units are counts s^-1

live_time          = cmreplicate(pixel_data.LIVE_TIME, 4)
live_time_error    = cmreplicate(pixel_data.LIVE_TIME_ERROR, 4)
count_rates        = f_div(counts,live_time)
counts_rates_error = abs(count_rates) * sqrt( f_div(counts_error,counts)^2. + f_div(live_time_error,live_time)^2. )

;;************** Normalization per keV: units are counts s^-1 keV^-1

energy_range = pixel_data.ENERGY_RANGE
count_rates        = count_rates/(energy_range[1]-energy_range[0])
counts_rates_error = counts_rates_error/(energy_range[1]-energy_range[0])

;;************** Normalization for effective area: units are counts s^-1 keV^-1 cm^-2

subc_str = stx_construct_subcollimator()
eff_area = subc_str.det.pixel.area
eff_area = reform(transpose(eff_area), 32, 4, 3)
eff_area = n_elements( pixel_ind ) eq 1 ? reform(eff_area[*, *, pixel_ind]) : total(eff_area[*,*,pixel_ind], 3)

count_rates           = count_rates/eff_area
counts_rates_error    = counts_rates_error/eff_area

;;************** Fill in calibrated pixel data structure

pixel_data_summed = stx_pixel_data_summed()

pixel_data_summed.LIVE_TIME    = pixel_data.LIVE_TIME
pixel_data_summed.TIME_RANGE   = pixel_data.TIME_RANGE
pixel_data_summed.ENERGY_RANGE = pixel_data.ENERGY_RANGE
pixel_data_summed.COUNT_RATES  = count_rates
pixel_data_summed.COUNTS_RATES_ERROR = counts_rates_error
pixel_data_summed.TOT_COUNTS      = pixel_data.tot_counts
pixel_data_summed.TOT_COUNTS_BKG = pixel_data.tot_counts_bkg
pixel_data_summed.RCR            = pixel_data.RCR                
pixel_data_summed.SUMCASE        = sumcase
pixel_data_summed.DETECTOR_MASKS = pixel_data.DETECTOR_MASKS

return, pixel_data_summed

end
