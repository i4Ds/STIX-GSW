;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_counts_calc
;
; PURPOSE:
;    	Calculates at first the STIX counts by means of folding the STIX DRM with the RHESSI photons and 
;	then adds POISSON noise the STIX counts           
;
; CATEGORY:
;       SIMULATION, SPECTRA, X-ray analysis
;
; CALLING SEQUENCE:
;    IDL> stx_counts_calc, obj=objname, phot_struct=phot_struct, stx_drm=stx_drm, intv=intv, seed1=seed1, stx_ct_struct, noplot=noplot,_extra=_extra
;    IDL> help, stx_ct_struct,/st
;	s 		- spex_summ of object
;       in 		- info of object
;	stx_cts0 	- STIX data counts calculated from data_pht; 2D-array [e-bins,t-bins]
;	stx_ct_flux0 	- STIX data count flux to stx_cts0; 2D-array [e-bins,t-bins]
;	stx_cts 	- STIX data counts calculated from  m_counts
;	stx_ct_flux 	- STIX data count flux to stx_cts; 2D-array [e-bins,t-bins]
;	stx_cts1 	- STIX data counts calculated from photons1; 2D-array [e-bins,t-bins]
;	stx_ct_flux1 	- STIX data count flux to stx_cts1; 2D-array [e-bins,t-bins]
;	interim0 	- STIX DRM folded with RHESSI photons (calc from data_pht)/RHESSI area
;	interim 	- STIX DRM folded with RHESSI photons (calc from m_counts)/RHESSI area
;	interim1 	- STIX DRM folded with RHESSI photons (calc from photons1)/RHESSI area
;	enspex 		- STIX energy bin edges; 2D array (2x32 elements from [4,5] to [132.251 ,150] keV) 
;	ct_edges1 	- STIX energy bin edges; 1D array (33 elements from 4 to 150 keV) 
;	emean 		- mean energy of STIX energy bins; 1D array (32 elements) 
;	win   		- width of STIX energy bins; 1D array (32 elements)
;	phot_struct 	- RHESSI photons structure
;	stx_drm 	- STIX drm structure
;	poi_counts 	- STIX data counts stx_cts plus Poisson noise
;	poi_counts0 	- STIX data counts stx_cts0 plus Poisson noise
;	poi_counts1 	- STIX data counts stx_cts1 plus Poisson noise
;
; HISTORY:
;       
;       29-Apr-2013 - ines.kienreich@uni-graz.at (INK)
;-

;+
; :description:
; 	determination of STIX counts by means of folding the STIX DRM, derived in stx_calc_drm, with the RHESSI photons calculated 
;	in different ways in stx_hessi_photons_calc, and application of poidev to the data to add noise to the STIX spectra.
;
; :keywords:
;	NOPLOT	- if set, then no interim plots are shown
;   
; :params:
;       OBJNAME		- name of the OSPEX object
;  	phot_struct	- name of the structure containing the RHESSI photons
;  	stx_drm		- name of the structure containing the STIX DRM
;  	intv 		- index of time-interval user wants to be plotted; integer
;  	seed1 		- in case the application of Poisson noise via poidev was already performed. This keyword can be used to have POIDEV give 
;             		  identical results on consecutive runs.    
;   
; :returns:
;    Returns the structure stx_ct_struct containing STIX data counts, with the RHESSI photons stored in the structure phot_struct
;     as starting points, as well as their noisy pendants
;    
;-


pro stx_counts_calc,obj=objname, phot_struct=phot_struct, stx_drm=stx_drm,intv=intv, seed1=seed1, stx_ct_struct, noplot=noplot,_extra=_extra



print, 'begin stx_counts_calc'

s = objname->get(/spex_summ)
in = objname->get(/info)

enspex = s.spex_summ_energy

edge_products,enspex,edges_2=ct_edges2,mean=emean,width=win

ct_edges1 = get_edges(s.spex_summ_energy,/edges_1)


;===============================================

; CALCULATION of STIX counts from RHESSI photons by means of STIX DRM

