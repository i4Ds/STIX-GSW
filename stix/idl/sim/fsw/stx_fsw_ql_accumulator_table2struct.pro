;+
;
; :Name:
;   stx_fsw_ql_accumulator_table2struct
; :description:
;   This function reads and parses the energy, pixel, detector, and time configurations
;
; :categories:
;    flight software, constructor, simulation
; :Params:
;   filename - optional, path descriptor of accumulator configuration table, default is qlook_accumulators.csv
;   dir - directory for filename if not in default location which is $STX_CONF
;
; :keywords:
;   all keywords for read_csv through _extra (none needed at this time)
                 
; :returns:
;    
; :examples:
;     
;    f = '.\stix\idl\sim\fsw\qlook_accumulators.csv
;    IDL> s = stx_fsw_ql_accumulator_table2struct( f )
;    IDL> help, s,/st
;    ** Structure <a450d60>, 9 tags, length=40, data length=40, refs=1:
;       ACCUMULATOR     STRING    ''
;       CHANNEL_BIN     POINTER   <PtrHeapVar101>
;       DET_INDEX_LIST  POINTER   <PtrHeapVar102>
;       PIXEL_INDEX_LIST
;                       POINTER   <PtrHeapVar103>
;       DT              FLOAT           4.00000
;       SUM_DET         INT              1
;       SUM_PIX         INT              1
;       LIVETIME        INT              0
;       PIXEL_SUB_SUM   INT              0
;    IDL> print, s.pixel_sub_sum
;           0       0       0       0       0       0       0       0       0       0       1       0       0       0       0       0
;      IDL> help, s
;      S               STRUCT    = -> <Anonymous> Array[16]
;    :history:
;     28-apr-2014, richard.schwartz@nasa.gov
;     2-may-2014, richard.schwartz@nasa.gov, fixed bug in det_index_list
;     made det_index_list and pixel_index_list both use "value" and not "values"
;     put the default file into $STX_CONF 
;     10-jun-2014, richard.schwartz@nasa.gov, changed dt field to double precision, however
;     as this is FSW we should be working with some sort of clock unit in long64 as that is 
;     surely what will be done in the real FSW, and the only way to match those boundaries
;     is to use the same long64, change to double courtesy of Ewan Dickson suggestion because
;     of 0.10 second boundaries in variance computation
;     
;;-
function stx_fsw_ql_accumulator_table2struct, filename, dir = dir, error = error, _extra = _extra
error = 1

if ~file_exist(filename) then begin
  message, /info, 'quicklook accumulator parameter file, not found!'
  return, -1
endif
  
;Look for comment lines and skip
txt = rd_ascii( filename )
nrec = ( where( strmid(txt, 0, 7) eq ';;;;;;;') )[0] + 1
a = read_csv( filename[0], header = header, _extra=_extra, record_start = nrec )

b = reform_struct( a )
nhead = n_elements( header )
for ii = 0, nhead - 1 do b = rep_tag_name( b, 'FIELD' + strtrim(ii+1, 2), header[ii] )
nrows = n_elements( b )
tags = [tag_names( b ), 'PIXEL_SUB_SUM']
ntags = n_elements( tags )
out = replicate( create_struct( tags, '', ptr_new(), ptr_new(), ptr_new(), 0.0d0, 0, 0, 0, 0, 0 ), nrows )

for jrow = 0, nrows - 1 do for itag = 1, ntags - 2 do begin

  tag = tags[ itag ]
  
  
    svalue = stregex_replace( b[jrow].(itag), '"','' ) ;remove double quotes before parsing
    is_all = stregex( svalue, 'ALL',/fold, /boolean )
    have_dash = stregex( svalue, '-', /boolean )
    have_comma = stregex( svalue, ',', /boolean )
    is_big8 = stregex( svalue, 'BIG8',/fold, /boolean )
    is_corners = stregex( svalue, 'CORNER', /fold, /boolean )
    is_fourier = stregex( svalue, 'FOURIER', /fold, /boolean )
    if have_comma then values_comma = fix( str2arr( svalue, delim = ',' ) ) 
      
      case 1 of
        tag eq 'CHANNEL_BIN' : out[jrow].(itag) = $
          ptr_new( have_dash ? fix( str2arr( svalue, delim = '-' ) ) : indgen(33) )
        tag eq 'DET_INDEX_LIST': begin
        
          case 1 of
            is_all : value = indgen(32)+1
            is_fourier : value = [indgen(8)+1, 11+indgen(22)]
            have_comma: value = values_comma
            else: value = fix( svalue )
          endcase
        out[jrow].(itag) = ptr_new( value ) 
        
        end
        tag eq 'PIXEL_INDEX_LIST': begin
          case 1 of
            is_big8 or is_corners : value = indgen(8)
            
            is_all: value = indgen(12)
            have_comma: value = values_comma
            else: values = fix( svalue )
            endcase
            out[jrow].(itag) = ptr_new( value )
            out[jrow].pixel_sub_sum = is_corners ? 1 : 0  ;sum the two corner pixels in accumulator
           end
           
        else: out[jrow].(itag) = (make_array( 1, value= svalue , type =size( out[jrow].(itag), /type)))[0]
        endcase
   endfor
out.accumulator = b.accumulator ;quick-look structure name    
error = 0
return, out
end
 