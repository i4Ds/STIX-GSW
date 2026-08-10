;+
;
; NAME:
; 
;   stx_construct_pixel_data
;
; PURPOSE:
; 
;   Read a STIX science L1 fits file (and optionally a STIX background L1 fits file) and fill in a 'pixel_data' structure
;
; CALLING SEQUENCE:
; 
;   pixel_data = stx_construct_pixel_data(path_sci_file, time_range, energy_range)
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
;   'stx_pixel_data' structure containing:
;   
;     - COUNTS: array 32x12 containing the number of counts recorded by the detector pixels 
;               in the selected time and energy intervals
;     - COUNTS_ERROR: array 32x12 containing the errors (statistics + compression) associated with the number of counts 
;                     recorded by the detector pixels
;     - LIVE_TIME: 32-element array containing the live time of each detector in the considered time interval
;     - LIVE_TIME_ERROR: 32-element array containing the uncertainty on the live time of each detector in the considered time interval
;     - TIME_RANGE: two-element 'stx_time' array containing the lower and upper edge of the selected time interval
;                   (the time bins containing the start and the end time provided as input are included in the 
;                   selected interval)
;     - ENERGY_RANGE: array containing the lower and the upper edge of the selected energy interval
;                     (the energy bins containing the lower and the upper edges provided as input are included in the interval)
;     - RCR: rate control regime status in the selcted time interval. If the RCR changes in that interval, an error is thrown
;     - PIXEL_MASKS: matrix containing info on the pixels used in the selected time interval
;     - DETECTOR_MASKS: matrix containing information on the detectors used in the selected time interval
;     - TOT_COUNTS: total number of counts recorded by the imaging subcollimators selected by means of 'subc_index'
;     - TOT_COUNTS_BKG: estimate of the total number of background counts recorded by the imaging subcollimators (selected with 'subc_index')
;                     in the considered time and energy interval
;
; KEYWORDS:
;
;   path_bkg_file: path of a background L1 fits file. If provided, the fields 'COUNTS_BKG', 'COUNTS_ERROR_BKG' and 'LIVE_TIME_BKG' 
;                  of the pixel_data structure are filled with the values read from the background measurement file
;
;   calib_data: if a 'stx_calibration_data' structure is passed as input, then the ELUT correction is applied  
;   
;   subc_index: array containing the indices of the selected imaging detectors. Used only for plotting the lightcurve by means of 
;             'stx_plot_selected_time_range'. Default, indices of
;             the detectors from 10 to 3
;   
;   sumcase: string indicating which pixels are considered. Used only for plotting the lightcurve by means of
;            'stx_plot_selected_time_range'. Refer to the header of 'stx_sum_pixel_data' for more details.
;             Default, 'TOP+BOT'
;    
;   silent: if set, plots are not displayed
;   
;   no_small: if set, Moire patterns measured by small pixels are not plotted with 'stx_plot_moire_pattern'
;   
;   no_rcr_check: if set, control on RCR change during the selected time interval is not performed. Default, 0
;   
;   shift_duration: if set, shift all time bins by 1 to account for FSW time input discrepancy prior to 09-Dec-2021.
;                   N.B. WILL ONLY WORK WITH FULL TIME RESOLUTION DATA WHICH IS OFTEN NOT THE CASE FOR PIXEL DATA.
;             
; HISTORY: July 2022, Massa P., created
;          September 2022, Massa P., added 'shift_duration' keyword
;          May 2023, Massa P., do not call 'stx_plot_selected_time_range' if the science fits file contains a single time bin
;          October 2023, Massa P., fixed bug in the selection of the energy bin indices
;          November 2023, Massa P., use simplified version of the subcollimator transmission (temporary solution)
;          January 2026, Massa P., removed 'xy_flare' keyword and grid transmission correction
;          March 2026, Massa P., made it compatible with new ELUT correction based on daily calibration data
;
; CONTACT:
;   paolo.massa@fhnw.ch
;-

function stx_construct_pixel_data, path_sci_file, time_range, energy_range, calib_data=calib_data, $
                                   path_bkg_file=path_bkg_file, subc_index=subc_index, $
                                   sumcase=sumcase, silent=silent, no_small=no_small, no_rcr_check=no_rcr_check, $
                                   shift_duration=shift_duration, _extra=extra

default, silent, 0
default, subc_index, stx_label2ind(['10a','10b','10c','9a','9b','9c','8a','8b','8c','7a','7b','7c',$
                                   '6a','6b','6c','5a','5b','5c','4a','4b','4c','3a','3b','3c'])

