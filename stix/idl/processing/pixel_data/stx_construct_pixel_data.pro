;+
;
; NAME:
; 
;   stx_construct_pixel_data
;
; PURPOSE:
; 
;   Read a STIX science L1 fits file (and potentially a STIX background L1 fits file) and fill in a 'pixel_data' structure
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
;   energy_range: array containing the values of the lower and upper edge of the energy interval to consider
;
; OUTPUTS:
; 
;   'stx_pixel_data' structure containing:
;   
;     - COUNTS: array 32x12 containing the number of counts recorded by the detector pixels 
;               in the selected time and energy intervals
;     - COUNTS_ERROR: array 32x12 containing the errors (statistics + compression) associated with the number of counts 
;                     recorded by the detector pixels
;     - LIVE_TIME: 32-dimensional array containing the live time of each detector in the considered time interval
;     - TIME_RANGE: STX_TIME array containg the start and the end of the selected time interval
;                   (the time bins containing the provided start and the end time are included in the interval)
;     - ENERGY_RANGE: array containing the lower and the upper edge of the selected energy interval
;                     (the energy bins containing the lower and the upper edges provided as input are included in the interval)
;     - COUNTS_BKG: array 32x12 containing the number of background counts recorded by the detector pixels
;     - COUNTS_ERROR_BKG: array 32x12 containing the errors (statistics + compression) associated with the number of background counts 
;                         recorded by the detector pixels in the selected and energy interval
;     - LIVE_TIME_BKG: 32-dimensional array containing the live time of each detector for the background measurement
;     - RCR: rate control regime status for the selcted time interval
;     - PIXEL_MASKS: matrix containing info on the pixels used in the selected time interval
;     - DETECTOR_MASKS: matrix containing information on the detectors used in the selected time interval
;
; KEYWORDS:
;
;   path_bkg_file: if provided, the fields 'COUNTS_BKG', 'COUNTS_ERROR_BKG' and 'LIVE_TIME_BKG' of the pixel_data
;                  structure are filled with the values read from the background measurement file
;
;
; HISTORY: July 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

function stx_construct_pixel_data, path_sci_file, time_range, energy_range, elut_corr=elut_corr, $
                                   path_bkg_file=path_bkg_file, _extra=extra

default, elut_corr, 1

if anytim(time_range[0]) gt anytim(time_range[1]) then message, "Start time is greater than end time"
if energy_range[0] gt energy_range[1] then message, "Energy range lower edge is greater than the higher edge"


stx_read_pixel_data_fits_file, path_sci_file, data_str = data, t_axis = t_axis, e_axis = e_axis, _extra=extra

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

;Question: COULD IT BE THAT THERE ARE GAPS BETWEEN THE LOWER AND THE HIGHER ENERGY EDGE?
; IN THAT CASE I WOULD HAVE TO ADD A CONTROL

energy_low  = e_axis.LOW
energy_high = e_axis.HIGH

if (energy_range[0] lt min(energy_low)) then $
  message, 'The lower edge of the selected energy interval is outside the science energy interval of this file (' + $
  num2str(fix(min(energy_low))) + ' - ' + num2str(fix(max(energy_high))) + ' keV)'

if (energy_range[1] gt max(energy_high)) then $
  message, 'The upper edge of the selected energy interval is outside the science energy interval of this file (' + $
  num2str(fix(min(energy_low))) + ' - ' + num2str(fix(max(energy_high))) + ' keV)'
  
energy_ind_min = where(energy_low le energy_range[0])
energy_ind_min = energy_ind_min[-1]
energy_ind_max = where(energy_high ge energy_range[1])
energy_ind_max = energy_ind_max[0]

energy_ind        = [energy_ind_min:energy_ind_max]
if n_elements(energy_ind) eq 1 then energy_ind = energy_ind[0]

this_energy_range = [energy_low[energy_ind_min], energy_high[energy_ind_max]]

;;************** Compute livetime

triggergram        = stx_triggergram(data.TRIGGERS, t_axis)
livetime_fraction  = stx_livetime_fraction(triggergram)
livetime_fraction  = livetime_fraction[*, time_ind]
duration_time_bins = t_axis.DURATION[time_ind]
duration_time_bins = transpose(cmreplicate(duration_time_bins, 32))
live_time          = n_elements(time_ind) eq 1? reform(duration_time_bins*livetime_fraction) : $
                     total(duration_time_bins*livetime_fraction,2)

if keyword_set(path_bkg_file) then begin
  
  triggergram_bkg        = stx_triggergram(data_bkg.TRIGGERS, t_axis_bkg)
  livetime_fraction_bkg  = stx_livetime_fraction(triggergram_bkg)
  duration_time_bins_bkg = t_axis_bkg.DURATION
  live_time_bkg          = duration_time_bins_bkg[0]*livetime_fraction_bkg
  
endif

;;************** Sum counts (and related errors) in time

;; Dimensions: [energy,pixel,detector,time]
counts       = data.COUNTS
counts_error = data.COUNTS_ERR

if n_elements(time_ind) eq 1 then begin

  counts       = reform(counts[*,*,*,time_ind])
  counts_error = reform(counts_error[*,*,*,time_ind])

