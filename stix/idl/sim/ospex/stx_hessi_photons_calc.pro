;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_hessi_photons_calc
;
; PURPOSE:
;    Calculates the RHESSI photons in STIX energy binning, which are then folded with the STIX drm to derive the STIX counts
;           
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;    IDL> stx_hessi_photons_calc,obj=objname,intv=intv,phot_struct,noplot=noplot,_extra=_extra
;    IDL> help, phot_struct,/st
;** Structure <ce8c68>, 12 tags, length=131504, data length=131448, refs=1:
;   S               STRUCT    -> <Anonymous> Array[1] 	- spex_summ of object
;   IN              STRUCT    -> <Anonymous> Array[1] 	- info of object
;   DATA_CT         STRUCT    -> <Anonymous> Array[1] 	- RHESSI data counts; structure
;   DATA_PHT        FLOAT     Array[32, 24]		- RHESSI data photons calculated with method 1; 2D-array [e-bins,t-bins]
;   M_COUNTS        STRUCT    -> <Anonymous> Array[1]	- RHESSI data photons calculated with method 2; structure
;   PH_FLUX         FLOAT     Array[32, 24]		- RHESSI data photon flux; 2D-array [e-bins,t-bins]
;   M_FLUX	    STRUCT    -> <Anonymous> Array[1]	- RHESSI data photon flux calculated with method 2; structure
;   MOD_FLUX        FLOAT     Array[32, 24]		- RHESSI model photon flux; structure
;   CT_FLUX         FLOAT     Array[32, 24]		- RHESSI data count flux
;   PH_COUNTS       FLOAT     Array[32, 24]		- RHESSI data photons calculated with method 3; 2D-array [e-bins,t-bins]
;   PH_COUNTS_FIT   FLOAT     Array[32, 24]		- RHESSI model photons calculated with method 3; 2D-array [e-bins,t-bins]
;   PHOTONS1        FLOAT     Array[32, 24]		- RHESSI data photons calculated with method 4; 2D-array [e-bins,t-bins]
;   PHOTONS2        FLOAT     Array[32, 24]		- RHESSI model photons calculated with method 4; 2D-array [e-bins,t-bins]
;
; HISTORY:
;       
;       29-Apr-2013 - ines.kienreich@uni-graz.at (INK)
;-

;+
; :description:
; This program applies various methods to calculate the RHESSI photons, starting from different parameters 
; (e.g. data/model counts, data/model photon fluxes), which were derived using the HESSI and OSPEX GUI.
; The resulting structure is an input parameter for stx_counts_calc
;
; :keywords:
;	NOPLOT	- if set, then no interim plots are shown
;   
; :params:
;       OBJNAME	- name of the OSPEX object
;  	intv 	- index of time-interval user wants to be plotted; integer
;   
; :returns:
;    Returns the structure phot_struct containing 2D arrays of RHESSI photons, calculated with different methods, plus RHESSI data counts and RHESSI
;    data and model photon fluxes
;-

pro stx_hessi_photons_calc,obj=objname,intv=intv,phot_struct,noplot=noplot,_extra=_extra



print, 'begin stx_hessi_photons_calc'

;help, objname

s = objname->get(/spex_summ)
in = objname->get(/info)

enspex = s.spex_summ_energy

edge_products,enspex,edges_2=enspex,mean=emean,width=win

enedges_1d = get_edges(s.spex_summ_energy,/edges_1)


 sztim = size(s.SPEX_SUMM_TIME_INTERVAL)
 
 print, sztim
 
 

;*************************************************************************************

;==============================================

; CALCULATION OF RHESSI PHOTONS (PHOTON COUNTS)

;===============================================


; METHOD 1 --> using original RHESSI DATA COUNTS
;------------------------------------------------

	conv = s.spex_summ_conv
	data_ct = objname -> getdata(class='spex_fitint',spex_units='counts')

	data_pht = data_ct.data     
	spex_apply_eff,data_pht,conv  ; array 32x33  (e-bins, t-bins)
	
	
livetime_array = data_ct.ltime