;===============================================

 ; fitdata = getdata(class='spex_fitint') one possibility, but info already included in d_ct
 ;					 as d_ct is a structure with 8 elements --> see above

  data_ct = phot_struct.data_ct

  data_pht = phot_struct.data_pht

  m_counts = phot_struct.m_counts

  photons1 = phot_struct.photons1
  
  ct_flux = phot_struct.ct_flux

  smatrix = stx_drm.smatrix

  area51 = s.spex_summ_area  ; RHESSI area

  ;print, area51

; METHOD 1: using data photons ==> data_pht ; two-dim array [n(energy_bins),n(time_bins)]
;----------------------------------------------------------------------------------------


sz0 = size(data_pht)

stx_cts0 = fltarr(sz0[1],sz0[2])

interim0 = fltarr(sz0[1],sz0[2])


for i = 0,sz0[2]-1 do begin
	interim0[*,i] = smatrix#data_pht[*,i]/area51  ; counts divided by RHESSI area ==> delivers 1cm^2 area
	stx_cts0[*,i] = win*(smatrix#data_pht[*,i])/area51
endfor

stx_ct_flux0 = interim0/ data_ct.ltime



; METHOD 2: using fitted values ==> m_counts; structure; composite fit in yvals [*,0,*] !!!
;-------------------------------------------------------------------------------------------

;		YVALS           DOUBLE    Array[32, 3, 33]
;  		ID              STRING    Array[3]
;  		STRAT_ARR       STRING    Array[3]
;  		CT_ENERGY       FLOAT     Array[2, 32]
; data in m_counts.yvals: 3D-array [n(energy_bins),3,n(time_bins)]; 
;                         !!!! in this case, if there are more components for fit 
;                                                         ---> size of 2nd dimension increases
;  m_counts.yvals[*,0,n0]...composite fit
;  m_counts.yvals[*,1,n0]...vth
;  m_counts.yvals[*,2,n0]...bpow


sz = size(m_counts.yvals)

stx_cts = fltarr(sz[1],sz[3])

interim = fltarr(sz[1],sz[3])


for i = 0,sz[3]-1 do begin
	interim[*,i] = smatrix#m_counts.yvals[*,0,i]/area51
	stx_cts[*,i] = win*(smatrix#m_counts.yvals[*,0,i])/area51
endfor

stx_ct_flux = interim/ data_ct.ltime
;print, data_ct.ltime
;print,area51
;print, win
;print, m_counts.yvals[*,0,7]
;print, data_pht[*,7]

; METHOD 3: using photons calculated from photon flux 
;----------------------------------------------------

sz1 = size(photons1)

stx_cts1 = fltarr(sz1[1],sz1[2])

interim1 = fltarr(sz1[1],sz1[2])


for i = 0,sz1[2]-1 do begin
	interim1[*,i] = smatrix#photons1[*,i]
	stx_cts1[*,i] = win*(smatrix#photons1[*,i])
endfor

stx_ct_flux1 = interim1/ data_ct.ltime


;comparison to RHESSI count flux:
;ct_flux = obj->calc_summ(item='data_count_flux', this_interval=indgen(33),errors=data_count_flux_errors)

;*************************************************************************************

;==============================================================================

; Addition of Poisson noise to the STIX count spectra - application of poidev

;==============================================================================

; METHOD 2: using  stx_cts ==>  m_counts (fitted values)
;----------------------------------------------------------------------------------------
  
  poi_counts = (keyword_set(seed1)) ? poidev(stx_cts,seed=seed1) : poidev(stx_cts,seed=seed)
  
  sz_p = size(poi_counts)
  interim_poi = fltarr(sz_p[1],sz_p[2])
  
  for i = 0,sz_p[2]-1 do begin
  	interim_poi[*,i] =poi_counts[*,i]/ win
  endfor
  
  poi_count_flux = interim_poi/ data_ct.ltime
  
  
  
  ; METHOD 1: using  stx_cts0 ==> data_pht (data photons)
  ;----------------------------------------------------------------------------------------

  poi_counts0 = (keyword_set(seed1)) ? poidev(stx_cts0,seed=seed1) :   poidev(stx_cts0,seed=seed)
  
  sz_p0 = size(poi_counts0)
  interim_poi0 = fltarr(sz_p0[1],sz_p0[2])
  
  for i = 0,sz_p0[2]-1 do begin
  	interim_poi0[*,i] =poi_counts0[*,i]/ win
  endfor
  
    poi_count_flux0 = interim_poi0/ data_ct.ltime
  
  
  
  ; METHOD 3: using  stx_cts1 ==> photons1 (from photon flux)
  ;----------------------------------------------------------------------------------------

  poi_counts1 = (keyword_set(seed1)) ? poidev(stx_cts1,seed=seed1) :   poidev(stx_cts1,seed=seed)
  
  sz_p1 = size(poi_counts1)
  interim_poi1 = fltarr(sz_p1[1],sz_p1[2])
  
  for i = 0,sz_p1[2]-1 do begin
  	interim_poi1[*,i] =poi_counts1[*,i]/ win
  endfor
  
    poi_count_flux1 = interim_poi1/ data_ct.ltime
  

;*************************************************************************************
 
val = 10^(findgen(12)-6.) 
val1 = min(stx_cts[*,intv])/val
val2 = (max(stx_cts[*,intv])>max(data_ct.data[*,intv]/area51))/val

l1 = where (val1 lt 1) 
l2 = where (val2 lt 1)


if not keyword_set(noplot) then begin

	window,4,xs=1200,ys=650

	!p.multi=[0,3,1]

;left
	 tit = 'HESSI Counts vs Energy (area 1 cm!U2!n)'
	 plot_oo,emean,data_ct.data[*,intv]/area51,/nodata,xtitle='Energy (keV)',ytitle='Counts',xst=1,xr=[4,150],$   ;,ytitle='photons s!U-1!n cm!U-2!n keV!U-1!n'  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit
	 yr=[val[l1[0]-1],val[l2[0]]],charsize=1.2,xcharsize=1.2,ycharsize=1.2,title=tit,/yst 
	 oplot,emean,stx_cts[*,intv],psym=10, thick=1.5
	 linecolors
	 oplot,emean,data_ct.data[*,intv]/area51,psym=10,col=2, thick=1.5
	 
	 xyouts,0.3,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm

	 xyouts,0.28,0.85,'from phot fit',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.28,0.8,'RHESSI',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.8,'__',alignment=1.0,color=2,charsize=1.2,/norm

;center
	 tit1 = 'STIX Counts vs Energy'
	 plot_oo,emean,stx_cts[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Counts',xst=1,xr=[4,150],$  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit1
	 yr=[val[l1[0]-1],val[l2[0]]],charsize=1.2,xcharsize=1.2,ycharsize=1.2,title=tit1,/yst 
	 oplot,emean,stx_cts[*,intv],psym=10, thick=1.5
	 linecolors 
	 oplot, emean,stx_cts0[*,intv],psym=10,color=7
	 ;oplot, emean,stx_cts1[*,intv],psym=10,color=7
	 xyouts,0.63,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.63,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	 anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	 

	 xyouts,0.6,0.85,'from phot fit',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.62,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.6,0.8,'from phot data',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.62,0.8,'__',alignment=1.0,color=7,charsize=1.2,/norm

;right
	 tit1 = 'STIX Counts (+ noise) vs Energy'
	 plot_oo,emean,poi_counts[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Counts',xst=1,xr=[4,150],$  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit1
	 yr=[val[l1[0]-1],val[l2[0]]],charsize=1.2,xcharsize=1.2,ycharsize=1.2,title=tit1,/yst 
	 oplot,emean,stx_cts[*,intv],psym=10, thick=1.5
	 oplot,emean,poi_counts[*,intv],psym=10, thick=1.5,color=5
	 linecolors 
	 oplot, emean,poi_counts0[*,intv],psym=10,color=7
	 ;oplot, emean,poi_counts1[*,intv],psym=10,color=9
	 xyouts,0.97,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	 anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	
	 xyouts,0.95,0.85,'STIX noiseless',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.95,0.8,'STIX fit + noise',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.8,'__',alignment=1.0,color=5,charsize=1.2,/norm
	 xyouts,0.95,0.75,'STIX data + noise',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.75,'__',alignment=1.0,color=7,charsize=1.2,/norm

	
;--------------------------------------------------------


fval = 10^(findgen(12)-6.) 
fval1 = min(stx_ct_flux[*,intv])/fval
fval2 = (max(stx_ct_flux[*,intv])>max(ct_flux[*,intv]))/fval

fl1 = where (fval1 lt 1) 
fl2 = where (fval2 lt 1)


	window,5,xs=1200,ys=650

	!p.multi=[0,3,1]


	 tit = 'HESSI Count Flux vs Energy (area 1 cm!U2!n)'
	 plot_oo,emean,ct_flux[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Count Flux',xst=1,xr=[4,150],$   ;,ytitle='photons s!U-1!n cm!U-2!n keV!U-1!n'  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit
	 yr=[fval[fl1[0]-1],fval[fl2[0]]],charsize=1.2,xcharsize=1.1,ycharsize=1.1,title=tit,/yst 
	 oplot,emean,stx_ct_flux[*,intv],psym=10, thick=1.5
	 linecolors
	 oplot,emean,ct_flux[*,intv],psym=10,col=2, thick=1.5
	 
	 xyouts,0.3,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm

	 xyouts,0.28,0.85,'from phot fit',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.28,0.8,'RHESSI',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.3,0.8,'__',alignment=1.0,color=2,charsize=1.2,/norm

	 tit1 = 'STIX Count Flux vs Energy'
	 plot_oo,emean,stx_ct_flux[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Count Flux',xst=1,xr=[4,150],$  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit1
	 yr=[fval[fl1[0]-1],fval[fl2[0]]],charsize=1.2,xcharsize=1.1,ycharsize=1.1,title=tit1,/yst 
	 oplot,emean,stx_ct_flux[*,intv],psym=10, thick=1.5
	 linecolors 
	 oplot, emean,stx_ct_flux0[*,intv],psym=10,color=7
	 
	 xyouts,0.63,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.63,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	 anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	 

	 xyouts,0.6,0.85,'from phot fit',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.62,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.6,0.8,'from phot data',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.62,0.8,'__',alignment=1.0,color=7,charsize=1.2,/norm

          ;legend,['from fit','from data'],linestyle=0,colors=[0,2],position=[0.6,0.7]

	 tit1 = 'STIX Count Flux (+noise) vs Energy'
	 plot_oo,emean,poi_count_flux[*,intv],/nodata,xtitle='Energy (keV)',ytitle='Count Flux',xst=1,xr=[4,150],$  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit1
	 yr=[fval[fl1[0]-1],fval[fl2[0]]],charsize=1.2,xcharsize=1.1,ycharsize=1.1,title=tit1,/yst 
	 oplot,emean,stx_ct_flux[*,intv],psym=10, thick=1.5
	 oplot,emean,poi_count_flux[*,intv],psym=10, thick=1.5,color=5
	 linecolors 
	 oplot, emean,poi_count_flux0[*,intv],psym=10,color=7
	 ;oplot, emean,poi_count_flux1[*,intv],psym=10,color=9
	 xyouts,0.97,0.95,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.9,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	 anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	
	 xyouts,0.95,0.85,'STIX noiseless',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.85,'__',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.95,0.8,'from fit + noise',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.8,'__',alignment=1.0,color=5,charsize=1.2,/norm
	 xyouts,0.95,0.75,'from data + noise',alignment=1.0,charsize=1.2,/norm
	 xyouts,0.97,0.75,'__',alignment=1.0,color=7,charsize=1.2,/norm



	
 endif
!p.multi=0

;*************************************************************************************


stx_ct_struct ={stx_cts0:stx_cts0,$
		stx_cts:stx_cts,$
		stx_cts1:stx_cts1,$
		interim0:interim0,$
		interim:interim,$
		interim1:interim1,$
		stx_ct_flux0:stx_ct_flux0,$
		stx_ct_flux:stx_ct_flux,$
		stx_ct_flux1:stx_ct_flux1,$
		enspex:enspex,$
		ct_edges1:ct_edges1,$
		emean:emean,$
		win:win,$
		phot_struct:phot_struct,$
		stx_drm:stx_drm, $
		poi_counts:poi_counts,$
		poi_counts0:poi_counts0,$
		poi_counts1:poi_counts1}


print, 'end stx_counts_calc'

end