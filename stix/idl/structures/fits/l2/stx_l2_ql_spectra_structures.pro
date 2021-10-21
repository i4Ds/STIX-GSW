;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_spectrum_structures
;
; :categories:
;       fits, io, quicklook, spectra
;
; :purpose:
;       Makes structures to store quick look l2 spectra TM and serialise to fits
;
; :params:
;    n_samples : in, type="int"
;             Number of spectra
;
; :returns:
;    A dictionary containing the control and data structures
;
; :examples:
;    structures = stx_l2_ql_spectra_structures(10,5)
;    control_struc = structures.control
;    data_struc = structures.data
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       08-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_spectra_structures - based on stx_l1_ql_spectra_structures
;-
function stx_l2_ql_spectra_structures, n_energies, n_times

    control = { $
        pixel_mask : bytarr(16), $
        integration_time : 0, $
        compression_scheme_spec : intarr(3), $
        compression_scheme_trigger : intarr(3) $
    }

    energies = stx_fits_energy_structure(n_energies)
    
    count = {COUNTS: lonarr(32, 32), TRIGGERS: lonarr(n_energies), CHANNEL: lonarr(n_energies), $
        DETECTOR_MASK: bytarr(32), TIME: 0.0d, TIMEDEL: 0.0}

    counts = replicate(count, n_times) 
    
    return, dictionary('energy', energies, 'count', counts, 'control', control)

end