; METHOD 2 --> using CALC_FUNC_COMPONENTS
;------------------------------------------------

	 m_counts = objname->calc_func_components(this_interval=indgen(sztim[2]),/use_fitted,photons=1,spex_units='counts') ;!!!!!!
	 m_flux = objname->calc_func_components(this_interval=indgen(sztim[2]),/use_fitted,photons=1,spex_units='flux') ;!!!!!!



; METHOD 3 --> using data or fitted RHESSI DATA PHOTON FLUX
;-----------------------------------------------------------

	ph_flux = objname->calc_summ(item='data_photon_flux',this_interval=indgen(sztim[2]),errors=data_photon_flux_errors)

	mod_flux = objname->calc_summ(item='model_photon_flux',this_interval=indgen(sztim[2]),errors=data_photon_flux_errors)

	ct_flux = objname->calc_summ(item='data_count_flux', this_interval=indgen(sztim[2]),errors=data_count_flux_errors)

	ph_counts = fltarr(32,sztim[2])
	ph_counts_fit = fltarr(32,sztim[2])

	for i=0,sztim[2]-1 do begin
		ph_counts[*,i] = objname -> convert_fitfunc_units(ph_flux[*,i],/photons,spex_units='counts')
		ph_counts_fit[*,i] = objname -> convert_fitfunc_units(mod_flux[*,i],/photons,spex_units='counts');,/use_fitted)
	endfor


; METHOD 4: calculate values directly from ph_flux and mod_flux
;---------------------------------------------------------------



	dummy1 = rebin(win,size(ph_flux,/dim))
	dummy2 = dummy1*ph_flux

	photons1 = dummy2*livetime_array  ; THIS IS IDENTICAL TO d_ct1a/in.spex_area

	dummy_mod2 = dummy1*mod_flux
	photons2 = dummy_mod2*livetime_array  ; THIS IS IDENTICAL TO m_counts.yvals/in.spex_area


;*************************************************************************************
 
 
 
if not keyword_set(noplot) then begin

	window,3,xs=800,ys=600

	!p.multi=[0,2,1]


	 tit = 'HESSI Photon Flux vs Energy'
	 plot_oo,emean,ph_flux[*,intv],/nodata,xtitle='Energy (keV)',ytitle='photons s!U-1!n cm!U-2!n keV!U-1!n',xst=1,xr=[4,150],$  
	 charsize=1.2,xcharsize=1,ycharsize=1,title=tit
	 ;yr=[1.d-4,1.d6],charsize=1.2,xcharsize=1,ycharsize=1,title=tit,/yst 
	 oplot,emean,ph_flux[*,intv],psym=10, thick=1.5
	 linecolors
	 oplot, emean,(m_flux.yvals)[*,0,intv],psym=10,color=2
	 oplot, emean,(m_flux.yvals)[*,1,intv],psym=10,color=7
	 oplot, emean,(m_flux.yvals)[*,2,intv],psym=10,color=5
	 xyouts,0.45,0.9,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.45,0.85,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm


	 tit1 = 'HESSI Photons vs Energy'
	 plot_oo,emean,data_pht[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Photons',xst=1,xr=[4,150],$  
	 charsize=1.2,xcharsize=1,ycharsize=1,title=tit1
	 ;yr=[1.d-2,1.d8],charsize=1.2,xcharsize=1,ycharsize=1,title=tit1,/yst 
	 oplot,emean,data_pht[*,intv],psym=10, thick=1.5
	 linecolors 
	 oplot, emean,(m_counts.yvals)[*,0,intv],psym=10,color=2
	 oplot, emean,(m_counts.yvals)[*,1,intv],psym=10,color=7
	 oplot, emean,(m_counts.yvals)[*,2,intv],psym=10,color=5
	 xyouts,0.95,0.9,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.95,0.85,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	 anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	 
 endif

;*************************************************************************************


phot_struct =  {s:s,$
		in:in,$
		data_ct:data_ct,$
		data_pht:data_pht,$
		m_counts:m_counts,$
		ph_flux:ph_flux,$
		m_flux:m_flux,$
		mod_flux:mod_flux,$
		ct_flux:ct_flux,$
		ph_counts:ph_counts,$
		ph_counts_fit:ph_counts_fit,$
		photons1:photons1, $
		photons2:photons2}

print, 'end stx_hessi_photons_calc'

end