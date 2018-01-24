;---------------------------------------------------------------------------
; Document name: stx_img_spectra_control__define.pro
;---------------------------------------------------------------------------
;
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_img_spectra_control__define
;
; PURPOSE: 
;       
;
; CATEGORY:
;       
; 
; CALLING SEQUENCE:
;       
;       var = {stx_img_spectra_control} 
;
; SEE ALSO:
;     stx_img_spectra_control() for a more complete description of the tags in struct.  
;       
;
; HISTORY:
; Created by:  rschwartz70@gmail.com
;
; Last Modified: 14-jun-2014
;
;-
;
pro stx_img_spectra_control__define

struct = {stx_img_spectra_control, $
          img: ptr_new(), $      
          erange: fltarr(2) $  
         }
end


;---------------------------------------------------------------------------
; End of 'stx_img_spectra_control__define.pro'.
;---------------------------------------------------------------------------
