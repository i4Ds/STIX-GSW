;+
; :project:
;       STIX
;
; :name:
;       stx_l2_ql_background_structures
;
; :categories:
;       fits, io, quicklook, background
;
; :purpose:
;       Makes structures to store quick look l2 backgound TM and serialise to fits
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
;    structures = stx_l2_ql_background_structures(5, 10)
;    control_struc = structures.energy
;    data_struc = structures.count
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       9-Apr-2020 – ECMD (Graz), initial release of stx_l2_ql_background_structures
;                               - based on stx_l1_ql_background_structures
;
;-
function stx_l2_ql_background_structures, n_energies, n_times

  control = { $
    integration_time : 0, $
    energy_bin_mask : bytarr(33),              $
    compression_scheme_background_skm : intarr(3), $
    compression_scheme_triggers_skm : intarr(3),    $
    nbkg_disabled_pixels : 0,                  $     ;
    detector_efficiency: fltarr(n_energies),   $     ;
    bkg_livetime: fltarr(n_times) ,            $     ;
    bkg_grid_transmission: fltarr(n_energies), $     ;
    window_transmission: fltarr(n_energies) , $
    tau :0.0, $
    eta :0.0 $
  }


  energies = stx_fits_energy_structure(n_energies)

  low_flux_rate = {background: fltarr(n_energies), $  ; 'Low flux-equivalent background [photons/cm2/second]
    triggers: 0l, channel: lonarr(n_energies), time: 0.0d, $
    timedel: 0.0, livetime: 1., error: lonarr(n_energies)}

  high_flux_rate = {background: fltarr(n_energies), $ ; 'High flux estimated background [photons/cm2/second]'
    triggers: 0l, channel: lonarr(n_energies), time: 0.0d, $
    timedel: 0.0, livetime: 1., error: lonarr(n_energies)}

  high_flux_rate = replicate(high_flux_rate, n_times)
  low_flux_rate  = replicate(low_flux_rate, n_times)

  return, dictionary('energy', energies, 'low_flux_rate', low_flux_rate, 'high_flux_rate', high_flux_rate, 'control', control )
end