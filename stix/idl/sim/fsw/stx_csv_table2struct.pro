function stx_accumulator_table2struct, filename, _extra = _extra

a = read_csv( filename[0], header = header, _extra=_extra )

b = reform_struct( a )
nhead = n_elements( header )
for ii = 0, nhead - 1 do b = rep_tag_name( b, 'FIELD' + strtrim(ii+1, 2), header[ii] )
nrows = n_elements( b )
tags = tag_names( b )
ntags = n_elements( tags )
out = replicate( create_struct( tags, '', ptr_new(), ptr_new(), ptr_new(), 0.0, 0, 0, 0 ), nrows )

for jrow = 0, nrows - 1 do for itag = 1, ntags -1 do begin

  tag = tags[ itag ]
  
  
    svalue = b[jrow].(itag)
    is_all = stregex( svalue, 'ALL',/fold, /boolean )
    have_dash = stregex( svalue, '-', /boolean )
    have_comma = stregex( svalue, ',', /boolean )
    is_allbig = stregex( svalue, 'ALLBIG',/fold, /boolean )
    is_fourier = stregex( svalue, 'FOURIER', /fold, /boolean )
    if have_comma then values_comma = fix( str2arr( svalue, delim = ',' ) ) else $
      values_comma = is_number( svalue ) ? fix( svalue ) : values_comma
      
      case 1 of
        tag eq 'CHANNEL_BIN' : out[jrow].(itag) = $
          ptr_new( have_dash ? fix( str2arr( svalue, delim = '-' ) ) : indgen(33) )
        tag eq 'DET_INDEX_LIST': begin
        if ~have_comma and ~is_number( svalue ) then begin
          ;Could be ALL or FOURIER
          case 1 of
            stregex( /boolean, /fold, svalue, 'ALL' ) : value = indgen(32)+1
            stregex( /boolean, /fold, svalue, 'FOURIER') : value = [indgen(8)+1, 11+indgen(22)]
        out[jrow].(itag) = ptr_new( is_all ? indgen(32) + 1 : values_comma )
        ;help, jrow, itag
        ;print, *out[jrow].(itag)
        end
        tag eq 'PIXEL_INDEX_LIST': begin
          case 1 of
            is_allbig : values = indgen(8)
            is_all: values = indgen(12)
            have_comma: values = values_comma
            else: values = fix( svalue )
            endcase
            out[jrow].(itag) = ptr_new( values )
           end
        else: out[jrow].(itag) = (make_array( 1, value= svalue , type =size( out[jrow].(itag), /type)))[0]
        endcase
      
      
        
    endfor
    
return, out
end
 