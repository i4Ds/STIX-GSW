;+
; Description :
;   Procedure to calibrate raw data: biases are subtracted and relative gains are applied.
;
; Category    : analysis
;
; Syntax      : stx_calib_sas_data, data , calibfile  [, factor=factor ]
;
; Inputs      :
;   data      = a structure as returned by read_hk_data
;   calibfile = name of the file with calibration parameters (gains and bias values), including full absolute path
;
; Output      : The input structure is modified
;
; Keywords    :
;   factor    = an extra calibration factor to be applied (multiplied) to all signals; default = 1.0
;
; History     :
;   2020-??, F. Schuller (AIP) : created
;   2020-11-18, FSc: added 'def_calibfile' in common block; added attribute _calibrated.
;   2021-06-21, FSc: added optional calibration factor
;   2021-11-15 - FSc: removed common block "config"
;   2022-01-28 - FSc (AIP): adapted to STX_ASPECT_DTO structure
;   2022-04-21, FSc (AIP) : changed name from "calib_sas_data" to "stx_calib_sas_data"
;-
pro stx_calib_sas_data, data, calibfile, factor=factor

  default, factor, 1.
  
  if n_params() lt 2 then message,' SYNTAX: stx_calib_sas_data, data, calibfile [, factor=factor]'
  
  if not is_struct(data) then message," ERROR: input variable is not a structure."
  
  _calibrated = data[0].calib
  if _calibrated then begin
    print," INFO: input data has already been calibrated - doing nothing."
    return
  endif

  ; Convert voltages to current - Added 2022-01-28: this has to be done here,
  ; because my new "prepare_aspect_data" function reads the raw data but does not
  ; convert to physical (current) units
  V_base = 0.06018  ; [V]
  R_m = 51100.      ; [Ohmn]
  ; Process only measurements at 64s cadence
;  ind_ok = where(abs(data.duration-64.) lt 0.1,nb_ok)
  ; increased tolerance to 0.5 s - FSc, 2022-02-15
  ind_ok = where(abs(data.duration-64.) lt 0.5,nb_ok)
  nb_rows = n_elements(data)
  if nb_ok lt nb_rows then begin
    print,nb_rows - nb_ok,format='(" CALIB_SAS_DATA Warning: Found",I5," entries with wrong duration.")'
    ind_bad = where(abs(data.duration-64.) ge 0.5,nb_bad)
    for i=0,nb_bad-1 do data[ind_bad[i]].ERROR = "SAS_DATA_WRONG_DURATION"
  endif
  data[ind_ok].CHA_DIODE0 = (data[ind_ok].CHA_DIODE0 / 16. - V_base) / R_m
  data[ind_ok].CHA_DIODE1 = (data[ind_ok].CHA_DIODE1 / 16. - V_base) / R_m
  data[ind_ok].CHB_DIODE0 = (data[ind_ok].CHB_DIODE0 / 16. - V_base) / R_m
  data[ind_ok].CHB_DIODE1 = (data[ind_ok].CHB_DIODE1 / 16. - V_base) / R_m
  
  ; Verify that the file with calibration parameters exists
  if strmid(calibfile,strlen(calibfile)-4,4) ne '.sav' then calibfile += '.sav'
  result = file_test(calibfile)
  if not result then message," ERROR: File "+calibfile+" not found."
  restore, calibfile

  ; Calibration: subtract bias and apply relative gain.
  ; Also apply calibration correction factor at the same time.
  data[ind_ok].CHA_DIODE0 = (data[ind_ok].CHA_DIODE0 - bias[0]*1.e-9) / gain[0] * factor
  data[ind_ok].CHA_DIODE1 = (data[ind_ok].CHA_DIODE1 - bias[1]*1.e-9) / gain[1] * factor
  data[ind_ok].CHB_DIODE0 = (data[ind_ok].CHB_DIODE0 - bias[2]*1.e-9) / gain[2] * factor
  data[ind_ok].CHB_DIODE1 = (data[ind_ok].CHB_DIODE1 - bias[3]*1.e-9) / gain[3] * factor
  
 ; Store calibration factor in CALIB attribute
 data.CALIB = factor
 
end
