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
;     10-Aug-2016 - Simon Marcin (FHNW), initial release
;
;-
function stx_asw_ql_spectra, n_time_bins

  default, n_time_bins, 2
  return, { $
    type                : 'stx_asw_ql_spectra', $
    time_axis           : stx_construct_time_axis(intarr(n_time_bins+1)), $
    energy_axis         : stx_construct_energy_axis(select=indgen(32+1)), $
    spectrum            : ulonarr(32,32,n_time_bins), $
    triggers            : ulonarr(32,n_time_bins), $
    detector_mask       : bytarr(32, n_time_bins), $
    pixel_mask          : bytarr(12) $
  }

end

