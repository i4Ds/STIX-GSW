;+
; :project:
;       STIX
;
; :name:
;       stx_l1_ql_variance_structures
;
; :purpose:
;       Makes structures to store quick look l1 backgound TM and serialise to fits
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_energies : in, type="int"
;             Number of energies channels
;
;    n_samples : in, type="int"
;             Number of variance measurements
;
; :returns:
;    A dictionary containing the energy and count structures
;
; :examples:
;    structures = stx_l1_ql_variance_structures(5, 10)
;    control_struc = structures.energy
;    data_struc = structures.count
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_l1_ql_variance_structures, n_energies, n_times

    control = { $
        integration_time : 0.0, $
        detector_mask : bytarr(32), $
        pixel_mask : bytarr(16), $
        energy_bin_mask : bytarr(32), $
        compression_scheme_variance : intarr(3), $
        samples_per_variance: 0 $
    }

   
    energies = stx_fits_energy_structure(n_energies)

    count = {VARIANCE: 0L, TRIGGERS: 0L, CHANNEL: lonarr(n_energies), TIME: 0.0d, TIMEDEL: 0.0, $
                    LIVETIME: 1, ERROR: 0L}                         
    counts = REPLICATE(count, n_times)
    
    return, DICTIONARY('energy', energies, 'count', counts, 'control', control)
end