default, sumcase, "TOP+BOT"
default, no_rcr_check, 0

if anytim(time_range[0]) gt anytim(time_range[1]) then message, "Start time is greater than end time"
if energy_range[0] gt energy_range[1] then message, "Energy range lower edge is greater than the higher edge"


stx_read_pixel_data_fits_file, path_sci_file, data_str = data, t_axis = t_axis, e_axis = e_axis, alpha = alpha, shift_duration=shift_duration, _extra=extra

if keyword_set(path_bkg_file) then begin

  stx_read_pixel_data_fits_file, path_bkg_file, data_str = data_bkg, t_axis = t_axis_bkg, e_axis = e_axis_bkg, _extra=extra
  
  if n_elements(t_axis_bkg.DURATION) gt 1 then message, 'The chosen file does not contain a background measurement'

endif
                                                                  

;;************** Select time indices

time_start = stx_time2any(t_axis.TIME_START)
time_end   = stx_time2any(t_axis.TIME_END)
if (anytim(time_range[0]) lt min(time_start)) then $
  message, 'The selected start time is outside the time interval of the data file (' + $
           anytim(min(time_start), /vms) + ' - ' + anytim(max(time_end), /vms) + ')'

if (anytim(time_range[1]) gt max(time_end)) then $
  message, 'The selected end time is outside the time interval of the data file (' + $
           anytim(min(time_start), /vms) + ' - ' + anytim(max(time_end), /vms) + ')'
  
time_ind_min = where(time_start le anytim(time_range[0]))
time_ind_min = time_ind_min[-1]
time_ind_max = where(time_end ge anytim(time_range[1]))
time_ind_max = time_ind_max[0]

time_ind        = [time_ind_min:time_ind_max]
this_time_range = [t_axis.TIME_START[time_ind_min], t_axis.TIME_END[time_ind_max]]

;;************** Select energy indices

;; Select indices of the energy bins (among the 32) that are actually present in the pixel data science file
energy_bin_mask = data.energy_bin_mask
energy_bin_idx  = where(energy_bin_mask eq 1)

energy_low  = e_axis.LOW
energy_high = e_axis.HIGH

if (energy_range[0] lt min(energy_low)) then $
  message, 'The lower edge of the selected energy interval is outside the science energy interval (' + $
  num2str(fix(min(energy_low))) + ' - ' + num2str(fix(max(energy_high))) + ' keV)'

if (energy_range[1] gt max(energy_high)) then $
  message, 'The upper edge of the selected energy interval is outside the science energy interval (' + $
  num2str(fix(min(energy_low))) + ' - ' + num2str(fix(max(energy_high))) + ' keV)'

energy_min = min(energy_low)
energy_max = max(energy_high)

if keyword_set(path_bkg_file) then begin

  ;; Select indices of the energy bins (among the 32) that are actually present in the pixel data bkg file
  energy_bin_mask_bkg = data_bkg.energy_bin_mask
  energy_bin_idx_bkg = where(energy_bin_mask_bkg eq 1)

  energy_low_bkg  = e_axis_bkg.LOW
  energy_high_bkg = e_axis_bkg.HIGH

  if (energy_range[0] lt min(energy_low_bkg)) then $
    message, 'The lower edge of the selected energy interval is outside the background energy interval (' + $
    num2str(fix(min(energy_low_bkg))) + ' - ' + num2str(fix(max(energy_high_bkg))) + ' keV)'

  if (energy_range[1] gt max(energy_high_bkg)) then $
    message, 'The upper edge of the selected energy interval is outside the background energy interval (' + $
    num2str(fix(min(energy_low_bkg))) + ' - ' + num2str(fix(max(energy_high_bkg))) + ' keV)'

  ;; Extract energy range in common between science and background file
  energy_min = max([energy_min,min(energy_low_bkg)])
  energy_max = min([energy_max,max(energy_high_bkg)])
  idx_energy_bkg = where((energy_low_bkg ge energy_min) and (energy_high_bkg le energy_max))

  energy_bin_idx_bkg = energy_bin_idx_bkg[idx_energy_bkg]
  energy_low_bkg = energy_low_bkg[idx_energy_bkg]
  energy_high_bkg = energy_high_bkg[idx_energy_bkg]

  energy_ind_min_bkg = where(energy_low_bkg le energy_range[0])
  energy_ind_min_bkg = energy_ind_min_bkg[-1]
  energy_ind_max_bkg = where(energy_high_bkg ge energy_range[1])
  energy_ind_max_bkg = energy_ind_max_bkg[0]

  energy_ind_bkg        = [energy_ind_min_bkg:energy_ind_max_bkg]
  if n_elements(energy_ind_bkg) eq 1 then energy_ind_bkg = energy_ind_bkg[0]

  this_energy_range_bkg = [energy_low_bkg[energy_ind_min_bkg], energy_high_bkg[energy_ind_max_bkg]]

