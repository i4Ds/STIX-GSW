;+
;
; NAME:
;
;   stx_plot_fit_map
;
; PURPOSE:
;
;   Plots the visibility amplitude and phase fit plots corresponding to a STIX map created 
;   with 'stx_make_map.pro'
;
; CALLING SEQUENCE:
;
;   stx_plot_fit_map, in_map
;
; INPUTS:
;
;   in_map: reconstructed map created with 'stx_make_map.pro'
;
; KEYWORDS:
;
;   this_window: graphic window number used for plotting. Default, 0
;   
;   pred_vis: out, complex array of visibilities predicted from the reconstructed map. They correspond to the 
;             sub-collimators used for reconstructing the image
;             
;   pred_amp: out, float array of visibility amplitudes predicted from the reconstructed map. 
;                 They correspond to the sub-collimators used for reconstructing the image
;
;   pred_phase: out, float array of visibility phases predicted from the reconstructed map.
;                   They correspond to the sub-collimators used for reconstructing the image
;                   
;   obs_amp: out, float array of observed visibility amplitudes
;   
;   obs_sigamp: out, float array of uncertainties on the visibility amplitudes
;   
;   obs_phase: out, float array of observed visibility phases
;   
;   obs_sigphase: out, float of uncertainties on the visibility phases
;
; OUTPUTS:
;
;   chi2: chi2 value associated with the input map. Computed assuming N_VIS-1 degrees of freedom, where N_VIS is the numeber
;         of observed visibilities
;
; HISTORY: August 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

pro stx_plot_fit_map, in_map, chi2=chi2, this_window=this_window, pred_vis=pred_vis, pred_amp=pred_amp, $
                      pred_phase=pred_phase, obs_amp=obs_amp, obs_sigamp=obs_sigamp,$
                      obs_phase=obs_phase, obs_sigphase=obs_sigphase
                      

default, this_window, 0

obs_vis    = in_map.OBS_VIS.obsvis  ; Observed visibilities that are used for reconstructing 'in_map'
pred_vis   = in_map.PRED_VIS.mapvis ; Visibilities predicted from 'in_map'

;;*********** Amplitudes

obs_amp  = abs(obs_vis)
obs_sigamp = in_map.OBS_VIS.sigamp  ; Error on observed visibility amplitudes
pred_amp = abs(pred_vis)

;;*********** Phases

obs_phase  = atan(imaginary(obs_vis), float(obs_vis)) * !radeg
obs_sigphase   = f_div(obs_sigamp, obs_amp) * !radeg
pred_phase = atan(imaginary(pred_vis), float(pred_vis)) * !radeg

;;*********** Chi2

n_vis  = n_elements(obs_vis)
n_free = n_vis-1
chi2   = total(abs(pred_vis - obs_vis)^2./obs_sigamp^2.)/n_free

;;*********** PLOT

subc_labels = ['1a','1b','1c','2a','2b','2c',$
               '3a','3b','3c','4a','4b','4c',$
               '5a','5b','5c','6a','6b','6c',$
               '7a','7b','7c','8a','8b','8c',$
               '9a','9b','9c','10a','10b','10c'] 

xx_tmp      = (findgen(30))/3. + 1.2

this_labels = in_map.OBS_VIS.LABEL ;; Labels subcollimators used for computing the observed visibilities

idx = intarr(n_vis)
for i=0,n_vis-1 do begin
  
  idx[i] = where(subc_labels eq this_labels[i])
  
endfor

xx = xx_tmp[idx]

charsize = 1.5
leg_size = 1.5
thick    = 1.5
symsize  = 1.8

color1 = cgcolor('Spring Green')
color2 = cgcolor('red')

units_phase = 'degrees' 
units_amp   = 'counts s!U-1!n cm!U-2!n keV!U-1!n'
xtitle      = 'Detector label'
title       = in_map.ID + ' ' + in_map.TIME + ' - CHI2: ' + trim(chi2, '(f12.2)')

xrange=[1,11]
xtickv = [1:10]

window, this_window, xsize=1200, ysize=500
cleanplot

