function stx_lightcurve, n_e, n_t
  lc = { $
    type          : 'stx_lightcurve', $
    time_axis     : stx_time_axis(n_t), $ 
    energy_axis   : stx_energy_axis(n_e), $
    data          : reform(dblarr(n_e, n_t),n_e,n_t),  $
    unit          : 'unit' $
  }
  
  return, lc
end