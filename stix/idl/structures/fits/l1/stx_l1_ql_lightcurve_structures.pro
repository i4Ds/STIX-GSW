function stx_l1_ql_lightcurve_structures, n_energies, n_times

    energy = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}
    energies = replicate(energy, n_energies)

    count = {COUNTS: lonarr(n_energies), TRIGGERS: 0L, RATE_CONTROL_REGEIME: 0b, $
        CHANNEL: lonarr(n_energies), TIME: 0.0d, TIMEDEL: 0.0, LIVETIME: 1, ERROR: lonarr(n_energies)}
        
    counts = replicate(count, n_times)
    
    return, DICTIONARY('energy', energies, 'count', counts)
end