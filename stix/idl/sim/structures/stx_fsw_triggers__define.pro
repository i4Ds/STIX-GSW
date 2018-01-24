;+
; :description:
;   structure that contains the trigger module information / results
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
pro stx_fsw_triggers__define
  void = { stx_fsw_triggers, $
            relative_time_range     : dblarr(2), $ ; relative start and end time of integration in seconds
            triggers                : lonarr(16) $ ; number of triggers
          }
end