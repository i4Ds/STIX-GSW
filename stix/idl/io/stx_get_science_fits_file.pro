;+
;
; name:
;       stx_get_science_fits_file
;
; :description:
;    This procedure downloads an L1 science fits file corresponding to a specific ID
;
; :categories:
;    template, example
;
; :params:
;   file_id: string containing the unique ID of the L1 fits file to be downloaded
;
; :keywords
;   out_dir: path of the folder where the L1 fits file is saved. Default is the current directory
;
;   clobber: 0 or 1. If set to 0, the code does not download the file again if it is already present in 'out_dir'.
;
; :returns:
;   Path of the L1 science fits file corresponding to a specific ID 
;
; :examples:
;   out_file = stx_get_science_fits_file("1178428688")
;
; :history:
;    18-Sep-2023 - Massa P. (WKU), initial release
;
;-
function stx_get_science_fits_file, file_id, out_dir=out_dir, clobber=clobber

  cd, current=current

  default, out_dir, current
  default, clobber, 0

  site = 'https://datacenter.stix.i4ds.net'
  path = '/download/fits/bsd/'
  
  sock_copy, site + path + file_id, out_name, local_file=out_file, out_dir = out_dir, clobber=clobber, status=status
  
  if status eq 0 then message, 'File ID ' + file_id + ' does not exist.'

  return, out_file
end