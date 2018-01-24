;+
; :description:
;   structure that contains the CFL module information / results
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized structure
;
; :history:
;     10-May-2016 - Laszlo I. Etesi (FHNW), initial release
;
;-
function stx_fsw_m_coarse_flare_locator, x_pos=x_pos, y_pos=y_pos, time_axis=time_axis 
  default, time_axis, stx_construct_time_axis([0,1])
  default, x_pos, 0
  default, y_pos, 0

  cfl_struct = {  $
    type : 'stx_fsw_m_coarse_flare_locator', $
    time_axis : time_axis, $
    x_pos     : x_pos, $
    y_pos     : y_pos $
  }
  
  return, cfl_struct
end

