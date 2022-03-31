; 
; NAME:
;   stx_get_l0_b0_rsun_roll_temp
;       
; PURPOSE:
;   provides the following values for a specific Solar Orbiter UT time (TEMPORARY SOLUTION):
;     - L0: Heliographic longitude (L0 angle, degrees)
;     - B0: Heliographic latitude (B0 angle, degrees)
;     - rsun: apparent radius of the Sun as seen from Solar Orbiter (arcsec)
;     - roll_angle: Solar Orbiter roll angle (degrees)
;   
; CALLING SEQUENCE:
;   stx_get_l0_b0_rsun_roll_temp( this_time )
;
; INPUTS:
;   this_time: time for which L0, B0, rsun and roll roll_angle returned
;
; OUTPUT:
;   Structure containing the values of L0, B0, rsun and roll_angle for a specific time
;
; HISTORY: March 2022, Anna V. and Paolo M., created
;
; CONTACTS: 
;          volpara[at]dima.unige.it
;          massa.p[at]dima.unige.it

function stx_get_l0_b0_rsun_roll_temp, this_time

set_data = read_csv(loc_file( 'L0_B0_rsun_roll_values.csv', path = getenv('STX_VIS_DEMO')), header=header, table_header=tableheader, n_table_header=1 )
this_time_steps = set_data.field1
B0_values         = set_data.field2
L0_values         = set_data.field3
rsun_values       = set_data.field4
roll_angle_values = set_data.field5


if (anytim(this_time) lt anytim(this_time_steps[0])) or (anytim(this_time) gt anytim(this_time_steps[-1])) then begin
  
  message, 'No information, time must be between ' + this_time_steps[0] + ' and ' + this_time_steps[-1]

endif else begin
  
  min_time_diff = min(abs(anytim(this_time) - anytim(set_data.field1)), iind)
  
  return, {L0: L0_values[iind], B0: B0_values[iind], RSUN: rsun_values[iind], ROLL_ANGLE: -roll_angle_values[iind]}

endelse

end