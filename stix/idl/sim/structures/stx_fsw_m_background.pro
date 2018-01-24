function stx_fsw_m_background, background=background, n_energies=n_energies, time_axis=time_axis
  default, n_energies, 5
  default, background, dblarr(n_energies) + 1.d
  default, time_axis, stx_construct_time_axis([0,1])
  
  return, { $
    type        : 'stx_fsw_m_background', $
    time_axis   : time_axis, $
    background  : double(background) $
  }
end