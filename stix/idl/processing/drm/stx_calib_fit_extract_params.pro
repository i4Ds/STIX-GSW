;+
; :Description:
;    Describe the procedure.
;
; :Examples:
;    IDL> result = stx_calib_fit_extract_params()
;    MRDFITS: Binary table.  11 columns by  384 rows.
;    IDL> help, result
;    RESULT          STRUCT    = -> STX_CAL_FITS Array[12, 32]
;    IDL> help, result,/st
;    ** Structure STX_CAL_FITS, 16 tags, length=64, data length=64:
;    E31             FLOAT           31.0541
;    E31S            FLOAT        0.00762761
;    R31             FLOAT           1.78836
;    R31S            FLOAT         0.0218994
;    E35             FLOAT           35.4279
;    E35S            FLOAT         0.0178856
;    R35             FLOAT           2.00855
;    R35S            FLOAT         0.0551651
;    E81             FLOAT           81.4295
;    E81S            FLOAT         0.0225141
;    R81             FLOAT           1.63080
;    R81S            FLOAT         0.0655710
;    GAIN_INPUT      FLOAT          0.430700
;    OFFSET_INPUT    FLOAT           263.748
;    GAIN_RESULT     FLOAT          0.428773
;    OFFSET_RESULT   FLOAT           263.900;
;
; :Keywords:
;    path
;    filename
;
;
; :Author: rschwartz70@gmail.com, 2-jul-2019
;-
function stx_calib_fit_extract_params,  filename = filename, path = path

  default, path, [curdir(), concat_dir( concat_dir('ssw_stix','dbase'),'detector')]


  ;Prepare output format from IDL calibration fitting or from Oliver's matlab results from TVAC
  results = replicate( { stx_cal_fits, e31: 0.0, e31s: 0.0, r31: 0.0, r31s: 0.0, $
    e35: 0.0, e35s: 0.0, r35: 0.0, r35s: 0.0, $
    e81: 0.0, e81s: 0.0, r81: 0.0, r81s: 0.0, $
    gain_input:0.0, offset_input:0.0, $
    gain_result:0.0, offset_result:0.0 }, 384 )

  default, filename, 'all_fits*.fits'
  f = file_search( path, filename, count=count)
  time = file2time( f )
  ord  = reverse( sort( file2time( f )) )
  f = f[ord[0]]
  afts = mrdfits(f,1)
  i3135 = [ 4, 11 ] ;line energy position
  i81   = i3135[0]
  results.e31 = afts.params_lo[i3135[0]]
  results.e31s = afts.sigmas_lo[i3135[0]]
  results.r31 = afts.params_lo[i3135[0]+1] * 2.36
  results.r31s = afts.sigmas_lo[i3135[0]+1] * 2.36

  results.e35 = afts.params_lo[i3135[1]]
  results.e35s = afts.sigmas_lo[i3135[1]]
  results.r35 = afts.params_lo[i3135[1]+1] * 2.36
  results.r35s = afts.sigmas_lo[i3135[1]+1] * 2.36

  results.e81 = afts.params_hi[i81]
  results.e81s = afts.sigmas_hi[i81]
  results.r81 = afts.params_hi[i81+1] * 2.36
  results.r81s = afts.sigmas_hi[i81+1] * 2.36

  results.gain_input = afts.gainfit
  results.offset_input = afts.offsetfit

  out = stx_calib_fit_gain_offset( results.gain_input, results.offset_input, results.e31, results.e81 )
  results.gain_result = out.gain
  results.offset_result = out.offset


  return, reform( results, 12, 32)
end