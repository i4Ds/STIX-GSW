;+
; :description:
;   structure that contains the rcr module information / results
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized structure
;
; :history:
;     10-May-2016 - Laszlo I. Etesi (FHNW), initial release
;     01-Feb-2017 - ECMD (Graz), Updated to reflect changes in rcr routine 
;                                added previous_rcr and attenuator_command keywords 
;     
;-
function stx_fsw_m_rate_control_regime, rcr = rcr, previous_rcr=previous_rcr, skip_rcr=skip_rcr, $
                                        attenuator_command= attenuator_command, time_axis=time_axis
                                        
  default, time_axis, stx_construct_time_axis([0,1])
  default, rcr, 0b
  default, previous_rcr, 0b
  default, skip_rcr, 0b
  default, attenuator_command, [0b,0b]
  
  rcr_struct = {  $
    type : 'stx_fsw_m_rate_control_regime', $
    time_axis : time_axis, $
    rcr       : rcr, $
    previous_rcr      : previous_rcr, $
    attenuator_command : attenuator_command, $
    skip_rcr  : skip_rcr $
  }
  
  return, rcr_struct
end

