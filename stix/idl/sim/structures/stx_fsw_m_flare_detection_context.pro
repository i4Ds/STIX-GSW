;+
; :description:
;   structure that contains the flare detection module information / results
;
; :categories:
;    flight software, structure definition, simulation
;
; :returns:
;    an uninitialized structure
;
; :history:
;     10-May-2016 - Laszlo I. Etesi (FHNW), initial release
;
;-
function stx_fsw_m_flare_detection_context, cbk=cbk, thermal_cc=thermal_cc, nonthermal_cc=nonthermal_cc, fip=fip, thermal_bg=thermal_bg, nonthermal_bg=nonthermal_bg
  return, { $
        type              : 'stx_fsw_m_flare_detection_context', $
        cbk               : cbk, $
        thermal_cc        : thermal_cc, $
        nonthermal_cc     : nonthermal_cc, $
        fip               : fip, $
        thermal_bg        : thermal_bg, $
        nonthermal_bg     : nonthermal_bg $
    }
end