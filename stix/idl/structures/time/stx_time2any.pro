function stx_time2any, instruct, error = error, _extra = _extra, quiet = quiet
;+
;Finds and converts the stx_time structure format to all anytim formats
;Searches the input structure (only) for 'time_range' and uses that 
;or will look for the tag 'type' with value 'stx_time' and then uses the value of 'tag' value
;If it can't interpret it as a 'stx_time' it will pass it on to anytim
;Takes all anytim keywords through inheritance.
;Examples:
;  IDL> s=stx_visibility()
;  IDL> help, stx_time2any( s, /vms)
;  <Expression>    STRING    = Array[2]
;  IDL> print, stx_time2any( s, /vms)
;   1-Jan-2019 00:00:00.000  1-Jan-2019 00:00:00.000
;  IDL> print, stx_time2any( s.time_range, /vms)
;   1-Jan-2019 00:00:00.000  1-Jan-2019 00:00:00.000
;  IDL> print, stx_time2any( s.time_range[0].value, /vms)
;   1-Jan-2019 00:00:00.000
;  IDL> print, stx_time2any( s.time_range[0].value, /vms, error=error) & help, error
;   1-Jan-2019 00:00:00.000
;  ERROR           INT       =        0;
;  
;History: 25-nov-2013, richard schwartz (gsfc), initial upload
;         19.02.2015, nicky hochmuth stx_time is now a named struct
;-

if ~isa(instruct) then begin
  error=1
  return, instruct
endif



if ppl_typeof(instruct, COMPARETO='STX_TIME', /RAW) then  return, anytim(instruct.value, _extra = _extra, error=error)
return, anytim(instruct, _extra = _extra, error=error) 
;error = 1
;if ~is_struct( instruct ) then goto, try_anytim
;time_range = get_tag_value( instruct, /time_range, /quiet )
;if is_struct( time_range )  && have_tag(time_range, 'type' )&& strlowcase( get_tag_value( time_range[0], /type, /quiet)) eq 'stx_time' then $
;  ;it's 'time_range'
;
;  return, anytim( get_tag_value( time_range, /value ), _extra = _extra, error=error )
;
;;if we're here it may just be a simple time  
;if is_struct( instruct ) && have_tag( instruct, 'value') &&  strlowcase( get_tag_value( instruct[0], /type, /quiet)) eq 'stx_time' then $
;  return, anytim( instruct.value, _extra = _extra, error=error )
;
;if  STRUPCASE( tag_names( /str, instruct ) ) eq 'CDS_INT_TIME' then return, anytim( instruct, _extra = _extra, error=error )
;
;try_anytim:
;out = anytim( instruct, _extra = _extra, error=error ); help, instruct & stop & out = anytim( instruct, _extra = _extra, error=error )
;if error then begin
;  message, /info, 'Could not interpret time, returning input'
;  out = instruct
;  endif
;
;return, out
end