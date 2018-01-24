;+
; :description:
;   structure that contains the variance module information / results
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
function stx_fsw_m_variance, variance=variance, time_axis=time_axis
  default, time_axis, stx_construct_time_axis([0, 1])
  return, { $
    type        : 'stx_fsw_m_variance', $
    time_axis   : time_axis, $
    variance    : variance $
  }
end