endif

;; Extract energy range in common between science and background file 
;; (in the case a background measurement file is passed as input)
idx_energy = where((energy_low ge energy_min) and (energy_high le energy_max))

energy_bin_idx = energy_bin_idx[idx_energy]
energy_low = energy_low[idx_energy]
energy_high = energy_high[idx_energy]

energy_ind_min = where(energy_low le energy_range[0])
energy_ind_min = energy_ind_min[-1]
energy_ind_max = where(energy_high ge energy_range[1])
energy_ind_max = energy_ind_max[0]

energy_ind        = [energy_ind_min:energy_ind_max]
if n_elements(energy_ind) eq 1 then energy_ind = energy_ind[0]

this_energy_range = [energy_low[energy_ind_min], energy_high[energy_ind_max]]

;;************** Compute livetime

live_time_data = stx_cpd_livetime(data.TRIGGERS, data.TRIGGERS_ERR, t_axis)
live_time_bins = live_time_data.LIVE_TIME_BINS
live_time_bins_err = live_time_data.LIVE_TIME_BINS_ERR

live_time = n_elements(time_ind) eq 1? reform(live_time_bins[*,time_ind]) : total(live_time_bins[*,time_ind],2)
live_time_error = n_elements(time_ind) eq 1? reform(live_time_bins_err[*,time_ind]) : $
  sqrt(total(live_time_bins_err[*,time_ind]^2.,2))

if keyword_set(path_bkg_file) then begin

  live_time_bkg_data = stx_cpd_livetime(data_bkg.TRIGGERS, data_bkg.TRIGGERS_ERR, t_axis_bkg)
  live_time_bkg = live_time_bkg_data.LIVE_TIME_BINS
  live_time_error_bkg = live_time_bkg_data.LIVE_TIME_BINS_ERR

endif else begin

  live_time_bkg = dblarr(32) + 1.
  live_time_error_bkg = dblarr(32)

endelse


;;************** Define count matrix and bkg count matrix

;; WE ASSUME THAT THE SCIENCE DATA FILE AND THE BKG DATA FILE CONTAIN MORE THAN 1 ENERGY BIN
;; (I.E., THE NUMBER OF ELEMENTS IN energy_bin_idx AND IN energy_bin_idx_bkg IS ASSUMED TO BE
;; LARGER THAN 1)

if (n_elements(energy_bin_idx) eq 1) then $
  message, 'It is not possible to analyze this science file as it contains a single energy bin. Please, contact the STIX team for further details.'
if keyword_set(path_bkg_file) and (n_elements(energy_bin_idx_bkg) eq 1) then $
  message, 'It is not possible to utilize this bkg file since it contains a single energy bin. Please, either utilize a different bkg file or contact the STIX team.'

;; Dimensions: [energy,pixel,detector,time]
counts       = data.COUNTS
counts_error = data.COUNTS_ERR

;; Consider only selected energy bins
counts       = counts[energy_bin_idx,*,*,*]
counts_error = counts_error[energy_bin_idx,*,*,*]

if keyword_set(path_bkg_file) then begin

  ;; Check if science and background files are reconrded with the same ELUT

  elut_filename = stx_date2elut_file(stx_time2any(this_time_range[0]))
  elut_filename_bkg = stx_date2elut_file(stx_time2any(t_axis_bkg.TIME_START))

  ;; Compare ELUT tables
  elut_comp = STRCMP(elut_filename, elut_filename_bkg)

  if not elut_comp then $
    message, 'The background file must be recorded when the same ELUT as the science file was uploaded. Please choose a different background file that is closer in time to the science file.'

  counts_bkg       = data_bkg.COUNTS
  counts_error_bkg = data_bkg.COUNTS_ERR
  counts_bkg       = counts_bkg[energy_bin_idx_bkg,*,*]
  counts_error_bkg = counts_error_bkg[energy_bin_idx_bkg,*,*]

endif else begin

  counts_bkg       = dblarr(size(counts, /dim))
  counts_error_bkg = dblarr(size(counts, /dim))

endelse

;;************** Plot lightcurve (if ~silent)

