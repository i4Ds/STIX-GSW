;+
;
; name:
;       stx_get_ephemeris_file
;
; :description:
;    This procedure checks the STIX data archive for a given observation time and finds any
;    STIX AUX Ephemeris files. If present the first file is dowloaded and the filename returned.
;    NOTE: Due to current limitations only a single Ephemeris file can be handled. This procedure
;    returns the first valid value. For most observations the file corresponding to the start date
;    is all that is needed.
;
; :categories:
;    template, example
;
; :params:
;    start_time : in, required, type="string"
;                the start time of the observation
;    end_time : in, required, type="string"
;                the end time of the observation
; 
; :keywords
;   out_dir: path of the folder where the Auxiliary Ephemeris FITS files are saved. Default is the current directory
;   
;   clobber: 0 or 1. If set to 0, the code does not download the file again if it is already present in 'out_dir'.
;
; :returns:
;   Path of the first Auxiliary Ephemeris FITS file for the given time period
;
; :examples:
;    out_file = stx_get_ephemeris_file('09-May-23 06:14:37.094', '09-May-23 06:36:12.194')
;
; :history:
;    11-Sep-2023 - ECMD (Graz), initial release
;    18-Sep-2023 - Massa P. (WKU), added 'out_folder' and 'clobber' keywords
;    25-Nov-2024 - F. Schuller (AIP): update to search for new ANC file names
;
;-
function stx_get_ephemeris_file, start_time, end_time, out_dir=out_dir, clobber=clobber

  cd, current=current
  
  default, out_dir, current
  default, clobber, 0

  site = 'http://dataarchive.stix.i4ds.net'
  date_path = get_fid(start_time,end_time,/full,delim='/')

  type_path = '/fits/ANC/'
  path  = type_path + date_path[0] +'/ASP'
  filter = '*stix-asp-ephemeris*.fits'
  found_files=sock_find(site,filter,path=path,count=count)

  if count eq 0 then begin
    ; try the previous naming convention - TEMPORARY FIX, should be removed at some point
    type_path = '/fits/L2/'
    path  = type_path + date_path[0] +'/AUX'
    filter = '*stix-aux-ephemeris*.fits'
    found_files=sock_find(site,filter,path=path,count=count)
  endif

  if count ne 0 then begin
    selected_file = found_files[0]
    sock_copy, selected_file, out_name, local_file=out_file, out_dir = out_dir, clobber=clobber
  endif else message, 'STIX AUX Ephemeris file not found.'
  
  return, out_file
end
