;+
; :Description:
;    Define the meta calibration structure,STX_CAL_FILE_META
;    ** Structure STX_CAL_FILE_META, 15 tags, length=3160, data length=3160:
;    FILENAME        STRING    ''
;    DURATION        LONG                 0 ;integration time in seconds
;    LIVE_TIME       LONG                 0 ;live_time in milliseconds
;    QUIET_TIME      INT              0     ;calibration quiet time gate in milliseconds
;    BL_HOLDER       INT              0     ;Is the baseline holder on, 1 for on
;    AVERAGE_TEMP    FLOAT          0.000000 ;temp in degrees Centigrade
;    DET_MASK        LONG64               0  ;bytarr(32) compressed to single word
;    PIX_MASK        LONG64                0 ;bytarr(16) compressed to single word
;    FITS_FILE_ID    LONG64                         0
;    CALIBRATION_RUN_ID LONG64                         0
;    MEAS_START_UTC  STRING    ''
;    GAIN            FLOAT     Array[12, 32]  ;calibration gain in 1024 adc units per keV
;    OFFSET          FLOAT     Array[12, 32]  ;adc1024 location of 0 keV
;    AVG31           FLOAT          0.000000  ;average adc1024 location of 30.85 keV peak from gain & offset
;    SIG31           FLOAT          0.000000  ;sigma of distribution of 30.85 keV adc1024
;
;
;
;
;
; :Author: rschwartz70@gmail.com
; 6-aug-2020 (Hiroshima +75 years)
;-
pro stx_cal_file_meta__define

  d = {stx_cal_file_meta, $
    filename: '', $
    
    duration: 0L, $
    live_time: 0L, $
    quiet_time: 0, $
    bl_holder: 0, $
    average_temp: 0.0, $
    det_mask: 0ll, $
    pix_mask: 0ll, $
    fits_file_id: 0LL, $
    calibration_run_id: 0LL, $
    meas_start_utc: '', $
    gain: fltarr(12, 32), $
    offset: fltarr(12, 32), $
    avg31: 0.0, $
    sig31: 0.0 $


  }
end