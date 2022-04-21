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
; :keywords:
;    version : out, type="string"
;              a string giving the STIX IDL Ground Software version.
;               
;    silent : in, type="boolean"
;             if set the version string will not be printed to screen.
;    
; :examples:
;    stx_gsw_version, version = version 
;
; :history:
;    24-Feb-2022 - ECMD (Graz), initial release
;    31-Mar-2022 - ECMD (Graz), Changed from date to version number
;    21-Apr-2022 - ECMD (Graz), Changed routine from function to procedure
;
;-
pro stx_gsw_version, version = version, silent = silent

  version_file = loc_file( 'VERSION.txt', path = getenv('SSW_STIX'))
  readcol, version_file, version, format = 'a', /silent

  version_string = 'The current STIX Ground Software version is - ' + version
  if ~keyword_set(silent) then print, version_string

end