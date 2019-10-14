;+
; :Description:
;    This procedure runs the processing of the calibration spectra
;    starting from reading the previous ELUT, ingesting the previously read cal spectra,
;    fitting the lines in non-interactive OSPEX, and finally plotting the fractional differences
;    between the old and new gain and offset. If requested writes a new ELUT with the newly 
;    derived gain and offset for the ADC4096
;
; :Params:
;    all_fits_filename - use this all_fits file which holds the intermediate fitting results.
;     It is incomplete because not aall the detector data has been accepted
;
; :Keywords:
;    obj - OSPEX object
;    path - data path to ELUT, looks in dbase/detector otherwise
;    spectra - 1024 channel cal spectra for 12x32 individual detectors
;    offset_nominal - previously fitted offset
;    gain_nominal -previously fitted gain
;    all_fits - data structure with fitting results
;    ;  IDL> help, results,/st
;  ** Structure STX_CAL_FITS, 16 tags, length=64, data length=64:
;  E31             FLOAT           31.0541
;  E31S            FLOAT        0.00762761
;  R31             FLOAT           1.78836
;  R31S            FLOAT         0.0218994
;  E35             FLOAT           35.4279
;  E35S            FLOAT         0.0178856
;  R35             FLOAT           2.00855
;  R35S            FLOAT         0.0551651
;  E81             FLOAT           81.4295
;  E81S            FLOAT         0.0225141
;  R81             FLOAT           1.63080
;  R81S            FLOAT         0.0655710
;  GAIN_INPUT      FLOAT          0.430700
;  OFFSET_INPUT    FLOAT           263.748
;  GAIN_RESULT     FLOAT          0.428773
;  OFFSET_RESULT

;    calib_spectra_filename - pathway to cal spectra if not provided
;    plot_change - if set, plot the fractional deviations in gain and offset
;    write_elut  - if set, write an ELUT
;    
;    _extra
;
; :Author: rschwartz70@gmail.com, 4-jul-2019
;-
pro stx_calib_fit, all_fits_filename, obj = obj, path = path, $
  spectra = spectra, $
  offset_nominal = offset_nominal, gain_nominal = gain_nominal, $
  all_fits = all_fits, $
  plot_change = plot_change, $
  write_elut = write_elut, $
  calib_spectra_filename = calib_spectra_filename, _extra = _extra


  default, write_elut, 0
  stx_read_elut, gain_nominal, offset_nominal, /scale1024, _extra = _extra
  default, path, [curdir(), concat_dir( concat_dir('ssw_stix','dbase'),'detector')]
  spectra = n_dimensions( spectra ) ge 3 ? spectra : $
    stx_calib_fit_get_calibration_spectra( filename = calib_spectra_filename, path = path)

  ;Get the data and previous offsets and gains,
  ;Expect this input to be more fully developed in the future, 29-jun-2019
  ;stx_calib_fit_data_prep, offset_nominal, gain_nominal, spectra, path = path

  ; :Description:
  ;    STX_CALIB_PROCESS_FITS controls the fitting of gaussian and tailing gaussian lines obtained from the
  ;    calibration sources on STIX.
  ; :Examples:
  ;    stx_calib_fit_process, obj, spectra, $
  ;      all_fits, filename = filename, $
  ;      det_id_range = det_id_range
  ; :Params:
  ;    obj - spex object class
  ;    all_fits - data structure with results from fitting
  ;
  ; :Keywords:
  ;    filename - FITS file containing parameter results from fitting
  ;    offset_nominal  - offset, dim 12x32 returned from the current or selected ELUT, full 4096 ADC bins
  ;    gain_nominal    - gain, dim 12x32 returned from the current or selected ELUT, full 4096 ADC bins, expressed in keV/bin ~ 0.10 keV/adc bin
  ;
  ;    det_id_range - 2 element fix, obtain fit over this range of detector ids (0-31)
  stx_calib_fit_process, obj, spectra, $
    all_fits, $
    offset_nominal = offset_nominal, gain_nominal = gain_nominal, $
    filename = all_fits_filename, $
    det_id_range = det_id_range, $
    path = path
  
  results = stx_calib_fit_extract_params( filename = all_fits_filename)
  ;  IDL> help, results,/st
  ;  ** Structure STX_CAL_FITS, 16 tags, length=64, data length=64:
  ;  E31             FLOAT           31.0541
  ;  E31S            FLOAT        0.00762761
  ;  R31             FLOAT           1.78836
  ;  R31S            FLOAT         0.0218994
  ;  E35             FLOAT           35.4279
  ;  E35S            FLOAT         0.0178856
  ;  R35             FLOAT           2.00855
  ;  R35S            FLOAT         0.0551651
  ;  E81             FLOAT           81.4295
  ;  E81S            FLOAT         0.0225141
  ;  R81             FLOAT           1.63080
  ;  R81S            FLOAT         0.0655710
  ;  GAIN_INPUT      FLOAT          0.430700
  ;  OFFSET_INPUT    FLOAT           263.748
  ;  GAIN_RESULT     FLOAT          0.428773
  ;  OFFSET_RESULT
  if keyword_set( plot_change ) then stx_calib_fit_plot_change, results, dev_offset, dev_gain
  if write_elut then stx_write_elut, results.gain_result / 4.0, results.offset_result * 4.0

end