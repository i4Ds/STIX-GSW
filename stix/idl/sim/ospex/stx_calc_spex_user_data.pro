;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_calc_spex_user_data
;
; PURPOSE:
;    	supplies the non RHESSI standard STIX counts array, the STIX energy edges and the STIX DRM to OSPEX, 
;	sets several parameters and calls the OSPEX GUI           
;
; CATEGORY:
;       helper method
;
; CALLING SEQUENCE:
;    IDL> stx_calc_spex_user_data, obj=ostix, stx_ct_struct=stx_ct_struct, noise=noise, data=data
;
; HISTORY:
;       
;       29-Apr-2013 - ines.kienreich@uni-graz.at (INK)
;-
;+
; :description:
; 	wrapper program, which supplies the non-standard STIX count spectrum array, the STIX energy edges and the STIX DRM to OSPEX,	 
; 	sets all required parameters and finally calls the OSPEX GUI. In this version the STIX background is set to 0.
; 	From this point on the user works with the OSPEX GUI, and performs the spectral fitting to the STIX data count spectra.
; 	The OSPEX script file and fits file have to be stored as they are needed for the following program stx_photon_flux_diff_calc. 	
; 	This program has to be run twice, one time for the original STIX data and the second time for the noisy STIX data. The fits and
;	script files should be named accordingly.
; 	
;
; :keywords:
;	NOISE	- if set, then STIX counts with Poisson noise are taken; 
;	DATA	- if set, then STIX counts derived from RHESSI data and not RHESSI fits are taken
;   
; :params:
;       OBJNAME		- name of the OSPEX object
;  	stx_ct_struct	- name of the structure containing the STIX counts
;   
; :returns:
;     ------
;    
;-


pro stx_calc_spex_user_data, obj=ostix, stx_ct_struct=stx_ct_struct, noise=noise, data=data                                          


if not is_class(ostix,'SPEX',/quiet) then ostix = ospex()                                       


if not keyword_set(noise) then begin

       ;print, 'one'
       stx_cts_1cm = (keyword_set(data)) ? stx_ct_struct.stx_cts0 : stx_ct_struct.stx_cts 
       ;help, stx_ct_struct.stx_cts
       ;help, stx_cts_1cm
       
endif else begin
       ;print, 'two'

       stx_cts_1cm = (keyword_set(data)) ? stx_ct_struct.poi_counts0 : stx_ct_struct.poi_counts

endelse

livetime_array = stx_ct_struct.phot_struct.data_ct.ltime
help, livetime_array
enspex = stx_ct_struct.enspex 
spexutedg = stx_ct_struct.phot_struct.s.SPEX_SUMM_TIME_INTERVAL

;stx_ct_struct ={stx_cts0:stx_cts0,$
;		stx_cts:stx_cts,$
;		stx_cts1:stx_cts1,$
;		interim0:interim0,$
;		interim:interim,$
;		interim1:interim1,$
;		stx_ct_flux0:stx_ct_flux0,$
;		stx_ct_flux:stx_ct_flux,$
;		stx_ct_flux1:stx_ct_flux1,$
;		enspex:enspex,$
;		ct_edges1:ct_edges1,$
;		emean:emean,$
;		win:win,$
;		phot_struct:phot_struct,$
;		stx_drm:stx_drm, $
;		poi_counts:poi_counts,$
;		poi_counts0:poi_counts0,$
;		poi_counts1:poi_counts1}
;	

ostix -> set, spex_data_source = 'SPEX_USER_DATA'
ostix -> set, spectrum = stx_cts_1cm,livetime = livetime_array;  $	; spectrum_array  [32,33]
ostix -> set, spex_ct_edges = enspex	; STIX energy edges  array [2,32]
ostix -> set, spex_eband= get_edge_products([4,12,25.728,48.291,102.806,150],/edges_2);

ostix -> set, spex_ut_edges =spexutedg  ; time edges of spectrum_array
    						    ;errors = error_array, $	; not set in this case
              	; taken from RHESSI file

ostix -> set, spex_respinfo= stx_ct_struct.STX_DRM.SMATRIX    ; sets all elements of 2-D DRM to .SMATRIX
ostix -> set, spex_area=1.
ostix -> set, spex_detectors='stix_detector'; 
ostix -> set, spex_title='STIX SPECTRUM'


datapos1 = stx_ct_struct.phot_struct.in.spex_data_pos 


ostix -> set, spex_data_pos=datapos1; 


s_stix0 = ostix->get(/spex_summ)

in_stix0 = ostix->get(/info)


print, in_stix0.SPEX_DATA_UNITS.DATA_NAME

interim_st = in_stix0.SPEX_DATA_UNITS
interim_st.DATA_NAME='STIX'

ostix->set, SPEX_DATA_UNITS=interim_st
in_stix0 = ostix->get(/info)
print, in_stix0.SPEX_DATA_UNITS.DATA_NAME


interim_st = in_stix0.SPEX_DATA_ORIGUNITS
interim_st.DATA_NAME='STIX'

ostix->set, SPEX_DATA_ORIGUNITS=interim_st
in_stix0 = ostix->get(/info)
print, in_stix0.SPEX_DATA_ORIGUNITS.DATA_NAME

datstix = ostix->getdata()

ostix->set,spex_bk_sep=1
ostix->set,spex_bk_order=[0,0,0,0,0]

spexutedg = stx_ct_struct.phot_struct.s.SPEX_SUMM_TIME_INTERVAL

ti = anytim([spexutedg[0,0],spexutedg[0,0]+1],/VMS)


ostix->set,this_band=0,this_time=ti
ostix->set,this_band=1,this_time=ti
ostix->set,this_band=2,this_time=ti
ostix->set,this_band=3,this_time=ti
ostix->set,this_band=4,this_time=ti

s_stix = ostix->get(/spex_summ)
in_stix = ostix->get(/info)

end