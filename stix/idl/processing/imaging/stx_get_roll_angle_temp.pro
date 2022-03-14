; 
; NAME:
;   stx_get_roll_angle
;       
; PURPOSE:
;   provides the Solar Orbiter roll angle value for an input date
;   
; CALLING SEQUENCE:
;   stx_get_roll_angle( flare_start_time )
;
; INPUTS:
;   this_time: input date for which the roll angle value is returned
;
; OUTPUT:
;   Solar Orbiter roll angle value

function stx_get_roll_angle_temp, this_time

set_data = read_csv(loc_file( 'roll_angle_value.csv', path = getenv('STX_VIS_DEMO')), header=header, table_header=tableheader, n_table_header=1 )

if (anytim(this_time) lt anytim(set_data.field1[0])) or (anytim(this_time) gt anytim(set_data.field1[-1])) then begin
  
  message, 'No roll angle information, time must be between June 1 2020 and March 10 2022.'

endif else begin
  
  ind = min(abs(anytim(this_time) - anytim(set_data.field1)), iind)
  return, set_data.field2[iind]

endelse

end