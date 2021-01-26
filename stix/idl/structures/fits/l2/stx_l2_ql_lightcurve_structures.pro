;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_lightcurve_structures
;
; :description:
;    This function saves a property file at given location. The properties... etc.
;
; :categories:
;       fits, io, quicklook, lightcurve
;       
; :purpose:
;       Makes structures to store quick look l1 lightcurve TM and serialise to fits
;
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
;    structures = stx_l2_ql_lightcurve_structures(5, 10)
;    control_struc = structures.energy
;    data_struc = structures.count
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       09-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_lightcurve_structures
;                               - based on stx_l1_ql_lightcurve_structures
;-
function stx_l2_ql_lightcurve_structures, n_energies, n_times

    control = { $
        integration_time : 0, $
        detector_mask : bytarr(32), $
        pixel_mask : bytarr(12), $
        energy_bin_mask : bytarr(33), $
        compression_scheme_counts : intarr(3),$
        compression_scheme_triggers : intarr(3),$ 
        detector_efficiency : fltarr(n_energies), $         ;
        grid_transmission: fltarr(n_energies) ,   $      ;
        window_transmission: fltarr(n_energies)  , $       ;
        attenuator_transmission: fltarr(n_energies) , $        ;
        tau :0.0, $
        eta :0.0 $
        }

    energies = stx_fits_energy_structure(n_energies)

    count = {COUNTS: fltarr(n_energies), TRIGGERS: 0L, RATE_CONTROL_REGEIME: 0b, $
        CHANNEL: lonarr(n_energies), TIME: 0.0d, TIMEDEL: 0.0, LIVETIME: 1., ERROR: lonarr(n_energies)}
        
    counts = replicate(count, n_times)
    
    return, DICTIONARY('energy', energies, 'count', counts, 'control', control)
end