set_viewport,0.1, 0.48, 0.27, 0.82

plot, xx, obs_phase, /nodata, xrange=xrange, /xst, xtickinterval=1, xminor=-1, $
  title='VISIBILITY PHASE FIT', XTICKFORMAT="(A1)", $
  xtitle='', ytitle=units_phase, yrange=[-200,300], /yst, charsize=charsize, thick=thick, /noe

; draw vertical dotted lines at each detector boundary
for i=1,10 do oplot, i+[0,0], !y.crange, linestyle=1


errplot, xx, (obs_phase - obs_sigphase > !y.crange[0]), (obs_phase + obs_sigphase < !y.crange[1]), $
  width=0, thick=thick, color=color1
oplot, xx, obs_phase, psym=7, thick=thick, symsize=symsize
oplot, xx, pred_phase, psym=4, thick=thick, symsize=symsize, color=color2


leg_text = ['Observed', 'Error on Observed', 'From Map']
leg_color = [255,color1,color2]
leg_style = [0, 0, 0]
leg_sym = [7, -3, 4]
ssw_legend, leg_text, psym=leg_sym, color=leg_color, linest=leg_style, box=0, charsize=leg_size, thick=thick,/right

;; Residuals
set_viewport,0.1, 0.48, 0.12, 0.27

plot, xx, (obs_phase - pred_phase)/obs_sigphase, /nodata, xticks=9, xtickv=xtickv, xrange=xrange, /xst, $
  charsize=charsize, thick=thick, yrange=[-8,8], /yst, $
  xtitle=xtitle, ytitle=y_title_residuals, /noe

; draw vertical dotted lines at each detector boundary
for i=1,10 do oplot, i+[0,0], !y.crange, linestyle=1

oplot, xx, xx*0., linestyle=1, color=color2, thick=thick
oplot, xx, (obs_phase - pred_phase)/obs_sigphase, psym=1, symsize=symsize, color=color0, thick=thick_res


set_viewport,0.57, 0.95, 0.27, 0.82

plot, xx, obs_amp, /nodata, xrange=xrange, /xst, xtickinterval=1, xminor=-1, $
  title='VISIBILITY AMPLITUDE FIT', XTICKFORMAT="(A1)", $
  xtitle='', ytitle=units_amp, charsize=charsize, thick=thick, yrange=[0,max(obs_amp + obs_sigamp)*4/3], /yst, /noe

; draw vertical dotted lines at each detector boundary
for i=1,10 do oplot, i+[0,0], !y.crange, linestyle=1


errplot, xx, (obs_amp - obs_sigamp > !y.crange[0]), (obs_amp + obs_sigamp < !y.crange[1]), $
  width=0, thick=thick, COLOR=color1
oplot, xx, obs_amp, psym=7, thick=thick, symsize=symsize
oplot, xx, pred_amp, psym=4, thick=thick, symsize=symsize, color=color2


leg_text = ['Observed', 'Error on Observed', 'From Map']
leg_color = [255,color1,color2]
leg_style = [0, 0, 0]
leg_sym = [7, -3, 4]
ssw_legend, leg_text, psym=leg_sym, color=leg_color, linest=leg_style, box=0, charsize=leg_size, thick=thick, /left

set_viewport,0.57, 0.95, 0.12, 0.27

plot, xx, (obs_amp - pred_amp)/obs_sigamp, /nodata, xticks=9, xtickv=xtickv, xrange=xrange, /xst, $
  charsize=charsize, thick=thick, yrange=[-8,8], /yst, $
  xtitle=xtitle, ytitle=y_title_residuals, /noe

; draw vertical dotted lines at each detector boundary
for i=1,10 do oplot, i+[0,0], !y.crange, linestyle=1

oplot, xx, xx*0., linestyle=1, color=color2, thick=thick
oplot, xx, (obs_amp - pred_amp)/obs_sigamp, psym=1, symsize=symsize, color=color0, thick=thick_res



xyouts,0.5,0.92,title,/normal,chars=2.,ali=0.5

!p.position = [0, 0, 0, 0]

end