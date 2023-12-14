function stx_aux_data
  
  struct = { $
    type                       : 'stx_aux_data', $
    time_utc                   : '', $
    spice_disc_size            : float(0), $
    y_srf                      : float(0), $
    z_srf                      : float(0), $
    sas_ok                     : byte(1), $
    solo_loc_carrington_lonlat : fltarr(2), $
    solo_loc_carrington_dist   : float(0), $ 
    solo_loc_heeq_zxy          : fltarr(3), $
    roll_angle_rpy             : fltarr(3) $
  }
  return, struct
  
end