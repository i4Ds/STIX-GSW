function stx_kms_compression_list_types, out, hdr=hdr, quiet = quiet
f = file_search(concat_dir( getenv( 'ssw_stix' ), 'dbase/conf'), 'stx_tm_compression_types.csv')

if file_exist( f ) then  out = read_csv( f, head=hdr )
if ~keyword_set( quiet ) then print, out.field2,form='(a)'

return, out.field2
end
;+


; :Description:
;    Describe the procedure. Get the kms values for various telemetry types
;    IDL> print, stx_kms_compression_types(/variance)
;    or
;    print, stx_kms_compression_types( 'variance' )
;    5           3           0
;    IDL> print, stx_kms_compression_types(/calibration_counter)
;    5           3           0
;    IDL> print, stx_kms_compression_types(/ql_lc)
;    5           3           0
;    Table of type description, single name, and k, m, s values
;     Summed calibration counts in 1 spectral datum         Max_calibration_datum 4 4 0
;                               Calibration counter           Calibration_counter 5 3 0
;                              QL light curve datum                   QL_LC_datum 5 3 0
;                                 QL spectral datum             QL_spectrum_datum 5 3 0
;                   Individual trigger accumulators   single_trigger_accumulators 5 3 0
;                       Summed trigger accumulators   summed_trigger_accumulators 5 3 0
;                                      Pixel counts                  pixel_counts 4 4 0
;                                 Visibility counts               vis_diff_counts 4 3 1
;                                          Variance                      variance 5 3 0
;
;  These are all the possible types. Be sure to use a unique name fragment as the fragment
;  is matched with the possible types via stregex, so using /ql or /accumulators will not
;  return a k m s values
;    Max_calibration_datum
;    Calibration_counter
;    QL_LC_datum
;    QL_spectrum_datum
;    single_trigger_accumulators
;    summed_trigger_accumulators
;    pixel_counts
;    vis_diff_counts
;    variance
;  :params:
;   input_string - selection may be by string of values above or via /value
;
; :Keywords:
;    out - structure from configuration structure
;    list - if set, (default is 0) then print a list of the possible telemetry datum types
;    _extra - obtain the kms values for /this_type, e.g.
;    
;
; :Author: richard.schwartz@nasa.gov
; :History: Written, 12-dec-2016
;-
function stx_kms_compression_types, input_string, out=out, hdr=hdr, list = list, _extra=_extra
      
default, list, 0      
if is_string( input_string ) then _extra = create_struct( input_string,1)
types = stx_kms_compression_list_types( out, hdr=hdr, quiet= 1-list )
row   = where( stregex( /fold, /bool, types, tag_names(_extra)), nmatch)
if nmatch eq 1 then return, [ out.field4[row], out.field5[row], out.field3[row]] else return, 0
end