if ~silent and (n_elements(size(live_time_bins, /dim)) gt 1) then begin

  if keyword_set(path_bkg_file) then begin
    stx_plot_selected_time_range, stx_time2any(t_axis.MEAN), energy_ind, time_ind, counts, live_time_bins, subc_index, $
      sumcase, this_energy_range, this_time_range, counts_bkg=counts_bkg, $
      live_time_bkg=live_time_bkg, energy_ind_bkg=energy_ind_bkg
  endif else begin
    stx_plot_selected_time_range, stx_time2any(t_axis.MEAN), energy_ind, time_ind, counts, live_time_bins, subc_index, $
      sumcase, this_energy_range, this_time_range
  endelse

endif

;;************** Sum counts (and related errors) in time

if n_elements(time_ind) eq 1 then begin

  counts       = reform(counts[*,*,*,time_ind])
  counts_error = reform(counts_error[*,*,*,time_ind])

endif else begin
  
  counts       = total(counts[*,*,*,time_ind],4)
  counts_error = sqrt(total(counts_error[*,*,*,time_ind]^2.,4))
  
endelse

;;************** Background subtraction

live_time_rep = transpose(cmreplicate(live_time, [n_elements(energy_bin_idx),12]), [1,2,0])
live_time_error_rep = transpose(cmreplicate(live_time_error, [n_elements(energy_bin_idx),12]), [1,2,0])
live_time_bkg_rep = keyword_set(path_bkg_file)? transpose(cmreplicate(live_time_bkg, [n_elements(energy_bin_idx_bkg),12]), [1,2,0]) : fltarr(size(counts_bkg, /dim)) + 1.
live_time_error_bkg_rep = keyword_set(path_bkg_file)? transpose(cmreplicate(live_time_error_bkg, [n_elements(energy_bin_idx_bkg),12]), [1,2,0]) : fltarr(size(counts_bkg, /dim))

counts_bkg_estimate = f_div( live_time_rep * counts_bkg, live_time_bkg_rep )
error_numerator = abs(live_time_rep * counts_bkg) * sqrt( f_div(live_time_error_rep,live_time_rep)^2. + $
  f_div(counts_error_bkg,counts_bkg)^2.)
counts_bkg_estimate_error = abs(counts_bkg_estimate) * sqrt( f_div(error_numerator,live_time_rep * counts_bkg)^2. + $
  f_div(live_time_error_bkg_rep,live_time_bkg_rep)^2.)

if keyword_set(calib_data) and ~silent then begin

  ;; To be used for plot of the bkg subtracted spectrum
  spectrum_with_bkg = total(total(counts[*,0:7,subc_index], 3), 2) / (energy_high - energy_low)
  spectrum_bkg = keyword_set(path_bkg_file)? total(total(counts_bkg_estimate[*,0:7,subc_index], 3), 2) / (energy_high_bkg - energy_low_bkg) : total(total(counts_bkg[*,0:7,subc_index], 3), 2)

endif

;; Determine indices of the selected pixels. It will be used for estimating total number of BKG counts and for estimating the amount of ELUT correction
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

;; Compute total number of counts (to be used for comparison with bkg counts)
counts_reshaped = reform(counts,n_elements(energy_bin_idx), 4, 3, 32)
tot_counts = total(counts_reshaped[energy_ind,*,pixel_ind,subc_index])

;; Apply BKG subtraction
counts = counts - counts_bkg_estimate
counts_error = sqrt(counts_error^2. +  counts_bkg_estimate_error^2.)

if keyword_set(path_bkg_file) then begin

  ;; Compute total number of background counts. Select only imaging detectors
  counts_bkg = reform(counts_bkg_estimate, n_elements(energy_bin_idx_bkg), 4, 3, 32)
  tot_counts_bkg = total(counts_bkg[energy_ind_bkg,*,pixel_ind,subc_index])

endif else begin

  tot_counts_bkg = 0.

endelse

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

;;************** Sum counts (and related errors) in energy

