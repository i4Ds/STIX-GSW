  ;+
  ;:Description:
  ;Finds and converts the stx_time structure format to all anytim formats
  ;Searches the input structure (only) for 'time_range' and uses that
  ;or will look for the tag 'type' with value 'stx_time' and then uses the value of 'tag' value
  ;If it can't interpret it as a 'stx_time' it will pass it on to anytim
  ;Takes all anytim keywords through inheritance.
  ;:Examples:
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
  ;:Params:
  ;   Instruct - Normally a STIX time structure, if not, it is interpreted by anytim and may throw an error
  ;:Keywords:
  ; _extra - passed to anytim(), can generate all anytim output formats   
  ;History: 25-nov-2013, RAS (GSFC), initial upload
  ;         19.02.2015, nicky hochmuth stx_time is now a named struct
  ;         17-nov-2019, RAS (GSFC), cleaned up the commented garbage and completed the doc header
  ;-
function stx_time2any, instruct, error = error, _extra = _extra, quiet = quiet
  if ~isa(instruct) then begin
    error=1
    return, instruct
  endif
  if ppl_typeof(instruct, COMPARETO='STX_TIME', /RAW) then return, anytim(instruct.value, _extra = _extra, error=error)
  return, anytim(instruct, _extra = _extra, error=error)
end