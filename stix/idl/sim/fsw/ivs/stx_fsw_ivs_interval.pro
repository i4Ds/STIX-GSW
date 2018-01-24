function stx_fsw_ivs_interval

  tmp = { type          : "stx_fsw_ivs_interval", $
    start_time    : stx_time() , $
    end_time      : stx_time() , $
    start_time_idx: ulong(0), $
    end_time_idx  : ulong(0), $
    start_energy_idx  : 0b , $
    end_energy_idx: 0b , $
;    start_energy_idx_orig  : 0b , $
;    end_energy_idx_orig: 0b , $
    counts        : 0UL , $
    trim          : 0b , $
    spectroscopy  : 0b $
  }
  return, tmp
end