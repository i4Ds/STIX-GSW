;+
; :Description:
;    Describe the procedure.
;
;
;
; :Keywords:
;    filename
;    path
;    quiet
;
; :Author: rschwartz70@gmail.com, 2-jul-2019
;-
function stx_calib_fit_get_calibration_spectra, filename = filename, path = path, quiet = quiet

  default, path, [curdir(), concat_dir( concat_dir('SSW_STIX','dbase'),'detector')]
  default, filename, 'run1_summed.sav'
  default, quiet, 1
  ;Get the calibration data, these were already read from telemetry
  ;Replace with the telemetry reader and data unpacker into 384 1024 channel spectra
  file = file_search( path, filename, count=count)
  run1_summed = 0 ;placeholder for data in save file
  if count ge 1 then restore, file[0], verbose = 1-quiet   else message,'calibration spectra file not found.'

  spectra = n_dimensions(run1_summed) eq 4 ? total( run1_summed, 4) : run1_summed

  return, spectra
end