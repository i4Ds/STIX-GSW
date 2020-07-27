;+
; :description:
;   structure that contains analysis software QL variance data
;
; :categories:
;    analysis software, structure definition, quicklook data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     15-Sep-2016 - Simon Marcin (FHNW), initial release
;
;-
function stx_asw_ql_variance, n_time_bins

  return, { $
    type                   : 'stx_asw_ql_variance', $
    time_axis              : stx_construct_time_axis(intarr(n_time_bins+1)), $ ;+1 as time_edges
    energy_mask            : bytarr(32), $
    samples_per_variance   : fix(0), $
    variance               : lonarr(n_time_bins), $
    detector_mask          : bytarr(32), $
    pixel_mask             : bytarr(12) $
  }

end

