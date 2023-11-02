;+
; Description :
;   Function to read STIX L1 housekeeping data from a FITS file and return an array of structures
;   with the format stx_aspect_dto (see https://github.com/i4Ds/STIXCore/issues/200 )
;
; Syntax      : data = prepare_aspect_data(infile [, /quiet] )
;
; Inputs      : 
;     infile  = input file name, including full absolute path
;
; Output      : an array of data structure stx_aspect_dto
; 
; Optional keyword:
;     quiet  = if set, don't display information messages
;     
; History   :
;   2019-12-12 - F. Schuller (AIP), initial version of read_SAS_data
;   2022-01-27 - FSc (AIP): adapted from read_hk_data
;   2022-02-15, FSc: update for changes of times in FITS files (32-bit integer, in unit of ds)
;
; Example:
;   data = prepare_aspect_data('/path_to_L1_files/solo_L1_stix-hk-maxi_20210914_V01.fits')
;
;-

function prepare_aspect_data, infile, quiet=quiet

  if n_params() lt 1 then message,'  SYNTAX: prepare_aspect_data, infile [, /quiet]

  ; First, verify that the file exists
  if strmid(infile,strlen(infile)-5,5) ne '.fits' then infile = infile + '.fits'  
  result = file_test(infile)
  if not result then begin
    print,"ERROR: File "+infile+" not found."
    return,0
  endif

  ; read file content: Primary header
  dummy = mrdfits(infile,0,primary,/silent)
  utc_0 = sxpar(primary, 'DATE-BEG')
  utc_end = sxpar(primary, 'DATE-END')

  ; read file content: data table
  tbl = mrdfits(infile,2,head,/silent)   ; binary table in Extension #2
  nb_rows = n_elements(tbl)
  if not keyword_set(quiet) then begin
    msg = string(nb_rows,format='("Input data file contains ",I5," entries, ")')
    msg += string(utc_0,utc_end,format='("from ",A23," to ",A23)')
    print,msg
  endif

  ; Convert start time (UTC string) to number...
  time_0 = anytim(utc_0, /tai)  ; need TAI to convert back to string with anytim2utc
  ; ... and build the array of absolute times
  ; res_times = time_0 + tbl.time
  ; Changed 2022-02-15 (new column format and unit in FITS files)
  times_wrong = tbl.time     ; wrong because for some reason, IDL sets the 1st bit to 1 but should be 0
  bin0 = times_wrong[0] - 1  ; this is 0b01111111111111111111111111111111
  times_ok = times_wrong AND bin0    ; sets the 1st bit to 0
  ; res_times = time_0 + times_ok/10.  ; convert ds to seconds
  res_times = time_0 + times_ok/100.  ; was changed to cs some time in March 2022
  
  ; compute array of "integration times"
  duration = res_times[1:-1] - res_times[0:-2]
  duration = [duration, duration[-1]]  ; assume that last point has same duration as previous one
  ; convert back to UTC strings
  UTC_str = anytim2utc(res_times, /ccsds, /truncate)
  ; get array of positions of SolO with respect to the Sun
  solo_pos = get_sunspice_lonlat(UTC_str,'SOLO')
  ; then the solar disc size (radius) is (in arcsec):
  solrad_m = 6.9566e8   ; solar radius [m]
  r_sol = solrad_m / (solo_pos[0,*]*1.e3) * 180./!pi * 3600.
  
  ; Loop through the rows to build an array of data structures
  for i=0,nb_rows-1 do begin
    a =  {stx_aspect_dto, $
          cha_diode0: tbl[i].hk_asp_photoa0_v, cha_diode1: tbl[i].hk_asp_photoa1_v, $
          chb_diode0: tbl[i].hk_asp_photob0_v, chb_diode1: tbl[i].hk_asp_photob1_v, $
          time: utc_str[i], $
           scet_time_c: 0LL, scet_time_f: 0LL, $
          duration : duration[i], spice_disc_size : r_sol[i], $
          y_srf : 0.0, z_srf : 0.0, calib : 0.0,  sas_ok : 1, error : "", $
          control_index: 0LL, parentfits: 0LL}
    if i eq 0 then result = [a] else result = [result, a]
  endfor

  return,result
end
