;+
; :description:
;   structure that contains analysis software QL flare flag and location data
;
; :categories:
;    analysis software, structure definition, quicklook data
;
; :returns:
;    an uninitialized structure
;
; :history:
;     14-Sep-2016 - Simon Marcin (FHNW), initial release
;     06-Jun-2018 - Nicky Hochmuth (FHNW), set x/ypos to signed int
;
;-
function stx_asw_ql_flare_flag_location, n_time_bins

  return, { $
    type                : 'stx_asw_ql_flare_flag_location', $
    time_axis           : stx_construct_time_axis(intarr(n_time_bins+1)), $ ;+1 as time_edges
    flare_flag          : bytarr(n_time_bins), $
    pos_valid           : bytarr(n_time_bins), $
    X_POS               : intarr(n_time_bins), $
    Y_POS               : intarr(n_time_bins) $
  }

end

