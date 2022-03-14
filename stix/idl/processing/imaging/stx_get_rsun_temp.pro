;
; NAME:
;   stx_get_rsun_temp
;
; PURPOSE:
;   provides the value of the solar radius (as seen from Solar Orbiter) in arcsec. Temporary solution before the official fits files will bes used
;
; CALLING SEQUENCE:
;   stx_get_rsun_temp( flare_start_time )
;
; INPUTS:
;   this_time: input date for which the value of the solar radius is returned
;
; OUTPUT:
;   Angular radius of the Sun (as seen from Solar Orbiter) in arcsec

function stx_get_rsun_temp, this_time

set_data = read_csv(loc_file( 'sun_angular_diameter.csv', path = getenv('STX_VIS_DEMO')), header=header, table_header=tableheader, n_table_header=1 )

if (anytim(this_time) lt anytim(set_data.field1[0])) or (anytim(this_time) gt anytim(set_data.field1[-1])) then begin

  message, 'No roll angle information, time must be between June 1 2020 and March 10 2022.'

endif else begin

  ind = min(abs(anytim(this_time) - anytim(set_data.field1)), iind)
  return, set_data.field2[iind] * 60. /2.

endelse

end