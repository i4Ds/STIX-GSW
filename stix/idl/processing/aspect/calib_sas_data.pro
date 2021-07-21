;+
; Description :
;   Procedure to calibrate raw data: biases are subtracted and relative gains are applied.
;
; Category    : analysis
;
; Syntax      : calib_sas_data, data [, calibfile=calibfile, factor=factor ]
;
; Inputs      :
;   data      = a structure as returned by read_sas_data
;
; Output      : The input structure is modified
;
; Keywords    :
;   calibfile = if given, use gain and bias values defined in this file; otherwise, use the default
;               file def_calibfile as defined in common block config.
;   factor    = an extra calibration factor to be applied (multiplied) to all signals; default = 1.0
;
; History     :
;   2020-??, F. Schuller (AIP) : created
;   2020-11-18, FSc: added 'def_calibfile' in common block; added attribute _calibrated.
;   2021-06-21, FSc: added optional calibration factor
;
;-
pro calib_sas_data, data, calibfile=calibfile, factor=factor
  common config

  if not is_struct(data) then begin
    print,"ERROR: input variable is not a structure."
    return
  endif
  
  if data._calibrated then begin
    print,"ERROR: input data has already been calibrated."
    return
  endif

  if not keyword_set(factor) then factor = 1.
  if not keyword_set(calibfile) then calibfile = def_calibfile  ; defined in common block config
  restore, param_dir + calibfile + '.sav'

  ; calibration: subtract bias and apply relative gain
  for arm=0,3 do data.signal[arm,*] = (data.signal[arm,*] - bias[arm]*1.e-9) / gain[arm]
  ; re-normalisation (if needed)
  data.signal *= factor
  data._calibrated = 1
end
