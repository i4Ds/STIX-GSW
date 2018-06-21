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
;    19-Jun-2018 - Nicky Hochmuth (FHNW) align with ICD  
;-
function stx_asw_ql_flare_list, number_flares=number_flares, random=random

  default, number_flares, 2
  default, random, 0

  pointer_start=ulong64(0)
  pointer_end=ulong64(0)
  
  if number_flares gt 0 then begin
  
    start_coarse             = replicate(stx_time(),number_flares)
    end_coarse               = replicate(stx_time(),number_flares)
    high_flag                = uintarr(number_flares)
    tm_volume                = ulon64arr(number_flares)
    avg_cfl_z                = intarr(number_flares)
    avg_cfl_y                = intarr(number_flares)
    processing_status        = bytarr(number_flares)  
  endif else begin
    start_coarse             = stx_construct_time()
    end_coarse               = stx_construct_time()
    high_flag                = 0
    tm_volume                = 0
    avg_cfl_z                = 0
    avg_cfl_y                = 0
    processing_status        = 0
  endelse
  
  if random then begin
    states = [1b, 2b, 4b, 8b, 16b, 32b, 64b, 128b]
    
    pointer_start   = ulong64((2ULL^30)*RANDOMU(Seed))
    pointer_end     = ulong64((2ULL^30)*RANDOMU(Seed))  
    
    if number_flares gt 0 then begin
      start_coarse    = replicate(stx_time(),number_flares)
      start_coarse    = stx_time_add(start_coarse,seconds=FIX((2^14)*RANDOMU(Seed,number_flares)))
      end_coarse      = stx_time_add(start_coarse,seconds=FIX((500)*RANDOMU(Seed,number_flares)))
      tm_volume       = ulong64((2L^32)*RANDOMU(Seed,number_flares))
      avg_cfl_z       = fix(128 - (2^8)*RANDOMU(Seed,number_flares))
      avg_cfl_y       = fix(128 - (2^8)*RANDOMU(Seed,number_flares))
      processing_status=states[BYTE(8*RANDOMU(Seed,number_flares))]
    endif
        
  endif

  return, { type    : 'stx_asw_ql_flare_list', $
    pointer_start              : pointer_start, $
    pointer_end                : pointer_end, $
    number_flares              : number_flares, $
    start_coarse               : start_coarse, $
    end_coarse                 : end_coarse, $
    high_flag                  : high_flag , $
    tm_volume                  : tm_volume, $
    avg_cfl_z                  : avg_cfl_z, $
    avg_cfl_y                  : avg_cfl_y, $
    processing_status          : processing_status }
end