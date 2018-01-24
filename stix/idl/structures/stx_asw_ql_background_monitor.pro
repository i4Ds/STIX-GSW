;+
; :description:
;   structure that contains analysis software QL background monitor data
;
; :categories:
;    analysis software, structure definition, quicklook data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     20-Sep-2016 - Simon Marcin (FHNW), initial release
;
;-
function stx_asw_ql_background_monitor, n_time_bins, n_energy_bins

  ; default is 5 energy bins
  default, n_energy_bins, 32

  return, { $
    type                : 'stx_asw_ql_background_monitor', $
    time_axis           : stx_construct_time_axis(intarr(n_time_bins+1)), $ ;+1 because it's time_edges
    energy_axis         : stx_construct_energy_axis(select=indgen(n_energy_bins+1)), $
    background          : lonarr(n_energy_bins,n_time_bins), $
    triggers            : lonarr(n_time_bins) $
  }

end

