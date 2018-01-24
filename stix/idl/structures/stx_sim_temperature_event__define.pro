;+
; :description:
;   This defines creates a temperature event structure for the flight software simulation.
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_temperature_event structure
;
; :examples:
;    temp_event = {stx_sim_temperature_event}
;
; :history:
;     17-Jun-2015, Marek Steslicki (SRC Wro), initial release
;-
pro stx_sim_temperature_event__define
   dummy = { stx_sim_temperature_event, $
            relative_time       : 0d, $ ; relative time in ms since T0
            detector_index      : 0b, $ ; 1 - 32 (see stx_subc_params in dbase)
            temperature    : uint(0)  $ 
          }
end
