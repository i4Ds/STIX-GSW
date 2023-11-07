;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_get_mrd_version
;
; :description:
;    This function is a wrapper for the mrdfits utility function  mrd_version
;
; :categories:
;    FITS 
;
; :returns:
;    a string giving the currently compiled version of mrdfits 
;
; :examples:
;    version = stx_get_mrd_version()
;
; :history:
;    22-Feb-2022 - ECMD (Graz), initial release
;
;-
function stx_get_mrd_version 

resolve_routine, 'mrdfits', /qu, /either, /compile_full_file

 mversion_full = mrd_version()

return, mversion_full
end