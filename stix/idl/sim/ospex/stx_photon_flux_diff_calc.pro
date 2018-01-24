;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_photon_flux_diff_calc
;
; PURPOSE:
;    	Determines the absolute and percentage differences between the RHESSI photon flux and 
;	STIX noiseless or noisy photon fluxes and updates stx_ct_struct           
;
; CATEGORY:
;       SIMULATION, SPECTRA, X-ray analysis
;
; CALLING SEQUENCE:
;    IDL> stx_photon_flux_diff_calc(stx_ct_struct, filename=filename, peaktime=peaktime, plotint=plotint, obj=objname, noise=noise, data=data, noplot=noplot)
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
;	stx_ph_flux	- STIX data photon flux calculated from stx_cts
;	stx_ph_flux0	- STIX data photon flux calculated from stx_cts0
;	stx_ph_flux1	- STIX data photon flux calculated from stx_cts1
;	stx_ph_poi_flux	- STIX data photon flux calculated from poi_counts
;	stx_ph_poi_flux0- STIX data photon flux calculated from poi_counts0
;	stx_ph_poi_flux1- STIX data photon flux calculated from poi_counts1

;
; HISTORY:
;       
;       29-Apr-2013 - ines.kienreich@uni-graz.at (INK)
;-

;+
; :description:
; 	Calculation of noiseless/noisy STIX photon fluxes (data/fit) using the functions calc_summ and calc_func_components
;	and computation of the differences in photon fluxes in absolute values [STIX-RHESSI; photons s^-1 cm^-2 keV^-1]
;       and on a percentage basis [(STIX-RHESSI)/RHESSI; %]
;       IMPORTANT: So far the script and fits files containing the noisy data MUST HAVE 'noise' in their filename !!!
;
; :keywords:
;	NOPLOT     - if set, then no interim plots are shown
;	NOSAVE     - if set, then no interim results are stored
;   
; :params:
;	stx_ct_struct	- STIX counts structure
;       FILENAME   	- ospex file to be loaded into the program (IMPORTANT: set obj = ospex(/no_gui) in OSPEX file !!!)
;       PEAKTIME   	- peak time of the event in format 'yyyy-mm-dd hh:mm:ss.xxx' (from RHESSI info)
;       OBJNAME    	- name of your object
;       PLOTINT    	- index of time-interval user wants to be plotted; integer
;   
; :returns:
;    Returns the modified structure stx_ct_struct containing STIX data counts, RHESSI photons, STIX DRM 
;     plus STIX and RHESSI photon fluxes and differences (absolute, percentage) of photon fluxes
;    
;-

function stx_photon_flux_diff_calc, stx_ct_struct, filename=filename, peaktime=peaktime, plotint=plotint, obj=objname, noise=noise, data=data, noplot=noplot, _extra=_extra


print, strpos(filename,'noise')

if (strpos(filename,'noise') ge 0) then begin
	print, 'keyword noise set'
	noise=1 
	if (strpos(filename,'data') ge 0) then begin
		print, 'keyword data set'
		data=1 
	endif else begin
		if keyword_set(data) then begin
			print, 'File name does not contain "data"! Check file and/or rename file! keyword data unset!'
			data=0
		endif
	endelse
endif else begin
 	if keyword_set(noise) then begin
		print, 'File name does not contain "noise"! Check file and/or rename file! keyword noise unset!'
		noise = 0
		if (strpos(filename,'data') ge 0) then begin
			print, 'keyword data set'
			data=1 
		endif else begin
			if keyword_set(data) then begin
				print, 'File name does not contain "data"! Check file and/or rename file! keyword data unset!'
				data=0
			endif
		endelse
	endif
	
endelse

CALL_PROCEDURE, filename, obj=objname

s = objname->get(/spex_summ)
in = objname->get(/info)

emean = stx_ct_struct.emean

  sztim = size(in.SPEX_SUMM_TIME_INTERVAL) 
  
  intv1 = where (anytim(peaktime) ge anytim(in.SPEX_SUMM_TIME_INTERVAL[0,*]) AND $
              anytim(peaktime) le anytim(in.SPEX_SUMM_TIME_INTERVAL[1,*])) 

  
  if not keyword_set(plotint) then begin
     intv =  intv1  
  endif else begin
   if (plotint ge 0 AND  plotint lt sztim[2]-1) then begin
  	intv = plotint 
   endif else begin
   	intv =  intv1
   endelse
  endelse
  print, intv

  sz_en_interval = size(in.SPEX_SUMM_ENERGY)     
  
