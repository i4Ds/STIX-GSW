;+
; Description :
;   Function to read STIX L1 housekeeping data and return an object containing signals from Aspect system
;
; Syntax      : data = read_hk_data(infile [, /quiet] )
;
; Inputs      : input file name
;
; Output      : a data structure that contains:
;                 result.UTC     = UTC timestamps as string 
;                 result.Times   = timestamps (in TAI) as double floating point values
;                 result.signal  = SAS raw signals (4*N 2D array)
;                 result.Primary = unmodified copy of the primary header from input file
;
; Optional keyword:
;     quiet  = if set, don't display information messages
;     
; History   :
;   2019-12-12 - F. Schuller (AIP), initial version of read_SAS_data
;   2021-06-16 - FSc: adapted to L1 HK datafiles, and standalone SAS_pipeline package
;   2021-08-09 - FSc: renamed from read_l1_data to read_hk_data
;   
; Example:
;   data = read_hk_data('SAS_20210212-20210215')

;-

function read_hk_data, infile, quiet=quiet
  common config   ; contains the input directory

  ; First, verify that the file exists
  full_name = data_dir + infile
  if strmid(full_name,strlen(full_name)-5,5) ne '.fits' then full_name = full_name + '.fits'  
  result = file_test(full_name)
  if not result then begin
    print,"ERROR: File "+full_name+" not found."
    return,0
  endif

  ; read file content: Primary header
  dummy = mrdfits(full_name,0,primary,/silent)
  utc_0 = sxpar(primary, 'DATE_BEG')
  utc_end = sxpar(primary, 'DATE_END')

  ; read file content: data table
  tbl = mrdfits(full_name,2,head,/silent)   ; binary table in Extension #2
  nb_rows = n_elements(tbl)
  if not keyword_set(quiet) then begin
    msg = string(nb_rows,format='("Input data file contains ",I5," entries, ")')
    msg += string(utc_0,utc_end,format='("from ",A23," to ",A23)')
    print,msg
  endif

  ; Convert start time (UTC string) to number...
  time_0 = anytim(utc_0, /tai)  ; need TAI to convert back to string with anytim2utc
  ; ... and build the array of absolute times
  res_times = time_0 + tbl.time
  
  ; compute array of "integration times"
  duration = res_times[1:-1] - res_times[0:-2]
  duration = [duration, duration[-1]]  ; assume that last point has same duration as previous one
  ; select only data where duration = 64s
  tmp64 = where(abs(duration - 64.) lt 0.1,nb_64)    ; allow for some rounding error
  if nb_64 eq 0 then begin
    print,"ERROR: no valid data in File "+full_name
    return,0
  endif

  ; extract and normalise the four signals from the FITS table
  asp_A0 = tbl.hk_asp_photoa0_v  &  asp_A1 = tbl.hk_asp_photoa1_v
  asp_B0 = tbl.hk_asp_photob0_v  &  asp_B1 = tbl.hk_asp_photob1_v

  ; convert voltages to current
  ; according to K. Rutkowski's e-mail (2020-04-03)
  V_base = 0.06018  ; [V]
  R_m = 51100.      ; [Ohmn]
  ; keep only measurements at 64s cadence
  ind_ok = where(abs(duration-64.) lt 0.1,nb_ok)
  
  if nb_ok lt nb_rows and not keyword_set(quiet) then $
    print,nb_ok,format='("... keeping only ",I5," entries.")'
  asp_A0 = asp_A0[ind_ok] / 16. &  asp_A1 = asp_A1[ind_ok] / 16.  
  asp_B0 = asp_B0[ind_ok] / 16. &  asp_B1 = asp_B1[ind_ok] / 16.

  ; channel A
  asp_A0 = (asp_a0 - V_base) / R_m
  asp_A1 = (asp_a1 - V_base) / R_m
  ; channel B
  asp_B0 = (asp_b0 - V_base) / R_m
  asp_B1 = (asp_b1 - V_base) / R_m

  if nb_ok eq 0 then begin
    print,"ERROR: No valid data found in file "+infile
    return,0
  endif

  ; Convert time values back to UTC strings
  res_times = res_times[ind_ok]
  res_UTC = anytim2utc(res_times, /ccsds, /truncate)

  ; Prepare result structure
  signal = [[asp_A1],[asp_A0],[asp_B1],[asp_B0]]
  ; also define attributes y_srf and z_srf where to store the results
  result = {times:res_times, UTC:res_utc, signal:transpose(signal), _calibrated:0, primary:primary, y_srf:0.*res_times, z_srf:0.*res_times}
  return,result
end
