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
;     - TIME_RANGE: two-element 'stx_time' array containing the lower and upper edge of the selected time interval
;                   (the time bins containing the start and the end time provided as input are included in the 
;                   selected interval)
;     - ENERGY_RANGE: array containing the lower and the upper edge of the selected energy interval
;                     (the energy bins containing the lower and the upper edges provided as input are included in the interval)
;     - COUNTS_BKG: array 32x12 containing an estimate of the number of background counts recorded by the detector pixels in the selected 
;                   time and energy intervals. If no bakground measurement is provided, it is filled with zeros
;     - COUNTS_ERROR_BKG: array 32x12 containing the errors (statistics + compression) associated with the estimate of the 
;                         number of background counts recorded by the detector pixels in the selected time and energy intervals
;     - LIVE_TIME_BKG: 32-element array containing the live time of each detector for the background measurement
;     - XY_FLARE: two-element array containing the X and Y coordinates of the estimated flare location (STIX coordinate frame, arcsec).
;                   If 'xy_flare' is not passed, it is filled with NaN values
;     - RCR: rate control regime status in the selcted time interval. If the RCR changes in that interval, an error is thrown
;     - PIXEL_MASKS: matrix containing info on the pixels used in the selected time interval
;     - DETECTOR_MASKS: matrix containing information on the detectors used in the selected time interval
;
; KEYWORDS:
;
;   path_bkg_file: path of a background L1 fits file. If provided, the fields 'COUNTS_BKG', 'COUNTS_ERROR_BKG' and 'LIVE_TIME_BKG' 
;                  of the pixel_data structure are filled with the values read from the background measurement file
;
;   elut_corr: if set, a correction based on a ELUT table is applied to the measured counts
;   
;   xy_flare: two-element array containing the X and Y coordinates of the estimated flare location
;             (STIX coordinate frame, arcsec). If passed, the grid transmission correction is computed
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
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_construct_pixel_data, path_sci_file, time_range, energy_range, elut_corr=elut_corr, $
                                   path_bkg_file=path_bkg_file, xy_flare=xy_flare, subc_index=subc_index, $
                                   sumcase=sumcase, silent=silent, no_small=no_small, no_rcr_check=no_rcr_check, $
                                   shift_duration=shift_duration, _extra=extra

default, elut_corr, 1
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
  
energy_ind_min = where(energy_low le energy_range[0])
energy_ind_min = energy_ind_min[-1]
energy_ind_max = where(energy_high ge energy_range[1])
energy_ind_max = energy_ind_max[0]

energy_ind        = [energy_ind_min:energy_ind_max]
if n_elements(energy_ind) eq 1 then energy_ind = energy_ind[0]

this_energy_range = [energy_low[energy_ind_min], energy_high[energy_ind_max]]

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
    
  energy_ind_min_bkg = where(energy_low_bkg le energy_range[0])
  energy_ind_min_bkg = energy_ind_min_bkg[-1]
  energy_ind_max_bkg = where(energy_high_bkg ge energy_range[1])
  energy_ind_max_bkg = energy_ind_max_bkg[0]
  
  energy_ind_bkg        = [energy_ind_min_bkg:energy_ind_max_bkg]
  if n_elements(energy_ind_bkg) eq 1 then energy_ind_bkg = energy_ind_bkg[0]
  
  this_energy_range_bkg = [energy_low_bkg[energy_ind_min_bkg], energy_high_bkg[energy_ind_max_bkg]]

endif

;;************** Compute livetime

triggergram        = stx_triggergram(data.TRIGGERS, t_axis)
livetime_fraction  = stx_livetime_fraction(triggergram)
duration_time_bins = t_axis.DURATION
duration_time_bins = transpose(cmreplicate(duration_time_bins, 32))
live_time_bins     = livetime_fraction*duration_time_bins
live_time          = n_elements(time_ind) eq 1? reform(live_time_bins[*,time_ind]) : $
                     total(live_time_bins[*,time_ind],2)

