;+
; :Description:
;    Describe the procedure.
;    Populate the calibration meta data strutcture array
;    using the calibration FITS files and the pub023 elut calibrations
;    The calibration FITS files must be on a local directory and pub023 is accessed
;    through socket calls via the internet. Once the meta data structure is 
;    filled, then separately the structure is written to a FITS file for future access
;    Calibration_meta.fits is stored in stx/dbase/detector
;    
;;    ** Structure STX_CAL_FILE_META, 15 tags, length=3160, data length=3160:
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
; :Examples:
;    IDL> cal_fits_filenames = file_search('stx_cal','*calibr*complete*.fits')
;    IDL> help, cal_fits_filenames
;    CAL_FITS_FILENAMES
;    STRING    = Array[468]
;    IDL> cal_fits_filenames = file_basename( cal_fits_filenames )
;    IDL> ;meta = stx_cal_get_meta( cal_fits_filenames, path= 'stx_cal') ;already done
;    IDL> help, meta
;    META            STRUCT    = -> <Anonymous> Array[423]
;    IDL> help, mrdfits( 'calibration_meta.fits',1)
;    MRDFITS: Binary table.  15 columns by  423 rows.
;    <Expression>    STRUCT    = -> <Anonymous> Array[423]
;    IDL> help, mrdfits( 'calibration_meta.fits',1), /st
;    MRDFITS: Binary table.  15 columns by  423 rows.
;    ** Structure <18afe3d0>, 15 tags, length=3160, data length=3160, refs=1:
;    FILENAME        STRING    'solo_L1_stix-calibration-spectrum_20200414T130357__complete_00100.fits'
;    DURATION        LONG              1800
;    LIVE_TIME       LONG            902269
;    QUIET_TIME      INT              6
;    BL_HOLDER       INT              0
;    AVERAGE_TEMP    FLOAT          -38.0373
;    DET_MASK        LONG64                4294967295
;    PIX_MASK        LONG64                      4095
;    FITS_FILE_ID    LONG64                       100
;    CALIBRATION_RUN_ID
;    LONG64                       234
;    MEAS_START_UTC  STRING    '2020-04-14T13:03:57.158'
;    GAIN            FLOAT     Array[12, 32]
;    OFFSET          FLOAT     Array[12, 32]
;    AVG31           FLOAT           356.078
;    SIG31           FLOAT           13.5082
;    IDL> ;mwrfits, meta, 'calibration_meta.fits'; 
; :Params:
;    cal_fits_filename - string array of ql calibration filenames eg.
;    solo_L1_stix-calibration-spectrum_20200414T130357__complete_00100.fits
;
; :Keywords:
;    path - path to stix ql calibration filenames
;
; :Author: richard
;-
function stx_cal_get_meta, cal_fits_filename, path = path

  nfil = n_elements(cal_fits_filename)
  meta = replicate( {stx_cal_file_meta}, nfil)
  default, path, curdir()

;  ;IDL> help, {stx_cal_file_meta}
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

  for ifl = 0, nfil-1 do begin
    file = concat_dir( path, cal_fits_filename[ifl])
    meti = meta[ifl]
    hdr  = head2stc( headfits( file ))
    ctrl = mrdfits( file, 2 )
    ;extract FITS_FILE_ID

    sl = strlen( cal_fits_filename[ifl] )


    data =  stx_cal_dbase_access( cal_fits_filename[ifl], query_struct = id_str)
;      IDL> data = stx_cal_dbase_access( file, query= id_str)
;      % Compiled module: IS_OBJECT.
;      IDL> help, data
;      DATA            DOUBLE    = Array[35, 384]
;      IDL> help, id_str
;      ** Structure <155132f0>, 5 tags, length=48, data length=48, refs=1:
;         FITS_FILE_ID    LONG64                       100
;         CALIBRATION_RUN_ID
;                         LONG64                       234
;         RAW_FILE_ID     LONG64                        82
;         MEAS_START_UTC  STRING    '2020-04-14T13:03:57.158'
;         DURATION_SECONDS
;                         LONG64                      1800

    if n_elements(data) gt 1 then begin
      meti.filename = file_basename( cal_fits_filename[ifl])

      struct_assign, id_str, meti,/nozer
      struct_assign, ctrl, meti, /nozer
      meti.det_mask = stx_mask2integer( ctrl.detector_mask)
      meti.pix_mask = stx_mask2integer( ctrl.pixel_mask)
      meti.average_temp = stx_temp_convert( meti.average_temp )
      ;    IDL> print, data[0:5,0:3,0]
      ;    0.00000000      0.00000000       304.72311       2.3062776       1255.0000       1265.0000
      ;    0.00000000       1.0000000       322.32446       2.2892570       1325.0000       1335.0000
      ;    0.00000000       2.0000000       307.15777       2.2950925       1265.0000       1274.0000
      ;    0.00000000       3.0000000       313.80806       2.2806540       1291.0000       1300.0000
      ;   data array has detector index first, pixel index next, offset adc 1024, gain in adc/keV
      meti.offset[ data[1,*], data[0,*] ] = data[2,*]
      meti.gain[ data[1,*], data[0,*] ] = data[3,*]
      q = where( meti.gain gt 2 and meti.gain lt 3, nq)
      if nq gt 200 then begin
        meti.avg31 = avg(meti.offset[q] + 30.85*meti.gain[q])
        meti.sig31 = stdev( meti.offset[q] + 30.85*meti.gain[q])
        meta[ifl] = meti
      endif
    endif
  endfor
  ;only return valid meta data
  q = where( meta.filename ne '', nq)
  meta = meta[q]
  ;Empirical determination of baseline_holder on is avg31 within 5 adc of 293
  z = where( abs(meta.avg31-293) lt 5)
  meta[z].bl_holder = 1
  return, meta
end