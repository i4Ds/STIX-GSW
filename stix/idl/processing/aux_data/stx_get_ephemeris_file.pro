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
; :returns:
;   Filename of the first Auxiliary Ephemeris FITS file for the given time period 
;
; :examples:
;    stx_get_ephemeris_file, '09-May-23 06:14:37.094', '09-May-23 06:36:12.194'
;
; :history:
;    11-Sep-2023 - ECMD (Graz), initial release
;
;-
function stx_get_ephemeris_file, start_time, end_time
 
  site = 'http://dataarchive.stix.i4ds.net'
  type_path = '/fits/L2/'
  date_path = get_fid(start_time,end_time,/full,delim='/')

  path  = type_path + date_path[0] +'/AUX'
  filter = '*stix-aux-ephemeris*.fits'

  found_files=sock_find(site,filter,path=path,count=count)
 
  if count ne 0 then begin
    selected_file = found_files[0]
    sock_copy, selected_file
    break_url, selected_file, servers, paths, out_file
  endif else message, 'STIX AUX Ephemeris file not found.'

  return, out_file
end