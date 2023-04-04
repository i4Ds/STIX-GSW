;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_check_fits_compatibility
;
; :description:
;    This function checks the processing level of a given FITS file for compatibility with the
;    current software version
;
; :categories:
;    fits, io
;
; :params:
;    fits_path : in, required, type="string"
;                Path to STIX L1 FITS file to be checked
;
; :returns:
;    1 if FITS file passes compatibility check, 0 if file does not
;
; :examples:
;      compatible  = stx_check_fits_compatibility( fits_path )
;
; :history:
;    28-Mar-2023 - ECMD (Graz), initial release
;                               GSW Version 0.4.0 is compatible only with L1 files released 2023-03-28
;
;-
function stx_check_fits_compatibility, fits_path

  fits_data = mrdfits( fits_path, 0, primary_header, silent = silent, /unsigned )

  processing_level = sxpar(primary_header,'level')

  creation_date = sxpar(primary_header,'date')
  release_date = '2023-03-28T00:00:00'

  compatible = ~(strcompress(processing_level,/remove_all) eq 'L1A') and $
    (anytim(creation_date) ge anytim(release_date)) ? 1 : 0

  break_file, fits_path, disk_log, dir, filnam, ext, fversion, node

  if ~compatible then begin
    message,'WARNING: The current file : '+ FILNAM, /con
    message,'is not currently supported, we recommend downloading the latest L1 file.', /con
    control = mrdfits( fits_path, 'control', control_header, /silent, /unsigned )
    if have_tag(control,'request_id')  then begin
      uid = strtrim(control.request_id, 2)
      message,'Available at:                      ',/cont
      message,'https://datacenter.stix.i4ds.net/download/fits/bsd/'+uid
    endif else begin
      message,'Available at:                      ',/cont
      message,'http://dataarchive.stix.i4ds.net/fits/'
    endelse
  endif

  return, compatible
end
