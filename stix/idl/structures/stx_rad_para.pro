function stx_rad_para
  s = {type: 'stx_rad_par', det_nr: 0, pix_nr: 0, line_par: fltarr(15) } ;det_nr 1-32, pix_nr: 0-11,
  ; line_par the fit parameters for 3 calibration lines
  return, s
end