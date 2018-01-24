;---------------------------------------------------------------------------
;+
; project:
;       STIX
;
; :name:
;       stx_spcivs2spectrogram
;       
; :purpose:
;       Takes a STIX interval selection output structure and converts it into a regular spectrogram ;    
;
; :category:
;       
;       
; :description:
;       Uses the sum_time_groups method of the stx_img_spectra object to convert the STIX spectrum archive buffer 
;        from the interval selection algorithm into a regularly gridded spectrogram
;  
; :params:
;       ivs - stx_fsw_ivs_result structure
;       
; :keywords:
;       none
;                 
; :returns:
;       Returns the structure spect_struct containing the regular grid spectrogram 
;       
; :calling sequence:
;       IDL> spectrogram = stx_spcivs2spectrogram( ivs )
;       
; :history:
;       23-Sep-2014 – ECMD (Graz) 
;       12-Dec-2014 – ECMD (Graz), Now depreciated in favour of stx_l1_spc_ivs2spectrogram.pro
;-

function stx_spcivs2spectrogram, ivs 

;get the level 1 spectrometry interval archive
l1=ivs.l1_spc_combined_archive_buffer_grouped.toarray()

;convert ivs l1 spc archive output into stx_ivs_interval structure
img = stx_spc_l1_archive2ivs(l1.intervals,start_time=l1.start_time)

;create imaging spectra object which will be used to process the spectrogram
simg = obj_new( 'stx_img_spectra' )

;convert the ivs output to pointer format expected by stx_img_spectra set method
pimg = ptr_new( img )

;set spectrogram and energy range in the imaging spectra object from ivs interval
simg->set, img = pimg, erange=[ min( img.start_energy ), max( img.end_energy ) ]

;calculation of the spectrogram structure using the sum_time_groups method
spect_struct = simg->sum_time_groups( /mk_struct )

return, spect_struct
end
