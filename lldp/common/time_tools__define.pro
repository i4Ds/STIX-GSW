FUNCTION time_tools::init, time_tai
  IF n_elements(time_tai) GT 1 THEN $
     message, "n_elements(time_tai) must be 0 or 1"
  
  IF n_elements(time_tai) EQ 1 THEN self.time_tai = time_tai[0]
  
  ;; Success
  return, 1
END


FUNCTION time_tools::time_in_ccsds, itime
  IF n_elements(itime) EQ 0 THEN get_utc, itime, /ccsds
  return, anytim2utc(itime, /ccsds)
END

FUNCTION time_tools::time_as_obt, itime
  IF n_elements(itime) EQ 0 THEN get_utc, itime
  
  time =   anytim2tai(itime) - anytim2tai('2015/12/01 00:00:00')
  
  formatted=trim(time, '(I010)')
  return, formatted
END

; Format the supplied time as YYYYMMDD_HHMMSS. If no supplied time,
; current time is used.
;
FUNCTION time_tools::time_yyyymmddThhmmss, itime
  time = self->time_in_ccsds(itime)

  ;; Remove all colons, dashes, and subseconds

  formatted = strmid(time, 2, 2)+strmid(time, 5, 2)+ $
              strmid(time, 8, 5)+strmid(time, 14, 2) +$
              strmid(time, 17, 2)
  
  return, formatted
END

FUNCTION time_tools::time_yyyymmddhhmmss, itime
  time=self->time_in_ccsds(itime)
  formatted=strmid(time, 0,4)+strmid(time,5,2)+ $
            strmid(time, 8,2)+strmid(time,11,2)+ $
            strmid(time,14,2)+strmid(time,17,2)
  return,formatted
END 

; Return YYYY/MM/DD HH:MM:SS from "request_YYMMDD_HHMMSS_AnyName"
;
FUNCTION time_tools::time_from_request, request
  year = '20'+strmid(request, 8, 2)
  month = strmid(request, 10, 2)
  day = strmid(request, 12, 2)
  hour = strmid(request, 15, 2)
  minute = strmid(request, 17, 2)
  second = strmid(request, 19, 2)
  
  time = year+"/"+month+"/"+day+" "+hour+":"+minute+":"+second
  return, time
END


; Later on, we might add functionality to set/get time, but for now this is
; only a toolbox-type class (less clutter)
;
PRO time_tools__define
  dummy = {TIME_TOOLS, $
           time_tai:0.0d}
END
