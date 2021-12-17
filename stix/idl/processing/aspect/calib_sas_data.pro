;+
; Description :
;   Procedure to calibrate raw data: biases are subtracted and relative gains are applied.
;
; Category    : analysis
;
; Syntax      : calib_sas_data, data , calibfile  [, factor=factor ]
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
;
;-
pro calib_sas_data, data, calibfile, factor=factor

  default, factor, 1.
  
  if n_params() lt 2 then message,' SYNTAX: calib_sas_data, data, calibfile [, factor=factor]'
  
  if not is_struct(data) then message," ERROR: input variable is not a structure."
  
  if data._calibrated then begin
    print," INFO: input data has already been calibrated - doing nothing."
    return
  endif

  ; Verify that the file with calibration parameters exists
  if strmid(calibfile,strlen(calibfile)-4,4) ne '.sav' then calibfile += '.sav'
  result = file_test(calibfile)
  if not result then message," ERROR: File "+calibfile+" not found."
  restore, calibfile

  ; calibration: subtract bias and apply relative gain
  for arm=0,3 do data.signal[arm,*] = (data.signal[arm,*] - bias[arm]*1.e-9) / gain[arm]
  ; re-normalisation (if needed)
  data.signal *= factor
  ; store calibration factor in primary header
  primary = data.primary
  sxaddpar, primary, 'SAS_CALI', factor
  data.primary = primary

  ; Calibration is done:
  data._calibrated = 1
end
