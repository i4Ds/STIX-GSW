;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_sim_ospex_demo
;
; PURPOSE:
;    Simulates STIX spectra of a flare event using RHESSI data in STIX energy binning and the STIX DRM
;           
;
; CATEGORY:
;       SIMULATION, SPECTRA, X-ray analysis
;
; CALLING SEQUENCE:
;    stx_sim_event,filename=filename, peaktime=peaktime, plotint=plotint, objname=objname,seed1=seed1,noplot=noplot,nosave=nosave,folder=folder,_extra=_extra
;       
;
; HISTORY:
;       
;       29-Apr-2013 - ines.kienreich@uni-graz.at (INK)
;-

;+

;+
; :description:
;   Wrapper program used in combination with stx_calc_spex_user_data.pro to simulate STIX spectra 
;   and compare it with the RHESSI spectra, which were taken as starting point.
;   It is imperative to first analyze the chosen flare event with the HESSI GUI and OSPEX GUI
;   using the STIX energy binning. A text file (STIX_intervals.txt)containing STIX energy bins is provided,
;   which can be loaded into the HESSI GUI and OSPEX GUI. The program needs both the OSPEX results fits file 
;   and OSPEX script file as input to set all parameters correctly. 
;   stx_sim_event calls routines, which calculate the RHESSI photons, the STIX DRM and finally the STIX counts
;   and returns a structure, which is subsequently passed to stx_calc_spex_user_data to further calculate the 
;   STIX photon flux using the OSPEX GUI.

;
; :keywords:
;	NOPLOT     - if set, then no interim plots are shown
;	NOSAVE     - if set, then no interim results are stored
;   
; :params:
;       FILENAME   - ospex file to be loaded into the program (IMPORTANT: set obj = ospex(/no_gui) in OSPEX file !!!)
;       PEAKTIME   - peak time of the event in format 'yyyy-mm-dd hh:mm:ss.xxx' (from RHESSI info)
;       OBJNAME    - name of your object
;       PLOTINT    - index of time-interval user wants to be plotted; integer
;	FOLDER	   - name of the folder to store the interim results; e.g. '/homedir/STIX/savfiles/'
;	seed1      - number of seed for poidev to reconstruct Poisson noise
;
; :returns:
;    Does not return anything per se, but subroutines return structures, which are stored in save files, if the
;    keyword /nosave is NOT set and FOLDER is given
;
;-


;
;
; examples:

;stx_sim_ospex_demo,filename='ospex_script_event20020220_4F_16032013nogui',peaktime='2002-02-20 11:06:58.000',objname='obj' 

;stx_sim_ospex_demo,filename='ospex_script_event20020220_4F_16032013nogui',peaktime='2002-02-20 11:06:58.000',objname='obj',/noplot,/nosave 

;stx_sim_ospex_demo,filename='ospex_script_event20020220_4F_16032013nogui',peaktime='2002-02-20 11:06:58.000',$
;objname='obj',folder='/home/ink/STIX/try/'

;***********************************************************************************

pro stx_sim_ospex_demo,filename=filename, peaktime=peaktime, plotint=plotint, objname=objname,seed1=seed1,noplot=noplot,nosave=nosave,folder=folder,_extra=_extra

if not keyword_set(folder) AND not keyword_set(nosave) then begin

	print, 'Do you want to save interim results?: Yes (y), No (n)'
	b=''
	read, b,prompt='YES(y)/NO(n):'
	if (b eq 'y') then begin
	print, 'Files stored in current directory:'
	  cd, current=curdir
	  print, curdir
	  folder=curdir
	  ;outdireit = curdir+'eit/'+date+'_spec/'
	  ;if (file_exist(outdireit) eq 0) then spawn, 'mkdir ' + outdireit

	endif else begin
	  print, 'No files will be saved!'
	  nosave=nosave
	endelse
endif


print, filename
print, peaktime
p_time = anytim(peaktime)
print, objname


CALL_PROCEDURE, filename, obj=objname

s = objname->get(/spex_summ)
in = objname->get(/info)

  sz_time_interval = size(in.SPEX_SUMM_TIME_INTERVAL) 
  
  intv1 = where (anytim(peaktime) ge anytim(in.SPEX_SUMM_TIME_INTERVAL[0,*]) AND $
              anytim(peaktime) le anytim(in.SPEX_SUMM_TIME_INTERVAL[1,*])) 

  
  if not keyword_set(plotint) then begin
     intv =  intv1  
  endif else begin
   if (plotint ge 0 AND  plotint lt sz_time_interval[2]-1) then begin
  	intv = plotint 
   endif else begin
   	intv =  intv1
   endelse
  endelse
  print, intv

  sz_en_interval = size(in.SPEX_SUMM_ENERGY)     
  
