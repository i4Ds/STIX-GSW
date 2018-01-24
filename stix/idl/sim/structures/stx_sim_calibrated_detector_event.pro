;+
; :description:
;   This function creates an uninitialized calibrated detector event structure for the flight software simulation.
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_calibrated_detector_event structure
;
; :examples:
;    calib_det_event = stx_sim_calibrated_detector_event()
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;     01-jul-2015, Aidan O'Flannagain (TCD), set default relative_time to -1 in order
;       to indicate the event is invalid until values are assigned
;
;-
function stx_sim_calibrated_detector_event
  return, { stx_sim_calibrated_detector_event, $
            relative_time: -1d, $ ; relative time in ms since T0
            detector_index: 0b, $ ; 0 - 31 (see stx_subc_params in dbase)
            pixel_index: 0b, $ ; 0 - 12 (see stx_pixel_data), 12 is used for trigger
            energy_science_channel: 0b $ ; [0,31] 
          }
end