;+
; :description:
;   structure that contains the flare flag module information / results
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
function stx_fsw_m_flare_flag, flare_flag=flare_flag, context=context, time_axis=time_axis
  default, flare_flag, 0
  default, time_axis, stx_construct_time_axis([0, 1])
  
  return, isvalid(context) ? $
    { $
      type        : 'stx_fsw_m_flare_flag', $
      time_axis   : time_axis, $
      flare_flag  : flare_flag, $
      context     : context $
      } : $
    { $
      type        : 'stx_fsw_m_flare_flag', $
      time_axis   : time_axis, $
      flare_flag  : flare_flag $
    }
end