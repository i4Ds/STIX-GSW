;+
;
; NAME:
;
;   stx_plot_selected_time_range
;
; PURPOSE:
;
;   This procedure plots the lightcurve (counts s^-1 cm^-2 keV^-1) of the considered event and highlights 
;   the selected time interval. Use this procedure just for visualization purposes (refer to 'stx_science_data_lightcurve' 
;   for scientific publications)
;
; CALLING SEQUENCE:
;
;   stx_plot_selected_time_range, tim_axis, energy_ind, time_ind, counts, live_time_bins, subc_index, sumcase, energy_range, $
;                                 counts_bkg=counts_bkg, live_time_bkg=live_time_bkg, log_scale=log_scale
;
; INPUTS:
;
;   tim_axis: array containing the reference time of each recorded time bin (UT)
;
;   energy_ind: array containing the indices of the selected energy channels
;
;   time_ind: array containing the indices of the selected time bins
;   
;   counts: matrix 32x12x32xn_times contaning the raw counts measured by STIX pixels
;   
;   live_time_bins: matrix 32xn_times containing the livetime corresponding to each time bin
;   
;   subc_index: array containing the indices of the selected imaging detectors
;   
;   sumcase: string indicating which pixels are considered. Refer to the header of 'stx_sum_pixel_data' for more informations
;   
;   energy_range: bidimensional array containing the lower and upper edge of the selected energy interval
;   
;   time_range: bi-dimensional STIX time array containing the lower and upper edge of the selected time interval
; 
;
; KEYWORDS:
;
;   counts_bkg: matrix 32x12x32 containing the background counts measured by STIX pixels
;   
;   live_time_bkg: array 32xn_times the livetime corresponding to each time bin associated with the background measurement
;
;
; HISTORY: September 2022, Massa P., created
;          October 2023, Massa P., fixed bug in the selection of the energy bin indices
;
; CONTACT:
;   paolo.massa@wku.edu
;-

pro stx_plot_selected_time_range, tim_axis, energy_ind, time_ind, counts, live_time_bins, subc_index, sumcase, energy_range, $
                                  time_range, counts_bkg=counts_bkg, live_time_bkg=live_time_bkg, energy_ind_bkg=energy_ind_bkg


; re-initialise UTBASE to handle UTC times properly when calling utplot
common utcommon
utbase = 0

;;********** Create lightcurve

if n_elements(energy_ind) eq 1 then begin

  lightcurve = reform(counts[energy_ind,*,*,*])
  
endif else begin

  lightcurve = total(counts[energy_ind,*,*,*],1)

endelse

if keyword_set(counts_bkg) then begin

  if n_elements(energy_ind_bkg) eq 1 then begin
    
    bkg_level = reform(counts_bkg[energy_ind_bkg,*,*])
    
  endif else begin
    
    bkg_level = total(counts_bkg[energy_ind_bkg,*,*],1)
    
  endelse

endif

;;********** Sum counts of selected imaging detectors

;; Compute incident area
subc_str = stx_construct_subcollimator()
eff_area = subc_str.det.pixel.area

live_time_bins = cmreplicate(live_time_bins, 12)
live_time_bins = transpose(live_time_bins,[2,0,1])
if keyword_set(counts_bkg) then this_live_time_bkg = transpose(cmreplicate(live_time_bkg, 12))

if n_elements(subc_index) eq 1 then begin
  
  lightcurve      = reform(lightcurve[*,subc_index,*]/live_time_bins[*,subc_index,*])
  eff_area        = reform(eff_area[*,subc_index])

  if keyword_set(counts_bkg) then bkg_level = reform(bkg_level[*,subc_index]/this_live_time_bkg[*,subc_index])
  
  
endif else begin
  
  
  lightcurve      = total(lightcurve[*,subc_index,*]/live_time_bins[*,subc_index,*],2)
  eff_area        = total(eff_area[*,subc_index], 2)
  if keyword_set(counts_bkg) then bkg_level = total(bkg_level[*,subc_index]/this_live_time_bkg  [*,subc_index],2)
  
endelse


;;********** Sum pixels
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

dim_lightcurve = size(lightcurve,/dim)
lightcurve = reform(lightcurve, 4, 3, dim_lightcurve[1])
eff_area   = reform(eff_area, 4, 3)
if keyword_set(counts_bkg) then bkg_level = reform(bkg_level, 4, 3)

if n_elements(pixel_ind) eq 1 then begin
  
  lightcurve = reform(lightcurve[*,pixel_ind,*])
  eff_area   = reform(eff_area[*,pixel_ind])
  if keyword_set(counts_bkg) then bkg_level = reform(bkg_level[*,pixel_ind])
  
endif else begin
  
  lightcurve = total(lightcurve[*,pixel_ind,*],2)
  eff_area   = total(eff_area[*,pixel_ind],2)
  if keyword_set(counts_bkg) then bkg_level = total(bkg_level[*,pixel_ind],2)
  
endelse

;; lightcurve has now dim 4 x n_times. We sum along the first dimension
lightcurve = total(lightcurve,1)
eff_area   = total(eff_area)
if keyword_set(counts_bkg) then bkg_level = total(bkg_level)

;;********** Normalize by cm^2 and keV
lightcurve = lightcurve/eff_area/(energy_range[1]-energy_range[0])
if keyword_set(counts_bkg) then bkg_level = bkg_level/eff_area/(energy_range[1]-energy_range[0])


;;********** Plot

this_time_range = anytim(stx_time2any(time_range), /vms)
this_date       = strmid(this_time_range[0],0,11)
this_start_time = strmid(this_time_range[0],12,8)
this_end_time   = strmid(this_time_range[1],12,8)

loadct,5, /silent
device, Window_State=win_state
if not win_state[2] then window,2,xsize=520,ysize=400
wset,2

chsize=1.2
chsize_leg=1.8
clearplot
utplot,tim_axis,lightcurve, psym=10, /xs, ytitle='STIX count rate [s!U-1!N cm!U-2!N keV!U-1!N]', charsize=chsize,$
       title = this_date + ' ' + this_start_time + '-' + this_end_time + ' UT, ' + $
       trim(energy_range[0],'(f12.1)') + '-' + trim(energy_range[1],'(f12.1)') + ' keV'
outplot,tim_axis[time_ind],lightcurve[time_ind],psym=10,color=122
if keyword_set(counts_bkg) then begin
  outplot,tim_axis,tim_axis*0.+bkg_level,color=166
  ssw_legend, ['Selected time', 'Background level'], TEXTCOLORS=[122,166], /right, box=0, charsize=chsize_leg
endif else begin
  ssw_legend, ['Selected time'], TEXTCOLORS=[122], /right, box=0, charsize=chsize_leg
endelse


end