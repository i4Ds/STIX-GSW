;---------------------------------------------------------------------------
; Document name: stx_img_spectra_info__define.pro
;---------------------------------------------------------------------------
;
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_img_spectra_info__define
;
; PURPOSE: 
;       
;
; CATEGORY:
;       
; 
; CALLING SEQUENCE:
;       
;       var = {stx_img_spectra_info} 
;
; SEE ALSO:
;       
;       
;
; HISTORY:
; Created by:  rschwartz70@gmail.com
;
; Last Modified: 14-jun-2014
;   9-jul-2014, ras, added 
;
;-
;


PRO stx_img_spectra_info__define


struct = {stx_img_spectra_info, $
          boundary_grid: ptr_new(), $  ut_edges x energy_edges, for all ut_edges and energy_edges make
          ;an num ut x num energy grid.  If there is a box boundary for that ut_edge, the value is 1, 0 otherwise
          ;valid_spectra_grid: ptr_new(), $
          ut_edge: ptr_new(), $ unique ut img box boundaries
          mod_img: ptr_new(), $ modified img structures. img with added tags, maybe missing time/energy boxes
          energy_edge: ptr_new(), $ unique energies for img box boundaries
          index_erange: lonarr(2) $
         }

END


;---------------------------------------------------------------------------
; End of 'stx_img_spectra_info__define.pro'.
;---------------------------------------------------------------------------