;*************************************************************************************
  

print,' '
print,' '
print, '************************************************'
print, '*'
print, '*          INFO'
print, '*'
print, '************************************************'
print,' '
print, 'Total Chosen Time Range:'
ptim,in.SPEX_FILE_TIME
print, 'Used Time Interval for Fit: '
ptim,[in.SPEX_SUMM_TIME_INTERVAL[0,0],in.SPEX_SUMM_TIME_INTERVAL[1,sz_time_interval[2]-1]]
print,' '
delta_t = in.SPEX_SUMM_TIME_INTERVAL[1,0] - in.SPEX_SUMM_TIME_INTERVAL[0,0]
print, 'no. of subintervals: '+string(sz_time_interval[2],format='(I2.2)')+' of length '+ string(delta_t,format='(I2.2)')+'s'
print,' '
print, 'Peak Time: '+peaktime+' (Interval '+string(intv,format='(I2.2)')+ ')'
print,' '
;print, 'Energy Range: [',in.SPEX_SUMM_ENERGY[0,0],', ',in.SPEX_SUMM_ENERGY[1,sz_en_interval[2]-1],'] keV'
print,format='(2(a,f7.3),a)','Energy Range: [',in.SPEX_SUMM_ENERGY[0,0],', ',in.SPEX_SUMM_ENERGY[1,sz_en_interval[2]-1],'] keV'
print,' '
print,'Detectors: '+in.SPEX_DETECTORS
print,' '
print,'Used Fit Functions: '+in.SPEX_SUMM_FIT_FUNCTION
print,'Chianti Version: '+in.SPEX_SUMM_CHIANTI_VERSION
print,' '
print, '************************************************'
print, '*'
print, '************************************************'
print,' '


;*************************************************************************************
                   

help, objname
;ebgband = objname->get(/spex_bk_eband)
;d = objname -> getdata(class='spex_fitint')

enspex = s.spex_summ_energy

ebin_flux = objname->getdata(class='spex_data',spex_units='flux')
;win = objname->getaxis(/ct_energy,/width)
;ct_edges2 = objname->get(/spex_ct_edges)

;ct_edges2 = s.spex_summ_energy

edge_products,enspex,edges_2=ct_edges2,mean=emean,width=win

ct_edges1 = get_edges(s.spex_summ_energy,/edges_1)


sz_dat = size(ebin_flux.data)
dummy1 = fltarr(5,sz_dat[2])
 for i = 0,sz_dat[2]-1 do begin
  dummy1[0,i] = total(ebin_flux.data[0:7,i]*win[0:7])/total(win[0:7])
  dummy1[1,i] = total(ebin_flux.data[8:17,i]*win[8:17])/total(win[8:17])
  dummy1[2,i] = total(ebin_flux.data[18:22,i]*win[18:22])/total(win[18:22])
  dummy1[3,i] = total(ebin_flux.data[23:28,i]*win[23:28])/total(win[23:28])
  dummy1[4,i] = total(ebin_flux.data[29:31,i]*win[29:31])/total(win[29:31])
endfor

ti = objname->getaxis(/ut,/mean)
beg = anytim(ti[0],/vms)
ti_diff = ti-ti[0]

;help, eband_flux
;help, ti

;*************************************************************************************

 
if not keyword_set(noplot) then begin

wdef, window_lu, free=~exist( window_lu ),400,600
    ;window,0,xsize=400,ysize=600
  !p.multi=0
	objname->plot_time,/data, spex_units='flux',/no_plotman,/xst;,yrange=[1.e-4,10.];,_extra=_extra

wh = where(dummy1 gt 0.)
yr = minmax(dummy1[wh])

