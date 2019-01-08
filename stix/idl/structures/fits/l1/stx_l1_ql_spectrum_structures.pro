function stx_l1_ql_spectrum, n_energies, n_times

    energy = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}

    energies = replicate(energy, n_energies)
    
    count = {COUNTS: lonarr(32, 32), TRIGGERS: 0L, CHANNEL: lonarr(n_energies), DETECTOR_MASK: bytarr(32), TIME: 0.0d, TIMEDEL: 0.0}

    counts = REPLICATE(rate_structure, n_times) 
    
    return, DICTIONARY('energy', energies, 'count', counts)

end
