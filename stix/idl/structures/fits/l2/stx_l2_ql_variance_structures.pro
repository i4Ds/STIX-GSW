;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_variance_structures
;       
; :purpose:
;       Makes structures to store quicklook l2 backgound TM and serialise to fits
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
;    structures = stx_l2_ql_variance_structures(10)
;    control_struc = structures.energy
;    data_struc = structures.count
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       09-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_variance_structures 
;                                  based on stx_l1_ql_variance_structures
;-
function stx_l2_ql_variance_structures, n_times

    control = { $
        integration_time : 0.0, $
        detector_mask : bytarr(32), $
        pixel_mask : bytarr(16), $
        energy_bin_mask : bytarr(32), $
        compression_scheme_variance_skm : intarr(3), $
        samples_per_variance: 0 }
  
    energies = stx_fits_energy_structure(1)

    count = {variance: 0., time: 0.0d, timedel: 0.0, error: 0l}                         
    counts = replicate(count, n_times)
    
    return, dictionary('energy', energies, 'count', counts, 'control', control)
end