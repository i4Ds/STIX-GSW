;+
; :Description:
;    Describe the procedure.
; :Examples:
;    Here are some test runs you can try. The detector_events file has to be in the current directory or the full descriptor passed
;    STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001, ts=0.001 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001, ts=0.0012 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    
;    IDL> STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    MRDFITS: Binary table.  5 columns by  16586 rows.
;    ** Structure <147664e0>, 4 tags, length=3145760, data length=3145760, refs=1:
;    TYPE            STRING    'stx_sim_calibration_spectrum'
;    ACCUMULATED_COUNTS
;    ULONG64   Array[1024, 12, 32]
;    LIVE_TIME       DOUBLE           63.983303
;    T_OPEN          DOUBLE        -0.016697049
;    16586.000
;    IDL> STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    MRDFITS: Binary table.  5 columns by  16586 rows.
;    ** Structure <147664e0>, 4 tags, length=3145760, data length=3145760, refs=1:
;    TYPE            STRING    'stx_sim_calibration_spectrum'
;    ACCUMULATED_COUNTS
;    ULONG64   Array[1024, 12, 32]
;    LIVE_TIME       DOUBLE           49.368202
;    T_OPEN          DOUBLE        -0.015697049
;    12828.000
;    IDL> STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001, ts=0.001 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    MRDFITS: Binary table.  5 columns by  16586 rows.
;    ** Structure <147664e0>, 4 tags, length=3145760, data length=3145760, refs=1:
;    TYPE            STRING    'stx_sim_calibration_spectrum'
;    ACCUMULATED_COUNTS
;    ULONG64   Array[1024, 12, 32]
;    LIVE_TIME       DOUBLE           49.368202
;    T_OPEN          DOUBLE        -0.015697049
;    12828.000
;    IDL> STX_FSW_ACCUMULATION_OF_CALIBRATION_SPECTRUM_test, cal_spectrum = cal_spectrum, tq=0.001, ts=0.0012 & help, cal_spectrum & print, total( cal_spectrum.ACCUMULATED_COUNTS )
;    MRDFITS: Binary table.  5 columns by  16586 rows.
;    ** Structure <147664e0>, 4 tags, length=3145760, data length=3145760, refs=1:
;    TYPE            STRING    'stx_sim_calibration_spectrum'
;    ACCUMULATED_COUNTS
;    ULONG64   Array[1024, 12, 32]
;    LIVE_TIME       DOUBLE           47.460257
;    T_OPEN          DOUBLE        -0.015531569
;    12317.000

; :Keywords:
;    cal_spectrum
;    file
;    _extra
;
; :Author: raschwar
;-
pro stx_fsw_accumulation_of_calibration_spectrum_test, cal_spectrum = cal_spectrum, file=file, _extra=_extra

cal_spectrum = 0
default, file, 'detector_events_sample.fits'
data = mrdfits( /unsigned, file , 1 )
;break into 4 second chunks and process
duration = last_item( data.relative_time )
nbin = ceil( duration / 4.0 )
ibound =  [-1, value_locate( data.relative_time, ( 1.0 + dindgen( nbin )) * 4.0 ) ]
for ii = 0L, nbin - 1 do $
  stx_fsw_accumulation_of_calibration_spectrum, data[ ibound[ ii ] + 1 : ibound[ ii + 1] ], cal = cal_spectrum, _extra=_extra

end  
