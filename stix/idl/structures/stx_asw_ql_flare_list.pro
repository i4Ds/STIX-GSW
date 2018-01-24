;+
; :description:
;   This function creates an uninitialized stx_sim_ql_flare_list structure.
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized stx_sim_ql_flare_list structure
;
; :examples:
;    qlfl = stx_sim_ql_flare_list()
;
; :history:
;     19-Dec-2015, Simon Marcin (FHNW), initial release
;
;-
function stx_asw_ql_flare_list, number_flares=number_flares, random=random

  default, number_flares, 2
  default, random, 0

  pointer_start=ulong64(0)
  pointer_end=ulong64(0)
  start_times=replicate(stx_time(),number_flares)
  end_times=replicate(stx_time(),number_flares)
  high_flag=bytarr(number_flares)  
  nbr_packets=bytarr(number_flares)  
  processed=bytarr(number_flares)  
  compression=bytarr(number_flares)  
  transmitted=bytarr(number_flares)  
  
  if random then begin
    pointer_start=FIX((2ULL^48)*RANDOMU(Seed))
    pointer_end=FIX((2ULL^48)*RANDOMU(Seed))    
    start_times=replicate(stx_time(),number_flares)
    start_times=stx_time_add(start_times,seconds=FIX((2^14)*RANDOMU(Seed)))
    end_times=stx_time_add(start_times,seconds=1000)
    high_flag=FIX((2^8)*RANDOMU(Seed,number_flares))
    nbr_packets=FIX((2^8)*RANDOMU(Seed,number_flares))
    processed=FIX((2^1)*RANDOMU(Seed,number_flares))
    compression=FIX((2^2)*RANDOMU(Seed,number_flares))
    transmitted=FIX((2^1)*RANDOMU(Seed,number_flares))    
  endif

  return, { type    : 'stx_asw_ql_flare_list', $
    pointer_start              : pointer_start, $
    pointer_end                : pointer_end, $
    start_times                : start_times, $
    end_times                  : end_times, $
    high_flag                  : high_flag , $
    nbr_packets                : nbr_packets, $
    processed                  : processed, $
    compression                : compression, $
    transmitted                : transmitted }
end