;+
; :project:
;       STIX
;
; :name:
;       stx_fits_energy_structure
;
; :purpose:
;       Makes structures to store engery info in compatable with HESSARC/RHESSI  
;
; :categories:
;       structures, telemetry
;
; :params:
;    n_energies : in, type="int"
;             Number of energies channels
;
; :returns:
;    A structure containing channel and correeponding E_MIN, E_MAX 
;
; :examples:
; 
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_fits_energy_structure, n_energies

    energy = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}

    energies = replicate(energy, n_energies)

    return, energies
end

