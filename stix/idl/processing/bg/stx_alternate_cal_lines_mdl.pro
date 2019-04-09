;+
; :description:
;    This procedure returns the line energies, any additional Gaussians needed for background and the broad energy ranges to perform fits
;    for the specific source
;
; :categories:
;    calibration
;
; :params:
;    source: the required calibration source either CO57 or AM241
;
;
; :keywords:
;
;    background_line_param : Gaussian lines to
;
;    fit_energy_ranges : The broad energy ranges where the fits to the background and emission lines should be performed
;
;    ilines: The lines which should be used to estimate detector gain
;
;
; :returns:
;   gauss_line_param: the gaussian line parameters (intensity, energy and sigma) for the strongest x-ray emission lines in the STIX
;   energy range
;
; :examples:
;     gauss_line_param = stx_alternate_cal_lines_mdl('co57', background_line_param = background_line_param, $
;    fit_energy_ranges = fit_energy_ranges, ilines = ilines)
;
; :history:
;    1-Apr-2019 - ECMD (Graz), initial release
;
;-
function stx_alternate_cal_lines_mdl, source, background_line_param = background_line_param, fit_energy_ranges = fit_energy_ranges, $
  ilines=ilines

  src = strupcase(source)

  case src of
    'CO57': begin

      kev6 = [0.326 , 6.404 ,0.5 ]
      kev14 =  [0.0916, 14.413, 0.5]
      kev122 = [.856, 122.0614, 1.5]
      kev136 = [.1068, 136.4743, 1.5]
      gauss_line_param = [ kev6[*], kev14[*], kev122[*], kev136[*] ]

      kev118 = [.6, 118, 1.5]
      kev80 = [.1, 80, 5]
      background_line_param = [kev80[*], kev118[*]]
      fit_energy_ranges  = [[3., 27.3], [65., 200.]]

      ilines =[0, 2]

    end

    'AM241' : begin

      kev13 = [0.167, 13.9, 0.5]
      kev17 = [.0707, 17.8, 0.5]
      kev59 = [.359, 59.54, 1.5]
      gauss_line_param = [  kev13[*], kev17[*], kev59[*] ]

      kev56 = [.1, 56., 1.5]
      kev40 = [.01, 40, 5]
      background_line_param = [kev56[*], kev40[*]]

      fit_energy_ranges = [[10., 25], [40., 70.]]
      ilines =[0, 2]
    end

    else: message, 'Source not recognized'
  endcase

  return, gauss_line_param
end