;*************************************************************************************


ph_flux = stx_ct_struct.phot_struct.ph_flux
m_flux = stx_ct_struct.phot_struct.m_flux


	ph_flux_stix = objname->calc_summ(item='data_photon_flux',this_interval=indgen(sztim[2]),errors=data_photon_flux_errors)
	m_flux_stix = objname->calc_func_components(this_interval=indgen(sztim[2]),/use_fitted,photons=1,spex_units='flux') ;!!!!!!

	perc_ph_flux_stix = (ph_flux_stix-ph_flux)*100./ph_flux
	perc_m_flux_stix = (m_flux_stix.yvals-m_flux.yvals)*100./(m_flux.yvals>1.d-10)
	diff_ph_flux_stix = (ph_flux_stix-ph_flux)
	diff_m_flux_stix = (m_flux_stix.yvals-m_flux.yvals)
	
	NEW_STRUCT = stx_ct_struct
	



if not keyword_set(noise) then begin
;original STIX counts
        
        if not keyword_set(data) then begin
          	stx_ph_flux = ph_flux_stix
          	stx_m_flux = m_flux_stix
        	perc_ph_flux = perc_ph_flux_stix
        	perc_m_flux = perc_m_flux_stix
        	diff_ph_flux = diff_ph_flux_stix
        	diff_m_flux = diff_ph_flux_stix
        	
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_ph_flux,'stx_ph_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_m_flux,'stx_m_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_ph_flux,'perc_ph_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_m_flux,'perc_m_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_ph_flux,'diff_ph_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_m_flux,'diff_m_flux')        	
        	
        endif else begin
          	stx_ph_flux0 = ph_flux_stix
          	stx_m_flux0 = m_flux_stix
        	perc_ph_flux0 = perc_ph_flux_stix
        	perc_m_flux0 = perc_m_flux_stix
        	diff_ph_flux0 = diff_ph_flux_stix
        	diff_m_flux0 = diff_ph_flux_stix
        	
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_ph_flux0,'stx_ph_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_m_flux0,'stx_m_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_ph_flux0,'perc_ph_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_m_flux0,'perc_m_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_ph_flux0,'diff_ph_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_m_flux0,'diff_m_flux0')        	

        endelse        
	help, NEW_STRUCT
endif else begin
;noisy STIX counts

        if not keyword_set(data) then begin
		stx_ph_poi_flux = ph_flux_stix
		stx_m_poi_flux = m_flux_stix
        	perc_ph_poi_flux = perc_ph_flux_stix
        	perc_m_poi_flux = perc_m_flux_stix
        	diff_ph_poi_flux = diff_ph_flux_stix
        	diff_m_poi_flux = diff_ph_flux_stix
        	
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_ph_poi_flux,'stx_ph_poi_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_m_poi_flux,'stx_m_poi_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_ph_poi_flux,'perc_ph_poi_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_m_poi_flux,'perc_m_poi_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_ph_poi_flux,'diff_ph_poi_flux')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_m_poi_flux,'diff_m_poi_flux')        	

        endif else begin
          	stx_ph_poi_flux0 = ph_flux_stix
          	stx_m_poi_flux0 = m_flux_stix
        	perc_ph_poi_flux0 = perc_ph_flux_stix
        	perc_m_poi_flux0 = perc_m_flux_stix
        	diff_ph_poi_flux0 = diff_ph_flux_stix
        	diff_m_poi_flux0 = diff_ph_flux_stix
        	
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_ph_poi_flux0,'stx_ph_poi_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,stx_m_poi_flux0,'stx_m_poi_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_ph_poi_flux0,'perc_ph_poi_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,perc_m_poi_flux0,'perc_m_poi_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_ph_poi_flux0,'diff_ph_poi_flux0')
        	NEW_STRUCT=ADD_TAG(NEW_STRUCT,diff_m_poi_flux0,'diff_m_poi_flux0')        	

        endelse        
endelse
	
	
	help, NEW_STRUCT

;**********************************************************************************************++

if not keyword_set(noplot) then begin

window,20,xs=800,ys=600
!p.multi=[0,2,1]

