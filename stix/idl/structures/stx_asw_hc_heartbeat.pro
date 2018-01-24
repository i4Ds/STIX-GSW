;+
; :description:
;   structure that contains analysis software house keeping heartbeat
;
; :categories:
;    analysis software, structure definition, house keeping data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     09-Nov-2016 - Simon Marcin (FHNW), init
;
;-
function stx_asw_hc_heartbeat, random=random
  default, random, 0

  return, { $
    type                             : 'stx_asw_hc_heartbeat', $
    time                             : random ? stx_time_add(stx_time(),seconds=uint((2^14)*RANDOMU(Seed))) : stx_time(), $
    flare_message                    : random ? uint((2ULL^8) * RANDOMU(seed)) : uint(0), $
    x_location                       : random ? fix((2ULL^7) * RANDOMU(seed)-(2ULL^7) * RANDOMU(seed)): fix(0), $
    y_location                       : random ? fix((2ULL^7) * RANDOMU(seed)-(2ULL^7) * RANDOMU(seed)): fix(0), $
    flare_duration                   : random ? ulong((2ULL^32) * RANDOMU(seed)) : ulong(0), $
    attenuator_motion                : random ? byte((2ULL^1) * RANDOMU(seed)): byte(0) $
  }

end
