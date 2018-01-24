pro stx_fsw_rotating_buffer__define
  rb = { $
    stx_fsw_rotating_buffer, $
    ;data_type     : byte(0), $                  ; 1b: Aspect system, 10b: detectors 
    timestamp     : double(0), $
    counts        : lonarr(32, 12, 32), $       ; 32 energies, 12 pixels, 32 detectors
    triggers      : lonarr(16) $               ; 16 trigger accumulators    
    }
end