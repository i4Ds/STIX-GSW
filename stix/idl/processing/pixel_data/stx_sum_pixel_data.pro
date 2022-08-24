;+
;
; NAME:
;
;   stx_sum_pixel_data
;
; PURPOSE:
;
;   Construct a summed STIX pixel data structure (i.e., sum the counts to form a 32x4 dimensional matrix, 
;   normalize for livetime, incident area, lenght of the energy interval considered, and correct for grid internal shadowing)
;
; CALLING SEQUENCE:
;
;   pixel_data_summed = stx_sum_pixel_data(pixel_data, flare_loc=flare_loc, sumcase=sumcase, silent=silent)
;
; INPUTS:
;
;   pixel_data: STIX pixel data structure to be summed
;
; KEYWORDS:
; 
;   xy_flare: bidimensional array containing the X and Y coordinates of an estimate of the flare location
;              (conceived in the STIX coordinate frame, arcsec)
;              
;   sumcase: string containing information on the pixels to be summed. Options: 
;            - 'ALL': top row + bottom row + small pixels
;            - 'TOP': top row pixels only
;            - 'BOTTOM': bottom row pixels only
;            - 'TOP+BOTTOM': top row + bottom row pixels
;            - 'SMALL': small pixels only
;   
;   silent: if set, no message is printed
;
; OUTPUTS:
;
;   'stx_pixel_data_summed' structure containing:
;
;   - LIVE_TIME: 32-dimensional array containing the live time of each detector in the considered time interval
;   - TIME_RANGE: STX_TIME array containg the start and the end of the selected time interval
;   - ENERGY_RANGE: array containing the lower and the upper edge of the selected energy interval
;   - COUNT_RATES: array 32x4 containing the value of the countrates A,B,C,D recorded by each subcollimator.
;                  Pixel measurements are summed (from 12 to 4) and countrates are normalized by live time,
;                  incident area, length of the energy interval considered. Optionally, they are corrected by the
;                  grid internal shadowing and transmission
;   - COUNTS_RATES_ERROR: array 32x4 containing the errors associated to the countrates A,B,C,D recorded by each detector
;                         (compression errors and statistical errors are taken into account, no systematic)
;   - TOT_COUNTS: total number of counts recorded by the imaging subcollimators (labelled from 3 to 10)
;   - LIVE_TIME_BKG: 32-dimensional array containing the live time of each detector during the background measurement          
;   - COUNT_RATES_BKG: array 32x4 containing the background countrates A,B,C,D recorded by each subcollimator. Pixel measurements are summed (from 12 to 4) and countrates are normalized by live time,
;                  incident area, length of the energy interval considered. Optionally, they are corrected by the
;                  grid internal shadowing and transmission
;   - COUNT_RATES_ERROR_BKG: array 32x4 containing the errors associated with the background countrates A,B,C,D recorded by each detector
;                         (compression errors and statistical errors are taken into account, no systematic)
;   - TOT_COUNTS_BKG: estimate of the total number of background counts recorded by the imaging subcollimators (3 to 10) 
;                     in the selected time and energy interval
;   - RCR: Rate Control Regime status during the flare measurement
;   - XY_FLARE: 2-dimensional array containing the X and Y coordinates of the estimated flare location (STIX coordinate frame, arcsec)
;   - SUMCASE: string describing which pixels have been summed (see comment on 'sumcase' keyword above for more details)
;   - DETECTOR_MASKS: 32-dimensional array containing information on the detectors used for the measurement 
;                     (1 if the corresponding detector has been used, 0 otherwise)
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-








; TBD: 
; 1) Check pixel mask
; 2) modify stix_label2ind


function stx_sum_pixel_data, pixel_data, xy_flare=xy_flare, sumcase=sumcase, silent=silent

default, sumcase, 'ALL'
default, silent, 0

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


count_rates = reform(pixel_data.COUNTS, 32, 4, 3)
count_rates = n_elements( pixel_ind ) eq 1 ? reform(count_rates[*, *, pixel_ind]) : $
              total( count_rates[*, *, pixel_ind], 3 )

counts_rates_error = reform(pixel_data.COUNTS_ERROR, 32, 4, 3)
counts_rates_error = n_elements( pixel_ind ) eq 1 ? reform(counts_rates_error[*, *, pixel_ind]) : $
                     sqrt(total( counts_rates_error[*, *, pixel_ind]^2, 3 ))

count_rates_bkg = reform(pixel_data.COUNTS_BKG, 32, 4, 3)
count_rates_bkg = n_elements( pixel_ind ) eq 1 ? reform(count_rates_bkg[*, *, pixel_ind]) : $
                  total( count_rates_bkg[*, *, pixel_ind], 3 )
              
count_rates_error_bkg = reform(pixel_data.COUNTS_ERROR_BKG, 32, 4, 3)
count_rates_error_bkg = n_elements( pixel_ind ) eq 1 ? reform(count_rates_error_bkg[*, *, pixel_ind]) : $
                        sqrt(total( count_rates_error_bkg[*, *, pixel_ind]^2, 3 ))

;;************** Livetime correction: units are counts s^-1

live_time          = cmreplicate(pixel_data.LIVE_TIME, 4)
count_rates        = f_div(count_rates,live_time)
counts_rates_error = f_div(counts_rates_error,live_time)


live_time_bkg         = cmreplicate(pixel_data.LIVE_TIME_BKG, 4)
count_rates_bkg       = f_div(count_rates_bkg,live_time_bkg)
count_rates_error_bkg = f_div(count_rates_error_bkg,live_time_bkg)

;;************** Print total number of counts

; Select just sub-collimators from 3 to 10 for computing the total number of counts
subc_index = stix_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
                             '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

time_range = stx_time2any(pixel_data.TIME_RANGE)

tot_counts     = total(pixel_data.COUNTS[subc_index,*])
tot_counts_bkg = average(count_rates_bkg[subc_index,*]) * (time_range[1]-time_range[0])

if ~silent then begin
  
  print,'***********************************************************************'
  print,'Total number of counts in image:  '+strtrim(tot_counts)
  print,'Background counts:                '+strtrim(tot_counts_bkg)
  print,'Counts above background:          '+strtrim(tot_counts-tot_counts_bkg)
  print,'Total to background:              '+strtrim(tot_counts/tot_counts_bkg)
  print,'***********************************************************************'

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

;;************** Correction for grid internal shadowing

if keyword_set(xy_flare) then begin
  
  subc_transmission     = stx_subc_transmission(xy_flare)
  subc_transmission_bkg = stx_subc_transmission([0.,0.])
  for i=0,31 do begin
    count_rates[i,*]        = count_rates[i,*]/subc_transmission[i]*0.25
    counts_rates_error[i,*] = counts_rates_error[i,*]/subc_transmission[i]*0.25
    
    count_rates_bkg[i,*]       = count_rates_bkg[i,*]/subc_transmission_bkg[i]*0.25
    count_rates_error_bkg[i,*] = count_rates_error_bkg[i,*]/subc_transmission_bkg[i]*0.25
  endfor
  
endif

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
pixel_data_summed.TOT_COUNTS_BKG  = tot_counts_bkg
pixel_data_summed.RCR             = pixel_data.RCR                

if ~keyword_set(xy_flare) then begin
  pixel_data_summed.XY_FLARE = [!VALUES.F_NaN,!VALUES.F_NaN]
endif else begin
  pixel_data_summed.XY_FLARE = xy_flare
endelse
 
pixel_data_summed.SUMCASE        = sumcase
pixel_data_summed.DETECTOR_MASKS = pixel_data.DETECTOR_MASKS

return, pixel_data_summed

end