if keyword_set(path_bkg_file) then begin
  
  triggergram_bkg        = stx_triggergram(data_bkg.TRIGGERS, t_axis_bkg)
  livetime_fraction_bkg  = stx_livetime_fraction(triggergram_bkg)
  duration_time_bins_bkg = t_axis_bkg.DURATION
  live_time_bkg          = duration_time_bins_bkg[0]*livetime_fraction_bkg
  
endif

;;************** Define count matrix and bkg count matrix

;; WE ASSUME THAT THE SCIENCE DATA FILE AND THE BKG DATA FILE CONTAIN MORE THAN 1 ENERGY BIN 
;; (I.E., THE NUMBER OF ELEMENTS IN energy_bin_idx AND IN energy_bin_idx_bkg IS ASSUMED TO BE
;; LARGER THAN 1)

;; Dimensions: [energy,pixel,detector,time]
counts       = data.COUNTS
counts_error = data.COUNTS_ERR

;; Consider only selected energy bins
counts       = counts[energy_bin_idx,*,*,*]
counts_error = counts_error[energy_bin_idx,*,*,*]

if keyword_set(path_bkg_file) then begin

  counts_bkg       = data_bkg.COUNTS
  counts_error_bkg = data_bkg.COUNTS_ERR
  counts_bkg       = counts_bkg[energy_bin_idx_bkg,*,*]
  counts_error_bkg = counts_error_bkg[energy_bin_idx_bkg,*,*]

endif

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

;;************** Sum counts (and related errors) in energy

;; Compute elut correction (if 'elut_corr' is set) - Correct just the first and the last energy bins (flat spectrum is assumed)
if elut_corr then begin
  
  elut_filename = stx_date2elut_file(stx_time2any(this_time_range[0]))  
  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename  
  
  ;; We assume that the first energy bin starts from 0. The right end of the last energy bin is set to NaN
  ;; We assume that the energy interval is always partitioned into 32 energy bins
  energy_bin_low           = fltarr(32,12,32)
  energy_bin_low[1:31,*,*] = ekev_actual
  
  energy_bin_high           = fltarr(32,12,32)
  energy_bin_high[0:30,*,*] = ekev_actual
  energy_bin_high[31,*,*]   = !VALUES.F_NaN
  
  energy_bin_low  = energy_bin_low[energy_bin_idx,*,*]
  energy_bin_high = energy_bin_high[energy_bin_idx,*,*]
  
  energy_bin_size = energy_bin_high - energy_bin_low
  
  if keyword_set(path_bkg_file) then begin
    
    ;; The bkg elut is potentially different from the one used for correcting the science data
    elut_filename_bkg = stx_date2elut_file(stx_time2any(t_axis_bkg.TIME_START))
    stx_read_elut, ekev_actual = ekev_actual_bkg, elut_filename = elut_filename_bkg

    ;; We assume that the first energy bin starts from 0. The right end of the last energy bin is set to NaN
    ;; We assume that the energy interval is always partitioned into 32 energy bins
    energy_bin_low_bkg           = fltarr(32,12,32)
    energy_bin_low_bkg[1:31,*,*] = ekev_actual_bkg
    
    energy_bin_high_bkg           = fltarr(32,12,32)
    energy_bin_high_bkg[0:30,*,*] = ekev_actual_bkg
    energy_bin_high_bkg[31,*,*]   = !VALUES.F_NaN
    
    energy_bin_low_bkg  = energy_bin_low_bkg[energy_bin_idx_bkg,*,*]
    energy_bin_high_bkg = energy_bin_high_bkg[energy_bin_idx_bkg,*,*]
    
    energy_bin_size_bkg = energy_bin_high_bkg - energy_bin_low_bkg
    
  endif

endif

if n_elements(energy_ind) eq 1 then begin
  
  energy_corr_factor = elut_corr ? (this_energy_range[1] - this_energy_range[0]) / reform(energy_bin_size[energy_ind,*,*]) : $
                       dblarr(12,32)+1

  counts       = reform(counts[energy_ind,*,*]) * energy_corr_factor
  counts_error = reform(counts_error[energy_ind,*,*]) * energy_corr_factor
  
  
