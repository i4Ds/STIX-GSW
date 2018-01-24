;+
; :description:
;   This function creates an uninitialized detector event structure for the flight software simulation.
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_detector_event structure
;
; :examples:
;    det_event = stx_sim_detector_event()
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;     04-nov-2014, Laszlo I. Etesi (FHNW), using named structure now
;     07-jul-2015, Laszlo I. Etesi (FHNW), setting relative time to -1 to indicate (uninitialized)
;-
function stx_sim_detector_event
  de = {stx_sim_detector_event}
  de.relative_time = -1d
  return, de
end
