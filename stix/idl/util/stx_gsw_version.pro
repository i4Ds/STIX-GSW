;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_gsw_version
;
; :description:
;    This function is a way of determining update status of the STIX IDL Ground Software repository.
;
; :categories:
;    util
;
; :returns:
;    a string giving the STIX IDL Ground Software version.
;
; :examples:
;    version = stx_gsw_version()
;
; :history:
;    24-Feb-2022 - ECMD (Graz), initial release
;    31-Mar-2022 - ECMD (Graz), Changed from date to version number
;
;-
function stx_gsw_version

  version_file = loc_file( 'VERSION.txt', path = getenv('SSW_STIX'))
  readcol, version_file, current_version, format = 'a', /silent

  version_string = 'The current STIX Ground Software version is - ' + current_version
  print, version_string

  return, current_version
end