endif else begin
  
  energy_corr_factor_low = elut_corr ? (reform(energy_bin_high[energy_ind[0],*,*]) - this_energy_range[0]) / $
                           reform(energy_bin_size[energy_ind[0],*,*]) : dblarr(12,32)+1
  
  energy_corr_factor_high = elut_corr ? (this_energy_range[1] - reform(energy_bin_low[energy_ind[-1],*,*])) / $
                           reform(energy_bin_size[energy_ind[-1],*,*]) : dblarr(12,32)+1
  
  counts[energy_ind[0],*,*]        *= energy_corr_factor_low
  counts[energy_ind[-1],*,*]       *= energy_corr_factor_high
  counts_error[energy_ind[0],*,*]  *= energy_corr_factor_low
  counts_error[energy_ind[-1],*,*] *= energy_corr_factor_high

  counts       = total(counts[energy_ind,*,*],1)
  counts_error = sqrt(total(counts_error[energy_ind,*,*]^2.,1))
  
endelse


if keyword_set(path_bkg_file) then begin
  
  if n_elements(energy_ind_bkg) eq 1 then begin

    ;; Background
    energy_corr_factor_bkg = elut_corr ? (this_energy_range[1] - this_energy_range[0]) / $
                              reform(energy_bin_size_bkg[energy_ind_bkg,*,*]) : dblarr(12,32)+1
    
    counts_bkg       = reform(counts_bkg[energy_ind_bkg,*,*]) * energy_corr_factor_bkg
    counts_error_bkg = reform(counts_error_bkg[energy_ind_bkg,*,*]) * energy_corr_factor_bkg
  
  endif else begin
  
    ;; Background
    energy_corr_factor_low_bkg = elut_corr ? (reform(energy_bin_high_bkg[energy_ind_bkg[0],*,*]) - this_energy_range[0]) / $
      reform(energy_bin_size_bkg[energy_ind_bkg[0],*,*]) : dblarr(12,32)+1
  
    energy_corr_factor_high_bkg = elut_corr ? (this_energy_range[1] - reform(energy_bin_low_bkg[energy_ind_bkg[-1],*,*])) / $
      reform(energy_bin_size_bkg[energy_ind_bkg[-1],*,*]) : dblarr(12,32)+1
  
    counts_bkg[energy_ind_bkg[0],*,*]        *= energy_corr_factor_low_bkg
    counts_bkg[energy_ind_bkg[-1],*,*]       *= energy_corr_factor_high_bkg
    counts_error_bkg[energy_ind_bkg[0],*,*]  *= energy_corr_factor_low_bkg
    counts_error_bkg[energy_ind_bkg[-1],*,*] *= energy_corr_factor_high_bkg
  
    counts_bkg       = total(counts_bkg[energy_ind_bkg,*,*],1)
    counts_error_bkg = sqrt(total(counts_error_bkg[energy_ind_bkg,*,*]^2.,1))
  
  endelse

endif

;;************** Correction for grid internal shadowing

if keyword_set(xy_flare) then begin

  subc_transmission     = stx_subc_transmission(xy_flare)
  subc_transmission_bkg = stx_subc_transmission([0.,0.])
  for i=0,31 do begin
    
    counts[*,i]       = counts[*,i]/subc_transmission[i]*0.25
    counts_error[*,i] = counts_error[*,i]/subc_transmission[i]*0.25

  endfor

endif

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
pixel_data.COUNTS           = transpose(counts)
pixel_data.COUNTS_ERROR     = transpose(counts_error)
if keyword_set(path_bkg_file) then begin
  
  pixel_data.LIVE_TIME_BKG    = live_time_bkg
  pixel_data.COUNTS_BKG       = transpose(counts_bkg)
  pixel_data.COUNTS_ERROR_BKG = transpose(counts_error_bkg)
  
endif

if ~keyword_set(xy_flare) then begin
  pixel_data.XY_FLARE = [!VALUES.F_NaN,!VALUES.F_NaN]
endif else begin
  pixel_data.XY_FLARE = xy_flare
endelse

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

