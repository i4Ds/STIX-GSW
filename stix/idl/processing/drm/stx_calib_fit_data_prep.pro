;+
; :Description:
;    This handles the data preparation for the fitting of the calibration spectra. Currently, 28-jun-2019, only configured to
;    restore data previously obtained from telemetry.  It will be more sophisticated later.  And it reads the gain and offset obtained from
;    the previous calibration as contained in the ELUT, Energy-edge Look-Up Table
;
; :Params:
;    offset_nom  - offset, dim 12x32 returned from the ELUT, full 4096 ADC bins
;    gain_nom    - gain, dim 12x32 returned from the ELUT, full 4096 ADC bins, expressed in keV/bin ~ 0.10 keV/adc bin
;    spectra     - calibration spectra, 1024 x 12 x 32
;
; :Examples:
;   stx_calib_fit_data_prep, offset_nom, gain_nom, spectra
; :Keywords:
;    path - path to elut or the cal_spectra_filename
;    cal_spectra_filename - if the spectra aren't passed then 
;    spectra = stx_calib_fit_get_calibration_spectra( filename = cal_spectra_filename, path = path)
;
;
; :Author: rschwartz70@gmail.com, 28-jun-2019.
; :History: broken into separate pieces for inclusion in stx_calib_fit as stx_read_elut and 
; stx_calib_fit_get_calibration_spectra
;-

pro stx_calib_fit_data_prep, offset_nom, gain_nom, spectra, path = path, cal_spectra_filename = cal_spectra_filename


  
  setenv,'OSPEX_MODELS_DIR='+concat_dir( getenv('ssw_stix'), concat_dir('dbase','detector'))
  stx_read_elut, gain_nom, offset_nom, adc4096_str, elut_filename = elut_filename, /scale1024
  default, path, [curdir(), concat_dir( concat_dir('ssw_stix','dbase'),'detector')]
  
  ;Get the calibration data, these were already read from telemetry
  ;Replace with the telemetry reader and data unpacker into 384 1024 channel spectra
  
  spectra = n_dimensions( spectra ) ge 3 ? spectra : $
    stx_calib_fit_get_calibration_spectra( filename = cal_spectra_filename, path = path)
end