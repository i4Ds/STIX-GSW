;+
; :Description:
;    STX_CALIB_PROCESS_FITS controls the fitting of gaussian and tailing gaussian lines obtained from the
;    calibration sources on STIX.
; :Examples:
;    stx_calib_fit_process, obj, spectra, $
;      all_fits, filename = filename, $
;      det_id_range = det_id_range
; :Params:
;    obj - spex object class
;    all_fits - data structure with results from fitting
;
; :Keywords:
;    filename - FITS file containing parameter results from fitting
;
;    det_id_range - 2 element fix, obtain fit over this range of detector ids (0-31)
;    offset_nominal  - offset, dim 12x32 returned from the current or selected ELUT, full 4096 ADC bins
;    gain_nominal    - gain, dim 12x32 returned from the current or selected ELUT, full 4096 ADC bins, expressed in keV/bin ~ 0.10 keV/adc bin
;
;
; :Author: rschwartz70@gmail.com, 28-jun-2019.
;-
pro stx_calib_fit_process, obj, spectra, $
  all_fits, $
  offset_nominal = offset_nom, gain_nominal = gain_nom, $
  filename = filename, $
  det_id_range = det_id_range, path = path

  if n_dimensions( spectra ) lt 3 || n_elements( offset_nom ) ne 384 || n_elements( gain_nom) ne 384 then begin


    default, path, [curdir(), concat_dir( concat_dir('ssw_stix','dbase'),'detector')]
    ;Get the data and previous offsets and gains,
    ;Expect this input to be more fully developed in the future, 29-jun-2019
    stx_calib_fit_data_prep, offset_nom, gain_nom, spectra, path = path
  endif
  ;In case the fitting has to be restarted then find the existing all_fits*.fits 
  default, filename, 'all_fits_'+ time2file(anytim( systime(1), fid='sys'),/date) + '.fits'
  ;If the filename is supplied and exists then we start from the current file
  if file_exist(filename) then begin
    all_fits = reform( mrdfits( filename, 1 ), 12,32)
    ;if det_id_range not supplied, generate it from the missing id
    ;if the det_id_range is supplied, it will supercede the one to be
    ;obtained by looking only at the last det_id completed
    if ~keyword_set( det_id_range ) then begin
      det_id_range = [(where( all_fits[11,*].ip ne 11, count))[0], 31]
      if count eq 0 then begin
        message, /info, 'Fitting completed, look at all_fits
        return ;all_fits is complete
      endif
    endif
  endif
  default, det_id_range, [0,31]
  det_id_range <= 31
  det_id_range >= 0

  setenv, 'OSPEX_MODELS_DIR=' + concat_dir( getenv('ssw_stix'), concat_dir('dbase','detector'))
  for id = det_id_range[0], det_id_range[1] do begin
    for ip = 0, 11 do begin
      tic
      ;Fit the line complex 31-35 keV and the one line at 81 keV
      stx_calib_fit_single, spectra, offset_nom, gain_nom, ip=ip, id = id, $
        summlo = summlo, summhi=summhi, obj = obj, auto=auto
      toc
      help, ip,id, summhi, summhi
      if ~is_struct( all_fits ) then begin
        all_fits = replicate( {params_lo : summlo.spex_summ_params * 0.0, sigmas_lo: summlo.spex_summ_sigmas*0.0, $
          function_lo: '', $ summlo.spex_summ_fit_function, $
          params_hi : summhi.spex_summ_params * 0.0, sigmas_hi: summhi.spex_summ_sigmas * 0.0, $
          function_hi: '', $ summhi.spex_summ_fit_function, $
          ip: ip, id:id, gainfit:0.0d0, offsetfit:0.0d0, time:''}, 12, 32 )
      endif
      all_fits[ ip, id ].params_lo = summlo.spex_summ_params
      all_fits[ ip, id ].sigmas_lo = summlo.spex_summ_sigmas
      all_fits[ ip, id ].function_lo = summlo.spex_summ_fit_function
      all_fits[ ip, id ].params_hi = summhi.spex_summ_params
      all_fits[ ip, id ].sigmas_hi = summhi.spex_summ_sigmas
      all_fits[ ip, id ].function_hi = summhi.spex_summ_fit_function

      all_fits[ ip, id ].ip     = ip
      all_fits[ ip, id ].id     = id
      all_fits[ ip, id ].gainfit = gain_nom[ ip, id]
      all_fits[ ip, id ].offsetfit = offset_nom[ ip, id]
      all_fits[ ip, id ].time = anytim( systime(1), fid='sys', /vms)
      ;if ip ge 1 then stop
    endfor

    ;update the file
    if file_exist( filename ) then file_move, filename, 'temp.fits',/overwrite
    mwrfits, all_fits, filename
    if file_exist( 'temp.fits' ) then file_delete, 'temp.fits'

  endfor
end