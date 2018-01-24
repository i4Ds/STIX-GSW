;+
;;; start from modulation count profiles and reconstruct the photon image
;;;
;;; x is the image, y is the modulation profile
;;;
;;; H # x = y where x is the photon map, y is the count modulation profile set
;;; H is given by the function :
;;; map=hsi_annsec_profile(image, cbe_obj )
;;; ( or xp = img_obj -> getdata(class='hsi_modul_profile', vimage=scaled_vimage)
;;;   where xp - array of pointers to image profiles - array since 9-detectors )
;;;
;;; Standard RL algorithm is given by:
;;;
;;;                       y
;;;               H^T # -------
;;;                      H # x
;;;; x  =   x  *  -----------------
;;;                  H^T # 1
;;;
;;; H^T is given by the function : hsi_pixon_bproj
;;;
;;;
;;; The number of modulation profiles is generally 9
;;; To get data y, we subdivide the observation time interval in several intervals.
;;; The finer the subdivision is, higher the cardinality of the data.
;;; At the same time, the worse is the SNR.
;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
function em_spectra, counts, drm_str, model = model, kernel=kernel

  ;default, kernel, gauss1( findgen(25), [12, 4., 1] )

  ;x is the photon spectrum in counts per bin
  ;y is observed counts per bin
  ;H is the drm.smatrix  rescaled
  ;Model is the photon spectrum in photons/kev from which counts is derived

  edge_products, drm_str.edges_out, width=cwidth, gmean = cgm
  edge_products, drm_str.edges_in, width = pwidth, gmean = pgm
  y = counts
  dim = size(/dim, drm_str.smatrix)
  H = drm_str.smatrix * drm_str.area * rebin( cwidth, dim )
  one = fltarr( dim[0] )+1.0
  HT = transpose( H )
  x = fltarr( dim[1] ) + 1.0 ;initial
  ;;;                       y
  ;;;               H^T # -------
  ;;;                      H # x
  ;;;; x  =   x  *  -----------------
  ;;;                  H^T # 1
  !p.multi = [0, 2, 1]
  for i=0,99 do begin
    xn = x * ( HT # ( y / ( H # X )) / (HT # One))

    x = xn
    if i mod 10 eq 0 then begin
      plot, pgm, x / pwidth, psy=1, /ylog, /xlog
      oplot, pgm, model
      plot, /xlog, cgm, counts - H # X, psym=4
      wait, 0.1
    endif

  endfor



  return, x/pwidth
end
;+
;Name: STX_Spectrum_Inversion_Param_Free
;
;Purpose: The is a demonstration model of a parameter free inversion of a STIX
;count rate spectrum into a photon spectrum
;
;-
;
pro STX_Spectrum_Inversion_Param_Free, out

  ct_edg= (stx_science_energy_channels()).edges_1 ;get_edges( /edges_2, get_uniq( [findgen(50)+3.,findgen(50)*4+53]) );(

  ph_edg= findgen(300)*.5+3 ;get_uniq( [ct_edg, 2*ct_edg] )
  wct = get_edges(/widt, ct_edg)
  wph  = get_edges(/widt, ph_edg)
  gct = get_edges( /gmean, ct_edg)
  gph = get_edges(/gmean, ph_edg)

  drm = stx_build_drm( ct_edg, ph_en=ph_edg)
  drmi = stx_build_drm( ct_edg, ph_en=ct_edg)
  smatrix = drmi.smatrix
  smatrixi = invert( smatrix, /double )
  a=[10.,4., 3200., 4.0, 50, 3200.]
  ph=f_thick2( get_edges(/edges_2, ph_edg), a)
  phi = f_thick2( get_edges(/edges_2, ct_edg), a)
  ctperkev = drm.smatrix # (ph * wph)
  ctperbin = ctperkev * wct
  mc_ctperbin = poidev( ctperbin, seed=seed )
  phperkev = (smatrixi # ctperkev)/wph