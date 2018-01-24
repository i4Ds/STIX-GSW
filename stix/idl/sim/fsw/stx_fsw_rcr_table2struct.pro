;+
;
; :Name:
;   stx_fsw_rcr_table2struct
;   
; :description:
;   This function reads and parses the energy, pixel, detector, and time configurations
;
; :categories:
;    flight software, constructor, simulation
;    
; :Params:
;   filename - optional, path descriptor of accumulator configuration table, default is rcr_states.csv
;   dir - directory for filename if not in default location which is $STX_CONF
;
; :keywords:
;
;   rcr_max: out, the maximum allowable value of the rate control regime, needed for the logic of the RCR algorhthm
;
;   min_attenuator_level: out, the minimum rcr level for which the attenuator is in, needed for the logic of the RCR algorhthm
;
;   keywords for read_csv can be passed through _extra (none needed at this time)
;
; :returns:
;
; :examples:
;
;   f = '.\stix\dbase\conf\rcr_states.csv'
;   IDL> s = stx_fsw_rcr_table2struct( f )
;   IDL> help, s, /st
;   ** Structure <524d62a0>, 5 tags, length=20, data length=16, refs=1:
;   LEVEL           INT              0
;   NORTH           POINTER   <PtrHeapVar1510>
;   SOUTH           POINTER   <PtrHeapVar1511>
;   BACKGROUND      POINTER   <PtrHeapVar1512>
;   ATTENUATOR      INT              0
;   IDL> print, s.attenuator
;       0       1       1       1       1       1       1       1
;   IDL> help, s
;    S               STRUCT    = -> <Anonymous> Array[8]
; 
;    :history:
;     31-Jan-2017 ECMD (Graz), initial release based on stx_fsw_ql_accumulator_table2struct.pro
;     25-Apr-2017 ECMD (Graz), now retrieving min_attenuator_level directly from RCR states 
;     31-May-2017 ECMD (Graz), attenuator tag now calculated from RCR state 
;
;;-
function stx_fsw_rcr_table2struct, filename, dir = dir, rcr_max = rcr_max, min_attenuator_level = min_attenuator_level, $
    error = error, _extra = _extra
    
   error = 1
      
   default, filename, concat_dir( getenv('STX_CONF'), 'rcr_states.csv' )
   filename =  keyword_set(dir) ?  concat_dir( dir, filename ) : filename 
   if ~file_exist(filename) then begin
    message, /info, 'rcr parameter file, not found!'
    return, -1
   endif
  
  ;Look for comment lines and skip
  txt = rd_ascii( filename )
  nrec = ( where( strmid(txt, 0, 7) eq ';;;;;;;') )[0] + 1
  a = read_csv( filename[0], header = header, _extra=_extra, record_start = nrec )
  att = []
  
  b = reform_struct( a )
  nhead = n_elements( header )
  for ii = 0, nhead - 1 do b = rep_tag_name( b, 'FIELD' + strtrim(ii+1, 2), header[ii] )
  nrows = n_elements( b )
  tags = [tag_names( b ), 'attenuator']
  ntags = n_elements( tags )
  out = replicate( create_struct( tags, 0, ptr_new(), ptr_new(), ptr_new(), 0), nrows )
  n = 0L
  
  for jrow = 0, nrows - 1 do for itag = 0, ntags - 2 do begin
  
    tag = tags[ itag ]
    
    if tag eq 'LEVEL' then begin
    
      out[jrow].(itag) =  b[jrow].(itag)
      
    endif else begin
    
      svalue = stregex_replace( b[jrow].(itag), '"','' ) ;remove double quotes before parsing
      have_dash = stregex( svalue, '-', /boolean )
  
      s =  have_dash ? str2arr( svalue, delim = '-' ) : svalue
      
      j = intarr(n_elements(s), 12)
      catt= intarr(n_elements(s), 1)
      
      for ii =  0, n_elements(s)-1 do begin
        reads, s[ii], n, FORMAT='(Z)'
        dec2bin,n,binar, /qui
        j[ii,*] = binar[-12:-1]
        
        ;retrieve attenuator bit for current configuration 
        catt[ii,0] = binar[-13]
      endfor
      if tag ne 'BACKGROUND' then begin
        ;if the attenautor bits for all configurations in this state agree then add it to the array
         if ~total(catt - catt[0]) then att = [att, catt[0]] else  message, 'Configuration attenautor bits inconsistent'
       out[jrow].(ntags - 1) = catt[0]
        endif
      out[jrow].(itag) = ptr_new( transpose(j) )
    endelse
    
  endfor
  
  error = 0
  rcr_max = max(out.level)
  att = reform(att,2,nrows) ; reformat into separate columns for north and south states 
  if ~total(att - rebin(att[0,*],2,nrows) ) then  min_attenuator_level =  min(where(reform(att[0,*]) eq 1)) $
     else  message, 'North/south attenautor bits inconsistent'
  return, out
end
