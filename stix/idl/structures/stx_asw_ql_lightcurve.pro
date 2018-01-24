;+
; :description:
;   structure that contains analysis software QL LC data
;
; :categories:
;    analysis software, structure definition, quicklook data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     10-May-2016 - Laszlo I. Etesi (FHNW), initial release
;     28-Jun-2016 - Simon Marcin (FHNW), added param n_time_bins and n_energy_bins
;
;-
function stx_asw_ql_lightcurve, n_time_bins, n_energy_bins
  
  ; default is 5 energy bins
  default, n_energy_bins, 5

  return, { $
      type                : 'stx_asw_ql_lightcurve', $
      time_axis           : stx_construct_time_axis(intarr(n_time_bins+1)), $
      energy_axis         : stx_construct_energy_axis(select=indgen(n_energy_bins+1)), $
      counts              : lonarr(n_energy_bins,n_time_bins), $
      triggers            : lonarr(n_time_bins), $
      rate_control_regime : bytarr(n_time_bins), $
      detector_mask       : bytarr(32), $
      pixel_mask          : bytarr(12) $
    }

end

