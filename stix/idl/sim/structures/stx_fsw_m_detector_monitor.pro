;+
; :description:
;   structure that contains the detector monitor module information / results
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
function stx_fsw_m_detector_monitor, active_detectors=active_detectors, noisy_detectors=noisy_detectors, time_axis=time_axis
  default, active_detectors, bytarr(32)+1b
  default, noisy_detectors, bytarr(32)+1b
  default, time_axis, stx_construct_time_axis([0, 1])
  
  return, { $
    type              : 'stx_fsw_m_detector_monitor', $
    time_axis         : time_axis, $
    active_detectors  : active_detectors, $
    noisy_detectors   : noisy_detectors $
  }
end