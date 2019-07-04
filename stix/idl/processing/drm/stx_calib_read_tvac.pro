;+
; :Description:
;    Reads the results of the TVAC fits to gain and offset for all 12x32 pixels.
;    These results come from fitsresults.mat which have been translated to fitsresults.h5
;    The h5 file (hvf5) is then read using h5_parse() in IDL
; :File Comments:
;    The detector order seems scrambled with det_id 31 appearing first with all 12 of 
;    its pixels in order. This row of 12 for gain and offset is moved to the end of the
;    of the list so in order or reading [1-31,0] yielding the gains and offset values
;    for pixels 0-11 and detectors 0-31
;
;
;
; :Keywords:
;    path - directory path containing h5 file
;    h5_file - 
;
; :Author: rschwartz70@gmail.com
; :History: 01-Jul-2019, RAS, version 1
;-
function stx_calib_read_tvac, h5_file = h5_file, path = path
  default, path, [curdir(), concat_dir( concat_dir('ssw_stix','dbase'),'detector')]

  default, h5_file, 'fitsresults.h5'

  if ~file_exist( h5_file ) then h5_path = file_search( path, file_basename( h5_file[0]), count = h5_count) $
    else h5_path = h5_file
  h = h5_parse( h5_path[0], /read)
  ;    IDL> help, h
  ;    ** Structure <e4190f0>, 12 tags, length=17136, data length=17112, refs=1:
  ;    _NAME           STRING    'C:\ssw\soft\stix_ssm\clear\fitsresults.h5'
  ;    _ICONTYPE       STRING    'hdf'
  ;    _TYPE           STRING    'GROUP'
  ;    _FILE           STRING    'C:\ssw\soft\stix_ssm\clear\fitsresults.h5'
  ;    _PATH           STRING    '/'
  ;    _COMMENT        STRING    ''
  ;    ENTRIES_31_34   STRUCT    -> <Anonymous> Array[1]
  ;    FWHM_31         STRUCT    -> <Anonymous> Array[1]
  ;    FWHM_81         STRUCT    -> <Anonymous> Array[1]
  ;    FITGAIN         STRUCT    -> <Anonymous> Array[1]
  ;    FITOFFSET       STRUCT    -> <Anonymous> Array[1]
  ;    TOTALENTRIES    STRUCT    -> <Anonymous> Array[1]
  results = replicate( {results_h5, gain: 0.0, offset:0.0, fwhm_31: 0.0, fwhm_81: 0.0 }, 12, 32 )
  results.gain = h.fitgain._data
  results.offset = h.fitoffset._data
  results.fwhm_31  = h.fwhm_31._data
  results.fwhm_81  = h.fwhm_81._data
  ;reorder the results to fix the tvac file
  results = [[results[*,1:31]],[ results[*,0]]]

  return, results
end