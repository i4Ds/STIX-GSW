;+
; :description:
;   This defines the detector event structure for the flight software simulation.
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_detector_event structure
;
; :examples:
;    det_event = {stx_sim_detector_event}
;
; :history:
;     23-jan-2014, Laszlo I. Etesi (FHNW), initial release
;     31-jul-2014, Laszlo I. Etesi (FHNW), added 'attenuator_flag'
;     02-dec-2014, Shaun Bloomfield (TCD), updated detector index
;                  definition from 0-31 to 1-32
;     02-jul-2015, Aidan O'Flannagain (TCD), set default relative_time to -1 in order
;       to indicate the event is invalid until values are assigned
;
;-
pro stx_sim_detector_event__define
   dummy = { stx_sim_detector_event, $
            relative_time       : -1d, $ ; relative time in ms since T0
            detector_index      : 0b, $ ; 1 - 32 (see stx_subc_params in dbase)
            pixel_index         : 0b, $ ; 0 - 11 (see stx_pixel_data), 12 is used for trigger
            energy_ad_channel   : uint(0), $ ; in a/d units [0, 4095]
            attenuator_flag     : 0b $ ; 1 if this detector event is absorbed by the attenuator
          }
end
