;+
;This is a demonstration of creating STIX calibration line spectra, compressing the data into subspectra
;Reading the subspectra, and extracting the line parameters after fitting the spectra with a background model 
;plus the Barium calibration lines
; 29-nov-2017, RAS
;-

  stx_bkg_sim_demo, /x4, spec=sp
  
  drm = stx_build_drm( sp.e_axis.edges_2, /background)
  
  stx_write_ospex_fits, spectrum = sp, specfilename= 'Cal_bkg_dev.fits', srmdata=drm, srmfilename = 'Cal_bkg_dev_drm.fits'
  
  ;obj=ospex()
  stx_cal_script, obj=obj, $
    spex_specfile= '.\Cal_bkg_dev.fits', spex_drmfile= '.\Cal_bkg_dev_drm.fits',_extra = _extra
  fit_params = obj->get(/spex_summ_params)
  fit_sigmas = obj->get(/spex_summ_sigma)
;The cal line parameters are in fit_params[[ 4, 7, 10]]
;  IDL> print, fit_params[ [4, 7, 10]]
;   30.8512      35.1231      80.9584

end

