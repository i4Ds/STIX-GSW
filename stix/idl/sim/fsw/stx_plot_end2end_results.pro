;+
; :description:
;    This procedure plots the fit parameters from stx_end2end_spectrogram_test
;
; :categories:
;    data simulation, spectrogram
;
; :keywords:
;
;
; :examples:
;
;   stx_sim_rhessi_fit
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;
;-
pro stx_plot_end2end_results, fit_results, scenario_name = scenario_name, all_params =all_params, $
     utvals =utvals, tntmask = tntmask, flare_start = ut_flare_start 
     
        
 restore, scenario_name+'/ospex_obj.sav'


ntmask = fit_results.SPEX_SUMM_FREE_MASK[3,*]

tmask = fit_results.SPEX_SUMM_FREE_MASK[0,*]


sigs = fit_results.SPEX_SUMM_SIGMAS

tmask[where(sigs[1,*] eq 0.0 )] = 0 
ntmask[where(sigs[4,*] eq 0.0 )] = 0

s = obj -> get(/spex_fit_time_used)

edge_products, s, mean = tmean
therms = where(tntmask[*,0] eq 1)
ntherms = where(tntmask[*,1] eq 1)

params = obj->get(/spex_summ_params)

linecolors

!p.multi = [0,1,2]

filename = scenario_name + '_results.eps'
!p.thick = 2
!x.thick = 2
!y.thick = 2
!p.charthick = 2
!p.charsize = 2
 
 ntfils = where(ntmask eq 1)
 tfils  = where(tmask eq 1)

if   ntherms[0] eq -1 then begin
  
   !p.multi = [0,1,2]
   
   ps_on, filename=filename, margin = 5
   device, /color,/encapsulated,/AVANTGARDE,/bold,/ISOLATIN1

   ymin = min(all_params[where(all_params[*,0] gt 1e-6),0])*0.5
   ymax = max(params[0,*]+sigs[0,*])*100

   utplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,0],  anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1, /ylog, ytitle = 'Emission Measure !C[10!u49!n cm!u-3!n]',$
     yrange = [ymin,ymax ],/yst, XMARGIN = [12.5, 3], /xst, xrange = [min(utvals-utvals[0,0]-240), max(utvals-utvals[0,0])], /NOLABEL
   outplot, tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare, params[0,tfils],  psym = 1, color = 2
   uterrplot,tmean[tfils]-(utvals[0,0]+ut_flare_start)- preflare, ((params[0,tfils]- sigs[0,tfils]) > ymin) < ymax, ((params[0,tfils]+sigs[0,tfils]) > ymin) < ymax, color = 2

   oplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,0], psym = 1

   al_legend, ['Input RHESSI parameters','OSPEX Results from STIX data'], colors =[0,2], psym = [1,1],/right, CHARSIZE =.8

   ymin = min(all_params[therms[where(all_params[therms,1] gt 1e-6)],2])*.9
   ymax = max(params[1,*]+sigs[0,*])*1.1 < 3

   utplot, utvals[therms]-utvals[0,0]-preflare., all_params[therms,1], anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1,   yrange = [ymin,ymax ], ytitle = 'Plasma Temperature [keV]', $
     /yst,  XMARGIN = [12.5, 3], /xst,  xrange = [min(utvals-utvals[0,0]-240), max(utvals-utvals[0,0])]
   outplot, tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare, params[1,tfils],   psym = 1, color = 2
   uterrplot,tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare,(params[1,tfils]- sigs[1,tfils]) >0, (params[1,tfils]+sigs[1,tfils]) < 10, color = 2
   outplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,1], psym = 1

   ps_off
  
