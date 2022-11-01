;+
;
; NAME:
;
;   stx_plot_vis_amp_vs_resolution
;
; PURPOSE:
;
;   Plot visibility amplitudes as a function of the corresponding resolution
;
; CALLING SEQUENCE:
;
;   stx_plot_vis_amp_vs_resolution, vis
;
; INPUTS:
;
;   vis: calibrated 'stx_visibility' structure
;
; HISTORY: September 2022, Massa P., created
;
; CONTACT:
;   paolo.massa@wku.edu
;-

pro stx_plot_vis_amp_vs_resolution, vis

calibrated = vis[0].calibrated

if ~calibrated then message, 'The input visibility structure must be calibrated'

vis_res = 1/(2.*sqrt(vis.u^2 + vis.v^2))
vis_amp = abs(vis.obsvis)
sigamp  = vis.sigamp

chsize=1.2
loadct,5,/silent
color=122
device, Window_State=win_state
if not win_state[3] then window,3,xsize=520,ysize=400,xpos=0,ypos=40
wset,3

clearplot
;shift display for bottom pixel to avoid overlap

plot_oo,(1./vis_res)^2,vis_amp,psym=1,xtitle='1/resolution^2',ytitle='amplitudes',yrange=[min(vis_amp),2*max(vis_amp+sigamp)],/nodata,$
  title='Visibility amplitudes vs resolution',xrange=[2d-5,1d-1],/xsty,/ysty, charsize=chsize
oplot,(1./vis_res)^2,vis_amp,psym=1,color=color,symsize=this_ss,thick=th3
errplot,(1./vis_res)^2,(vis_amp-sigamp)>0.001,vis_amp+sigamp,color=color,thick=th3,width=1d-13

end