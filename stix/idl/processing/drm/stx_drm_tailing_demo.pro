;---------------------------------------------------------------------------
;+
; project:
;       STIX
;
; :name:
;       stx_drm_tailing_demo
;
; :purpose:
;       A demo script comparing stix detector matrices with and without hole tailing
;
; :category:
;       simulation, spectra
;
; :description:
;       the script will create stix detector matrices with and without including the effects
;       of hole tailing due to incomplete charge collection (through the keyword tailing). The response for photon energies of
;       20, 80 and 140 keV is then plotted for both response matrices.
;
; :params:
;       none
;
; :keywords:
;
;    ph_energy     : in, type= "float", default = 1760 evenly spaced (0.1 kev width) bins from 4 kev to 180 kev
;                     1d photon energy bins in kev
;
;    ct_energy     : in, type= "float", default = 1460 evenly spaced (0.1 kev width) bins from 4 kev to 150 kev
;                     1d count energy bins in kev
;
;    trap_length_e : in, type= "float", default =  6.6 [cm]
;                    electron trapping length  = electron mobility * electron lifetime  * electric field strength.
;
;    trap_length_h : in, type= "float", default = 0.2 [cm]
;                    hole trapping length  = hole mobility * hole lifetime  * electric field strength.
;
;    n_bins        : in, type="integer", default =  100000L
;                    number of bins to use for calculation of tailing spectrum
;
;    d_factor_kern : in, type= "float", default = 10
;                    reduction factor of pulse tailing kernel to speed convolution
;
;    window_max    : in, type= "float", default = 1/4
;                    the fraction of the full tailing spectrum at which the window to produce the
;                    convolution kernel should begin
;
;    window_min    : in, type= "float", default = 3/4
;                    the fraction of the full tailing spectrum at which the window to produce the
;                    convolution kernel should end
;
;    eloss_mat     : out, type = "float"
;                    the detector energy loss matrix convolved with the tailing spectra
;
;    pls_ht_mat    : out, type = "float"
;                    pulse-height response matrix, eloss_mat including tailing convolved with energy resolution broadening
;
;    smatrix       : out, type = "float"
;                    pulse-height response matrix including tailing normalized to units of 1/keV
;
;    plotting      : plot the response for photon energies of 20, 80 and 140 keV
;                    for both with and without tailing.
;
;
; :example calling sequence:
;       IDL> stx_drm_tailing_demo, trap_length_e = 5.0 , trap_length_h = 0.3, n_bins = 150000L, $
;                         d_factor_kern = 15, window_min = 1./3., window_max = 2./3., /plotting
;
; :history:
;       15-Apr-2015 – ECMD (Graz), initial release
;
;-
pro stx_drm_tailing_demo, ph_energy = ph_energy, ct_energy =  ct_energy, trap_length_e = trap_length_e, trap_length_h = trap_length_h, n_bins = n_bins, $
    d_factor_kern = d_factor_kern, window_min = window_min, window_max = window_max, $
    plotting = plotting, eloss_mat = eloss_mat_tail, pls_ht_mat = pls_ht_mat_tail, smatrix = smatrix_tail
    
  default, ph_energy, findgen(1800)*0.1+4.0
  default, ct_energy, findgen(1500)*0.1+4.0
  
  ;defaults for tailing parameters are same as in stx_calc_pulse_tailing.pro
  default, trap_length_e , 6.6
  default, trap_length_h,  0.2
  default, n_bins, 100000L
  default, d_factor_kern, 10
  default, window_min, 1./4.
  default, window_max, 3./4.
  
  ;set parameters to match those in stx_build_drm.pro
  detector = 'cdte'
  area = 1.0     ; detector geometric area in cm^2
  func = 'stx_fwhm'     ; returns FWHM in keV
  func_par = 1.0
  
  edge_products, ph_energy, edges_2 = eph2, mean = phmean, width = wout
  edge_products, ct_energy,  mean = emean, width=win, edges_2 = ect2
  
  ;calculate drm without tailing
  drm_no_tailing =  stx_build_drm(ct_energy, ph_energy = ph_energy, d_al = 0.0, d_be = 0.0)
  ;the smatrix is used for the comparison plots
  smatrix = drm_no_tailing.smatrix
  ;the smatrix is used for the comparison plots
  eloss_mat = drm_no_tailing.eloss_mat
  ;set the depth to be the same as that used in stx_build_drm.pro
  depth = drm_no_tailing.d
  
  ;calculate the pulse tailing due to incomplete charge collection and convolve this with
  ;the energy loss matrix using the parameter supplied to the demo if they differ from the defaults
  tailing_eloss_mat =  stx_calc_pulse_tailing( eloss_mat, phmean, emean , depth , detector = detector, trap_length_e = trap_length_e, $
    trap_length_h = trap_length_h, n_bins = n_bins, d_factor_kern = d_factor_kern , $
    window_max = window_max, window_min = window_min)
    
  ;calculate the pulse height matrix and smatrix from the energy loss matrix including tailing
  eloss_mat_tail = stx_tailing_products( tailing_eloss_mat, eph2, ect2, win, wout, func, func_par, area, $
    pls_ht_mat = pls_ht_mat_tail, smatrix = smatrix_tail )
    
  ;if plotting is set show the comparison of smatrix and smatrix_tail
  if keyword_set( plotting ) then begin
    p1 = plot(ct_energy,smatrix(*,160),yrange=[1d-6,1d0],xrange=[4.,150],xtitle='Count energy (keV)',$
      ytitle='detector response for!c20 keV photons', title = 'Comparison of detector responses', layout = [1,3,1], $
      font_size=15, name = 'stx_build_drm', dimensions = [768.,864.])
    p2 = plot(ct_energy,smatrix_tail(*,160),color='red',linestyle=2,/over,/curr, layout = [1,3,1],name = 'drm with tailing', font_size=15)
    leg1 = legend(target=[p1,p2], position=[0.9,0.95], /auto_text_color, font_size=12, shadow = 0)
    
    p3 = plot(ct_energy,smatrix(*,760),yrange=[1d-6,1d0],xrange=[4.,150],xtitle='Count energy (keV)', $
      ytitle='detector response for!c80 keV photons' ,name = 'stx_build_drm',layout = [1,3,2],/curr,/ylog,font_size=15)
      
    p4 = plot(ct_energy,smatrix_tail(*,760),color='red',linestyle=2,/over,/curr,font_size=15,name = 'drm with tailing',layout = [1,3,2])
    leg2 = legend(target=[p3,p4], position=[0.9,0.61], /auto_text_color, font_size=12, shadow = 0)
    
    p5 = plot(ct_energy,smatrix(*,1360),yrange=[1d-6,1d0],xrange=[4.,150],xtitle='Count energy (keV)',$
      ytitle='detector response for!c140 keV photons', name = 'stx_build_drm', layout = [1,3,3],/curr,/ylog,font_size=15)
      
    p6 = plot(ct_energy,smatrix_tail(*,1360),color='red',linestyle=2,/over,/curr,name = 'drm with tailing', layout = [1,3,3])
    leg3 = legend(target=[p5,p6], position=[0.45,0.28], /auto_text_color, font_size=12, shadow = 0)
  endif
  
end
