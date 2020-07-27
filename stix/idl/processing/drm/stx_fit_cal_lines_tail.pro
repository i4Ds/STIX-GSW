;+
; :description:
;    This function fits the several lines in the calibration spectra with a function which includes
;    a tail
;
; :categories:
;    fit, radiation damage, calibration
;
; :params:
;    counts : in, required, type='float array'
;             the measured counts in each energy bin for the calibration spectrum
;
;    energy : in, required, type = 'float array'
;             the energy edges in keV
;
;
; :keywords:
;    error_counts           : in, type="float", default= "sqrt(counts)"
;                             the error on the count values
;
;    estimated _ line _ centers : in, type='float array', default= "[31.,35.,81.]"
;                             the center value in keV for the Ba calibration lines
;
;    parameters             : out,  type ="list"
;                             the fitted parameters 'Hole trap length (cm)','Electron trap length (cm)','
;                             Peak counts','Line energy (kev)' and 'Noise FWHM (keV)' for the 3 calibration lines
;
;
; :returns:
;    fit  - the count values for the fit including the estimated background component
;
; :examples:
;    result = stx_fit_cal_lines_tail(counts, energy)
;
; :history:
;    29-Mar-2018 - ECMD (Graz), initial release
;
;-
function stx_fit_cal_lines_tail, counts, energy,  error_counts=error_counts, estimated_line_centers = estimated_line_centers, parameters = outparam

  default, estimated_line_centers, [31.,35.,81.]
  default, bkg_energies, where(energy gt 4 and energy lt 150.)
  default, p2,   [14224238., -0.0053043224, -14888804., -0.0053587507, -2.5979600, 1.7779794e+10,  -1.9600922e+08, -2.9901226]
  default, error_counts, sqrt(counts)

  valid_energy =  where(energy gt 4 and energy lt 150.)

  counts = counts[valid_energy]
  energy = energy[valid_energy]

  n_lines = n_elements(estimated_line_centers)

  bk_parameters_fit = mpfitfun('stx_background_double_exponential', energy[bkg_energies], counts[bkg_energies], error_counts[bkg_energies]*1+1, p2)


  bkg_model =  stx_background_double_exponential(energy, bk_parameters_fit)
  bpcounts = counts

  counts -= bkg_model
  counts = counts >0

  outparam = list()

  erange_use = where(energy gt estimated_line_centers[0] - 5 and energy lt estimated_line_centers[0] + 5 )

  parinfo = replicate({value:0.D, fixed:0, parname:'', LIMITED:[1,0], LIMITS:[0.,0.]}, 3)
  parinfo.parname = ['integrated intensity','Line energy (kev)' ,'Noise FWHM (keV)']
  maxpeak = max(counts[erange_use], ipeak)
  parinfo.value =   [maxpeak,estimated_line_centers[0],1]

  fittedline = gaussfit( energy[erange_use], counts[erange_use], lfit)
  sig = lfit[2]*(2.*sqrt(2.*alog(2.)))
  totalfit = counts*0.


  for i = 0, n_lines-1 do begin

    erange_use = where(energy gt estimated_line_centers[i] - 5 and energy lt estimated_line_centers[i] + 5 )

    ; set the assumed starting parameters for the fit
    ;perform the fit on the simulated spectrum
    parinfo = replicate({value:0.D, fixed:0, parname:'', LIMITED:[1,0], LIMITS:[0.,0.]}, 5)
    parinfo.parname = ['Hole trap length (cm)','Electron trap length (cm)','Peak counts','Line energy (kev)' ,'Noise FWHM (keV)']

    maxpeak = max(counts[erange_use], ipeak)
    parinfo.value =  [0.2,20,maxpeak,estimated_line_centers[i],sig]

    ;perform the fit on the simulated spectrum
    parameters_fit = mpfitfun('stx_hecht', energy[erange_use], counts[erange_use], error_counts[erange_use]+0.1, parinfo = parinfo)
    counts_fit = stx_hecht(energy, parameters_fit)

    outparam.add, parinfo.value

    totalfit += counts_fit

  endfor


  totalfit += bkg_model


  return,totalfit
end