wdef, window_lu, free=~exist( window_lu ),400,600
; window,2,xs=400,ys=600

	utplot,ti_diff,dummy1[0,*],/nodata,beg,ytitle='counts s!U-1!n cm!U-2!n keV!U-1!n',$
	title='SPEX HESSI Count Flux vs Time',/xst,/ylog,yrange=yr;/yst,yrange=[1.d-4,10.]
	linecolors
	outplot,ti_diff,dummy1[0,*],col=255
	outplot,ti_diff,dummy1[1,*],col=3

	outplot,ti_diff,dummy1[2,*],col=7
	outplot,ti_diff,dummy1[3,*],col=9
	outplot,ti_diff,dummy1[4,*],col=5

	 xyouts,0.18,0.93,'Detectors'+in.SPEX_DETECTORS,charsize=1.1,/norm
	 xyouts,0.18,0.9,'__',charsize=1.1,col=255,/norm
	 xyouts,0.25,0.9,'4.0 to 12.0 keV (Data with Bk)',charsize=1.1,/norm
	 xyouts,0.18,0.87,'__',charsize=1.1,col=3,/norm
	 xyouts,0.25,0.87,'12.0 to 25.7 keV (Data with Bk)',charsize=1.1,/norm
	 xyouts,0.18,0.84,'__',charsize=1.1,col=7,/norm
	 xyouts,0.25,0.84,'25.7 to 48.3 keV (Data with Bk)',charsize=1.1,/norm
	 xyouts,0.18,0.81,'__',charsize=1.1,col=9,/norm
	 xyouts,0.25,0.81,'48.3 to 102.8 keV (Data with Bk)',charsize=1.1,/norm
	 xyouts,0.18,0.78,'__',charsize=1.1,col=5,/norm
	 xyouts,0.25,0.78,'102.8 to 150 keV (Data with Bk)',charsize=1.1,/norm


	print,'Press any key to continue'

	x = get_kbrd(1)

endif

!p.multi=0

;*************************************************************************************

print, 'CALLING stx_hessi_photons_calc to calculate RHESSI PHOTONS'

 
stx_hessi_photons_calc,obj=objname,intv=intv,phot_struct,noplot=noplot,_extra=_extra


help, phot_struct
str11=anytim(ti[0],/CCSDS,/date_only)
remchar, str11, '-'

if not keyword_set(nosave) then $
save,phot_struct,filename=str11+'_RHESSI_photons.sav'

 
	print,'Press any key to continue'

	x = get_kbrd(1)

;*************************************************************************************

print, 'CALLING stx_calc_drm to calculate STIX DETECTOR RESPONSE MATRIX'

stx_drm = stx_build_drm(ct_edges1)

help, stx_drm
help, stx_drm.smatrix

;; parameter:

;detector='cdte' 		; Cadmium-Telluride
;area = 1.			; detector geometric area in cm^2
;func='stx_fwhm'			; returns FWHM in keV
;func_par= [1.2, .01, 0.0,0.0]	; vector for func
;d=0.1				; detector thickness in cm
;z=13				; atomic number of elements in detector window
;gmcm=.27			; thickness of each element in grams per cm2
				; (gmcm = 0, if no window is assumed)

;edges_in = ct_edges1
;edges_out = edges_in


;resp_calc, detector, area, func, func_par, d, z, gmcm, nflux, elo, ehi, $
;eloss_mat, pls_ht_mat, ein, smatrix, edges_in=edges_in, edges_out=edges_out


;;output:

;;EIN		channel energy edges for photon input
;;ELOSS_MAT	energy loss matrix
;;PLS_HT_MAT	pulse-height response matrix (ELOSS_MAT convolved with energy resolution broadening)
;;SMATRIX	detector response matrix;
;;                     = PLS_HT_MAT normalized to 1/keV

;drm_info=[['DRM calculated with resp_calc. smatrix is DRM (counts/keV/photons)'],$
;         ['pls_ht_mat is DRM (counts/photons) NOT normalized, eloss_mat is Energy Loss Matrix, NO response broadening'],$
;         ['ein...2D energy array, edges_in...1D energy array']]


;help, smatrix

;stx_drm =      {detector:detector,$
;		area:area,$
;		func:func,$
;		func_par:func_par,$
;		d:d,$
;		z:z,$
;	gmcm:gmcm,$
;		nflux:nflux,$
;		eloss_mat:eloss_mat,$
;		pls_ht_mat:pls_ht_mat, $
;		e_2D:ein,$ 
;		smatrix:smatrix,$ 
;		edges_in:edges_in,$
;		edges_out:edges_out,$
;		emean:emean,$
;		ewidth:win,$
;		info:drm_info}

if not keyword_set(nosave) then $
save,stx_drm,filename=str11+'_STIX_drm.sav'


	print,'Press any key to continue'

	x = get_kbrd(1)

;*************************************************************************************

; CALLING stx_counts_calc to calculate STIX COUNTS

;stop

stx_counts_calc,obj=objname, phot_struct=phot_struct, stx_drm=stx_drm,intv=intv,seed1=seed1, stx_ct_struct, noplot=noplot,_extra=_extra



save,stx_ct_struct,filename=str11+'_STIX_counts.sav'

;*************************************************************************************


print,'Press any key to continue'
x = get_kbrd(1)
;stop
end