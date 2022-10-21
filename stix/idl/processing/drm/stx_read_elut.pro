;+
; :Description:
;    This procedure finds the most recent ELUT csv file, reads it, and returns the gain and offset used to make it along
;    with the edges of the Edges in keV (Exact) and ADC 4096, rounded
; :Examples:
;    IDL> stx_read_elut, gain, offset, adc4096_str
;
;    IDL> help,gain, offset, adc4096_str
;    gain        DOUBLE    = Array[12, 32]
;    offset      DOUBLE    = Array[12, 32]
;    ADC4096_STR     STRUCT    = -> <Anonymous> Array[12, 32]
;    IDL> help, adc4096_str
;    ADC4096_STR     STRUCT    = -> <Anonymous> Array[12, 32]
;    IDL> help, adc4096_str,/st
;    IDL> help, adc4096_str,/st
;    ** Structure <15a51c50>, 5 tags, length=208, data length=206, refs=1:
;       ELUT_FILE       STRING    'elut_table_20190704.csv'  ELUT filename
;       EKEV            FLOAT     Array[31]                  science energy channel edges in keV
;       ADC4096         INT       Array[31]                  4096 ADC channel value based on EKEV and gain/offset
;       PIX_ID          INT              0                   Pixel cell of detector, 0-11
;       DET_ID          INT              0                   Detector ID 0-31
;    IDL> print, adc4096_str[0,0].adc4096
;    1092    1101    1111    1120    1129    1139    1148    1157    1166    1176    1185    1194    1204    1222    1241    1259    1287    1315    1352    1389    1426
;    1473    1519    1575    1640    1705    1761    1835    1984    2169    2448
;    IDL> print, adc4096_str[3,0].adc4096
;    1159    1168    1177    1186    1196    1205    1214    1223    1233    1242    1251    1260    1269    1288    1306    1325    1353    1380    1417    1454    1491
;    1537    1583    1638    1703    1768    1823    1897    2044    2229    2506
;    IDL> print, adc4096_str[3,31].adc4096
;    1066    1075    1085    1094    1103    1113    1122    1131    1141    1150    1159    1169    1178    1197    1215    1234    1262    1290    1327    1364    1402
;    1448    1495    1551    1616    1681    1737    1812    1961    2147    2427
;
; :Params:
;    gain - 4096 ADC gain in keV/ADC, normally about 0.10
;    offset - 4096 ADC bin corresponding to 0 keV
;    adc4096_str -
;    IDL> stx_read_elut, gain, offset, str4096, elut_filename = f, scale1024=0, ekev_a = ekev
;    IDL> print, ekev[*,0:1,0]
;           3.9528848       5.0419448       6.0220988       7.0022528       7.9824068       8.9625608       10.051621       11.031775
;           12.011929       12.992083       13.972237       14.952391       16.041451       18.001759       19.962067       22.031281
;           24.971743       28.021111       32.050633       35.971249       40.000771       45.010447       50.020123       56.009953
;           62.979937       69.949921       76.048657       83.998795       100.00798       120.04668       149.99583
;           3.9652347       4.9474497       6.0387997       7.0210147       8.0032297       8.9854447       9.9676597       10.949875
;           12.041225       13.023440       14.005655       14.987870       15.970085       18.043650       20.008080       21.972510
;           25.028290       27.974935       32.012930       36.050925       39.979785       44.999995       50.020205       56.022630
;           63.007270       69.991910       75.994335       83.961190       100.00403       119.97574       149.98786
;    IDL> pmm,gain
;         0.104247     0.110312
;    IDL> pmm, offset
;          844.445      922.222
;
; :Keywords:
;    ELUT_FILENAME - search and use this file, with or without full path
;    EKEV_ACTUAL   - channel edges with true energies based on full adc 4096 bins
;    SCALE1024     - 1 or 0, default 1.  If set, gain and offset are returned
;    for the 1024 ADC calibration data. EKEV_ACTUAL is the same regardless
;    path          - Path to the folder in which to search for elut_table csv files, by default .../ssw/so/stix/dbase/detector is used.
;
;
;
;
; :Author: rschwartz70@gmail.com, 2-jul-2019
; :History: 29-aug-2019, improved the file search for the elut file
; :RAS, 11-jun-2020, added ekev_actual, corrected the action of scale1024==0
; :ECMD, 23-Feb-2022, fixed issue with finding file if current folder is not /stix
; :ECMD, 03-Aug-2022, fixed issue when filename keyword is not used
;
;-
pro stx_read_elut, gain, offset, adc4096_str, elut_filename = elut_filename, scale1024 = scale1024, $
  ekev_actual = ekev_actual, path = path

  default, scale1024, 1

  if getenv('SSW_STIX') eq '' and ~keyword_set(path) then message, 'Path to ELUT table files not found.'

  if keyword_set(elut_filename) then begin
    case 1 of
      file_exist( elut_filename ) : elut_file = elut_filename
      file_exist( concat_dir( concat_dir('SSW_STIX','dbase'),'detector') + get_delim() + elut_filename) : $
        elut_file =  concat_dir( concat_dir('SSW_STIX','dbase'),'detector') + get_delim() + elut_filename
    end
  endif else begin

    default, path, [concat_dir( concat_dir('SSW_STIX','dbase'),'detector')]

    elut_file = file_search( path,'elut_table*.csv', count=count)
    filename = file_basename( elut_file )
    ;only include filename with dates. Look for numbers
    use = where( stregex( filename, '.[0-9].',/boo))
    elut_file = elut_file[use]
    filename = file_basename( elut_file )
    old_style = where( stregex( filename, '-',/boo), nold, $
      complement = usefile2time, ncomp= nusefile2time )
    if nusefile2time ge 1 then begin
      elut_file = elut_file[ usefile2time ]
      filename  = filename[ usefile2time ]
      date = file2time( filename )
    endif else begin
      if nold ge 1 then begin
        elut_file = elut_file[ old_style ]
        filename  = filename[ old_style ]
        date = strmid( filename, 11, 11)
      endif
    endelse

    count = n_elements( date )
    if count gt 1 then begin
      ord = reverse( sort( anytim( date )))
      elut_file = elut_file[ ord[0] ]
    endif
  end

  elut_str = reform_struct( read_csv( elut_file, n_table_header=3 ))
  ;Get the previous offset and gain suitable for the ADC1024 cal spectra

  if scale1024 then begin
    offset = reform( elut_str.(0) / 4.0, 12, 32)
    gain = reform( elut_str.(1) * 4.0, 12, 32)
  endif else begin
    offset = reform( elut_str.(0), 12, 32)
    gain = reform( elut_str.(1), 12, 32)

  endelse
  ekev =(stx_science_energy_channels()).edges_1
  adc4096_str = replicate( {elut_file:file_basename( elut_file[0] ), ekev: ekev, adc4096: intarr(31), pix_id: 0, det_id: 0}, 12, 32)
  adc4096_str[*].pix_id = elut_str.field03
  adc4096_str[*].det_id = elut_str.field04
  for i = 4,34 do adc4096_str.adc4096[i-4] = reform( elut_str.(i), 12, 32)
  scl = scale1024 ? 4.0 : 1.0
  gain4096 = transpose( reproduce(gain/scl,31),[2,0,1])
  offset4096 = transpose( reproduce(offset*scl,31),[2,0,1])
  ekev_actual =  (adc4096_str.adc4096-offset4096)*gain4096

end