endif else begin
  
  counts       = total(counts[*,*,*,time_ind],4)
  counts_error = sqrt(total(counts_error[*,*,*,time_ind]^2.,4))
  
endelse

;;************** Sum counts (and related errors) in energy

;; Exclude first and last energy bins (below 4 keV and over 150 keV)
counts       = counts[1:30,*,*]
counts_error = counts_error[1:30,*,*]

if keyword_set(path_bkg_file) then begin

  counts_bkg       = data_bkg.COUNTS
  counts_error_bkg = data_bkg.COUNTS_ERR
  counts_bkg       = counts_bkg[1:30,*,*]
  counts_error_bkg = counts_error_bkg[1:30,*,*]

endif

;; Compute elut correction (if 'elut_corr' is set) - Correct just the first and the last energy bins (flat spectrum is assumed)
if keyword_set(elut_corr) then begin
  
  elut_filename = stx_date2elut_file(stx_time2any(this_time_range[0]))  
  stx_read_elut, ekev_actual = ekev_actual, elut_filename = elut_filename  
  
  energy_bin_low  = reform(ekev_actual[0:29,*,*])
  energy_bin_high = reform(ekev_actual[1:30,*,*])
  energy_bin_size = energy_bin_high - energy_bin_low
  
  if keyword_set(path_bkg_file) then begin
    
    ;; The bkg elut is potentially different from the one used for correcting the science data
    elut_filename_bkg = stx_date2elut_file(stx_time2any(t_axis_bkg.TIME_START))
    stx_read_elut, ekev_actual = ekev_actual_bkg, elut_filename = elut_filename_bkg

    energy_bin_low_bkg  = reform(ekev_actual_bkg[0:29,*,*])
    energy_bin_high_bkg = reform(ekev_actual_bkg[1:30,*,*])
    energy_bin_size_bkg = energy_bin_high_bkg - energy_bin_low_bkg
    
  endif

endif

if n_elements(energy_ind) eq 1 then begin
  
  energy_corr_factor = elut_corr ? (this_energy_range[1] - this_energy_range[0]) / reform(energy_bin_size[energy_ind,*,*]) : $
                       dblarr(12,32)+1

  counts       = reform(counts[energy_ind,*,*]) * energy_corr_factor
  counts_error = reform(counts_error[energy_ind,*,*]) * energy_corr_factor
  
  if keyword_set(path_bkg_file) then begin
    
    ;; Background
    energy_corr_factor_bkg = elut_corr ? (this_energy_range[1] - this_energy_range[0]) / reform(energy_bin_size_bkg[energy_ind,*,*]) : $
      dblarr(12,32)+1

    counts_bkg       = reform(counts_bkg[energy_ind,*,*]) * energy_corr_factor_bkg
    counts_error_bkg = reform(counts_error_bkg[energy_ind,*,*]) * energy_corr_factor_bkg
    
  endif
  
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
  
  if keyword_set(path_bkg_file) then begin
    
    ;; Background
    energy_corr_factor_low_bkg = elut_corr ? (reform(energy_bin_high_bkg[energy_ind[0],*,*]) - this_energy_range[0]) / $
      reform(energy_bin_size_bkg[energy_ind[0],*,*]) : dblarr(12,32)+1

    energy_corr_factor_high_bkg = elut_corr ? (this_energy_range[1] - reform(energy_bin_low_bkg[energy_ind[-1],*,*])) / $
      reform(energy_bin_size_bkg[energy_ind[-1],*,*]) : dblarr(12,32)+1

    counts_bkg[energy_ind[0],*,*]        *= energy_corr_factor_low_bkg
    counts_bkg[energy_ind[-1],*,*]       *= energy_corr_factor_high_bkg
    counts_error_bkg[energy_ind[0],*,*]  *= energy_corr_factor_low_bkg
    counts_error_bkg[energy_ind[-1],*,*] *= energy_corr_factor_high_bkg

    counts_bkg       = total(counts_bkg[energy_ind,*,*],1)
    counts_error_bkg = sqrt(total(counts_error_bkg[energy_ind,*,*]^2.,1))
    
  endif

endelse

;;**************  RCR

rcr = data.rcr[time_ind]
find_changes, rcr, index, state, count=count
if count gt 1 then message, "RCR status changed in the selected time interval"

;;************** Pixel masks and detector masks

pixel_masks    = data.PIXEL_MASKS[*,*,time_ind]
detector_masks = data.DETECTOR_MASKS[*,time_ind]

diff_pixel_masks    = fltarr(n_elements(time_ind))
diff_detector_masks = fltarr(n_elements(time_ind))

for i=0,n_elements(time_ind)-2 do begin
  
  diff_pixel_masks[i]    = total(pixel_masks[*,*,i]-pixel_masks[*,*,i+1])
  diff_detector_masks[i] = total(detector_masks[*,i]-detector_masks[*,i+1])
  
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
pixel_data.RCR            = rcr[0]
pixel_data.PIXEL_MASKS    = pixel_masks[*,*,0]
pixel_data.DETECTOR_MASKS = detector_masks[*,0]

return, pixel_data  
  
end