;; Compute elut correction (if 'calib_data' is provided) - Correct just the first and the last energy bins
if keyword_set(calib_data) then begin
  
  energy_bin_low = calib_data.ENERGY_BIN_LOW
  energy_bin_high = calib_data.ENERGY_BIN_HIGH
  
  energy_bin_low  = energy_bin_low[energy_bin_idx,*,*]
  energy_bin_high = energy_bin_high[energy_bin_idx,*,*]
  
  ;; Apply ELUT correction
  spectrum = total(total(counts[*,0:7,subc_index], 3), 2) / (energy_high - energy_low)
  elut_data = stx_elut_correction(counts, counts_error, $
                            energy_bin_idx, energy_bin_low, energy_bin_high, energy_high, energy_low, energy_ind, this_energy_range, $
                            spectrum, pixel_ind, subc_index, $
                            spectrum_with_bkg=spectrum_with_bkg, spectrum_bkg=spectrum_bkg,silent=silent)
  
  counts = elut_data.COUNTS
  counts_error = elut_data.COUNTS_ERROR
  counts_no_elut = elut_data.COUNTS_NO_ELUT
  counts_elut = elut_data.COUNTS_ELUT

  if ~silent then begin

    ;; Print minimun and maximum ELUT correction in the different pixels
    elut_corr_perc = f_div(abs(counts_no_elut -  counts_elut),counts_no_elut) * 100 ;; in percentage
    counts_error_reshaped = reform(counts_error, 4, 3, 32)
    counts_error_elut=reform(counts_error_reshaped[*,pixel_ind,subc_index])
    rel_error=abs(counts_error_elut/counts_elut)*100.
    print
    print
    print,'***********************************************************************'
    print,'Min/Max ELUT correction over all pixels:               '+num2str(min(elut_corr_perc), format='(f7.2)')+'% - '+num2str(max(elut_corr_perc), format='(f7.2)')+'% '
    print,'Average ELUT correction over all pixels:               '+num2str(average(elut_corr_perc), format='(f7.2)')+'%'
    print,'Standard deviation of ELUT correction over all pixels: '+num2str(stdev(elut_corr_perc), format='(f7.2)')+'%'
    print,'Average count error over all pixels:                   '+num2str(average(rel_error), format='(f7.2)')+'%'
    print,'***********************************************************************'
    print
    print

  endif
endif else begin
  
  if n_elements(energy_ind) eq 1 then begin
    
    counts       = reform(counts[energy_ind,*,*])
    counts_error = reform(counts_error[energy_ind,*,*])
    
  endif else begin
    
    counts       = total(counts[energy_ind,*,*],1)
    counts_error = sqrt(total(counts_error[energy_ind,*,*]^2.,1))
  
 endelse
endelse

;;**************  RCR

rcr = data.rcr[time_ind]
find_changes, rcr, index, state, count=count
if (count gt 1) and (~no_rcr_check) then message, "RCR status changed in the selected time interval"

;;************** Pixel masks and detector masks

if alpha then begin
  
  pixel_masks    = data.PIXEL_MASKS[*,*,time_ind]
  
endif else begin
  
  pixel_masks    = data.PIXEL_MASKS[*,time_ind]
  
endelse
detector_masks = data.DETECTOR_MASKS[*,time_ind]

diff_pixel_masks    = fltarr(n_elements(time_ind))
diff_detector_masks = fltarr(n_elements(time_ind))

for i=0,n_elements(time_ind)-2 do begin
  
  if alpha then begin

    diff_pixel_masks[i] = total(pixel_masks[*,*,i]-pixel_masks[*,*,i+1])

  endif else begin

    diff_pixel_masks[i] = total(pixel_masks[*,i]-pixel_masks[*,i+1])

  endelse
  
endfor

if total(diff_pixel_masks) gt 0. then message, "Pixel masks changed in the selected time interval"
if total(diff_detector_masks) gt 0. then message, "Detector masks changed in the selected time interval"

;;************** Fill in pixel data structure

pixel_data = stx_pixel_data()

pixel_data.TIME_RANGE       = this_time_range
pixel_data.ENERGY_RANGE     = this_energy_range
pixel_data.LIVE_TIME        = live_time
pixel_data.LIVE_TIME_ERROR  = live_time_error
pixel_data.COUNTS           = transpose(counts)
pixel_data.COUNTS_ERROR     = transpose(counts_error)
pixel_data.TOT_COUNTS       = tot_counts
if keyword_set(path_bkg_file) then pixel_data.TOT_COUNTS_BKG   = tot_counts_bkg

pixel_data.RCR            = rcr[0]

if alpha then begin
  pixels_used = where( total((data.pixel_masks)[*,*,0],1) eq 1, npix)
  pixel_data.PIXEL_MASKS[pixels_used] = 1b
endif else begin
  pixel_data.PIXEL_MASKS    = pixel_masks[*,0]
endelse

pixel_data.DETECTOR_MASKS = detector_masks[*,0]

if ~silent then stx_plot_moire_pattern, pixel_data, no_small=no_small

return, pixel_data
  
end

