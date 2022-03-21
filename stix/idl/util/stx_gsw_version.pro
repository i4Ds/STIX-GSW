;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_gsw_version
;
; :description:
;    This function is a way of determining update status of the STIX IDL Ground Software repistiory. 
;
; :categories:
;    util 
;
; :returns:
;    a string giving the date the STIX IDL Ground Software was last updated.
;
; :examples:
;    date = stx_gsw_version()
;
; :history:
;    24-Feb-2022 - ECMD (Graz), initial release
;
;-
function stx_gsw_version 

date_updated = '16-Mar-2022'

version = 'The STIX IDL Ground Software was last updated on - ' + date_updated

return, date_updated
end