yra = [(min(ph_flux[*,intv])< min(ph_flux_stix[*,intv]))>1.d-6, max(ph_flux[*,intv])> max(ph_flux_stix[*,intv])]

	 tit = 'HESSI Photon Flux vs Energy'
	 plot_oo,emean,ph_flux[*,intv],/nodata,xtitle='Energy (keV)',ytitle='photons s!U-1!n cm!U-2!n keV!U-1!n',xst=1,xr=[4,150],$  
	 yr=yra,charsize=1.2,xcharsize=1,ycharsize=1,title=tit
	 ;yr=[1.d-4,1.d6],charsize=1.2,xcharsize=1,ycharsize=1,title=tit,/yst 
	 oplot,emean,ph_flux[*,intv],psym=10, thick=1.5
	 linecolors
	 oplot, emean,(m_flux.yvals)[*,0,intv],psym=10,color=2
	 oplot, emean,(m_flux.yvals)[*,1,intv],psym=10,color=7
	 oplot, emean,(m_flux.yvals)[*,2,intv],psym=10,color=5
	 xyouts,0.45,0.9,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.45,0.85,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm



	 tit = 'STIX Photon Flux vs Energy'
	 plot_oo,emean,ph_flux_stix[*,intv],/nodata,xtitle='Energy (keV)',ytitle='photons s!U-1!n cm!U-2!n keV!U-1!n',xst=1,xr=[4,150],$  
	 ;charsize=1.2,xcharsize=1,ycharsize=1,title=tit
	 yr=yra,charsize=1.2,xcharsize=1,ycharsize=1,title=tit;,/yst 
	 oplot,emean,ph_flux_stix[*,intv],psym=10, thick=1.5
	 linecolors
	 oplot, emean,(m_flux_stix.yvals)[*,0,intv],psym=10,color=2
	 oplot, emean,(m_flux_stix.yvals)[*,1,intv],psym=10,color=7
	 oplot, emean,(m_flux_stix.yvals)[*,2,intv],psym=10,color=5
	 xyouts,0.45,0.9,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
	 xyouts,0.45,0.85,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
	 if keyword_set(noise) then begin
	 xyouts,0.95,0.9,'STIX photon flux + noise',alignment=1.0,charsize=1.2,/norm
         endif else begin
	 xyouts,0.95,0.9,'STIX photon flux',alignment=1.0,charsize=1.2,/norm         
         endelse

!p.multi=0

window,21,xs=800,ys=550
!p.multi=[0,2,1]

yr = [(min(perc_ph_flux_stix[2:28,intv])< min(perc_m_flux_stix[2:28,0,intv])), max(perc_ph_flux_stix[2:28,intv])> max(perc_m_flux_stix[2:28,0,intv])]
 
 plot,emean,perc_ph_flux_stix[*,intv],yrange=yr,xrange=[4,150],/xlog,/xst,psym=10,xtit = 'Energy (keV)',ytit = 'Difference (%)',$
 tit = 'STIX/HESSI Photon Flux Difference vs Energy' 
 linecolors
 oplot,emean,perc_m_flux_stix[*,0,intv],col=2,psym=10
 oplot,[6,6],!y.crange,linestyle=2
 oplot,[4,150],[0,0],linestyle=1
 oplot,[4,150],[100,100],linestyle=1
 oplot,[4,150],[-100,-100],linestyle=1
 	 xyouts,0.45,0.9,'Interval'+string(intv,format='(i3)'),alignment=1.0,charsize=1.2,/norm
 	 xyouts,0.45,0.85,anytim(in.SPEX_SUMM_TIME_INTERVAL[0,intv],/VMS,/truncate)+' - '+$
 	        anytim(in.SPEX_SUMM_TIME_INTERVAL[1,intv],/VMS,/time_only,/truncate),alignment=1.0,charsize=1.1,/norm
 


 yr1 = [min(diff_ph_flux_stix[2:28,intv])< min(diff_m_flux_stix[2:28,0,intv]), max(diff_ph_flux_stix[2:28,intv])> max(diff_m_flux_stix[2:28,0,intv])]
 
 plot,emean, diff_ph_flux_stix[*,intv], yrange = yr1, xrange=[4,150],/xlog,/xst,psym=10,xtit = 'Energy (keV)',$
 ytit = 'Difference (photons s!U-1!n cm!U-2!n keV!U-1!n)',tit = 'STIX/HESSI Photon Flux Difference vs Energy'  
 
 oplot,emean,diff_m_flux_stix[*,0,intv],col=2,psym=10
 oplot,[6,6],!y.crange,linestyle=2


endif
!p.multi=0


return, NEW_STRUCT
 
end