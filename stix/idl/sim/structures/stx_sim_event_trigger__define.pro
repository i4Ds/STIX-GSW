; :history:
;     02-jul-2015, Aidan O'Flannagain (TCD), set default relative_time to -1 in order
;       to indicate the event is invalid until values are assigned

pro stx_sim_event_trigger__define
  dummy= { stx_sim_event_trigger, $
            relative_time       : -1d, $ ; relative time in ms since T0
            adgroup_index       : 0b, $ ; 0 - 15 
            detector_index      : 0b  $ ; 0 - 31 (see stx_subc_params in dbase)
          }
end