endif else begin
 
  !p.multi =[0,1,4]


  ps_on, filename=filename, margin = 5
  device, /color,/encapsulated,/AVANTGARDE,/bold,/ISOLATIN1

  ymin = min(all_params[where(all_params[*,0] gt 1e-6),0])*0.5
  ymax = max(params[0,*]+sigs[0,*])*100

  utplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,0],  anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1, /ylog, ytitle = 'Emission Measure !C[10!u49!n cm!u-3!n]',$
    yrange = [ymin,ymax ],/yst, XMARGIN = [15, 3], /xst, xrange = [min(utvals-utvals[0,0]-240), max(utvals-utvals[0,0])], /NOLABEL, ymargin = [1,1]
  outplot, tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare, params[0,tfils],  psym = 1, color = 2
  uterrplot,tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare, ((params[0,tfils]- sigs[0,tfils]) > ymin) < ymax, ((params[0,tfils]+sigs[0,tfils]) > ymin) < ymax, color = 2

  oplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,0], psym = 1

  al_legend, ['Input RHESSI parameters','OSPEX Results from STIX data'], colors =[0,2], psym = [1,1],/right, CHARSIZE =.8


  ymin = min(all_params[ntherms[where(all_params[ntherms,1] gt 1e-6)],2])*.9
  ymax = max(params[1,*]+sigs[0,*])*1.1

  utplot, utvals[therms]-utvals[0,0]-preflare., all_params[therms,1], anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1,   yrange = [ymin,ymax ], ytitle = 'Plasma Temperature [keV]', $
    /yst,  XMARGIN = [15, 3], /xst,  xrange = [min(utvals-utvals[0,0]-240), max(utvals-utvals[0,0])], /NOLABEL, ymargin = [1,1]
  outplot, tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare, params[1,tfils],   psym = 1, color = 2
  uterrplot,tmean[tfils]-(utvals[0,0]+ut_flare_start)-preflare,(params[1,tfils]- sigs[1,tfils]) >0, (params[1,tfils]+sigs[1,tfils]) < 10, color = 2
  outplot, utvals[therms]-utvals[0,0]-preflare, all_params[therms,1], psym = 1


  utplot, utvals[ntherms]-utvals[0,0]-preflare., all_params[ntherms,2],  anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1, /ylog, ytitle = 'Normalization at 50 keV', $
    yrange = [ymin,ymax ] ,/yst, xrange = [min(utvals-utvals[0,0]), max(utvals-utvals[0,0])], /xst, XMARGIN = [15, 3], /NOLABEL, ymargin = [1,1]
  outplot, tmean[ntfils]-(utvals[0,0]+ut_flare_start)-preflare, params[3,ntfils],psym = 1, color = 2
  errplot,tmean[ntfils]-(utvals[0,0]+ut_flare_start)-preflare, ((params[3,ntfils]- sigs[3,ntfils]) > ymin) < ymax, ((params[3,ntfils]+sigs[3,ntfils]) > ymin) < ymax, color = 2
  outplot, utvals[ntherms]-utvals[0,0]-preflare, all_params[ntherms,2], psym = 1

  ymin = min(all_params[ntherms[where(all_params[ntherms,3] gt 1e-6)],3])*.8
  ymax =  max(params[4,ntfils])*1.2

  utplot, utvals[ntherms]-utvals[0,0]-preflare., all_params[ntherms,3], anytim(utvals[0,0]-preflare+ut_flare_start, /ccs), psym = 1, yrange = [ymin,ymax ], $
    ytitle = 'Spectral Index',/yst, xrange = [min(utvals-utvals[0,0]), max(utvals-utvals[0,0])], /xst, XMARGIN = [15, 3], ymargin = [4,1]
  outplot, tmean[ntfils]-(utvals[0,0]+ut_flare_start)-preflare, params[4,ntfils] ,psym = 1, color = 2
  uterrplot,tmean[ntfils]-(utvals[0,0]+ut_flare_start)-preflare, params[4,ntfils]- sigs[4,ntfils] >0, params[4,ntfils]+sigs[4,ntfils]< 10, color = 2
  outplot, utvals[ntherms]-(utvals[0,0])-preflare, all_params[ntherms,3], psym = 1

  ps_off
  
endelse
set_plot,'x'


end