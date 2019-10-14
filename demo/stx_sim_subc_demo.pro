; Document name: stx_sim_subc_demo.pro
; Created by:    Nicky Hochmuth, 2012/09/17
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_sim_subc_demo
;
; PURPOSE:
;       helper method to run and visualise the grid response simulation by Shaun Bloomfield
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;
;       stx_sim_subc_demo
;       simulates a gausian point source at x,y(0,0) with radius of 0 and 10000 photons cm^-2
;
;       stx_sim_subc_demo, SRC_XCEN=20, SRC_YCEN=30, SRC_FLUX=30000
;       simulates a gausian  source at x,y(20,30) with radius of 0 and 30000 photons cm^-2
;
; HISTORY:
;       17-Sep-2012 - Nicky Hochmuth (FHNW), initial release
;       15-Jan-2013 - Shaun Bloomfield (TCD), revised subcollimator structure tagnames
;       20-Feb-2013 - Nicky Hochmuth (FHNW), changes to keywords
;       14-Apr-2013 - Laszlo I. Etesi (FHNW), changed subcollimator parameter file reading (temporary)
;       30-Apr-2013 - Shaun Bloomfield (TCD), changed source counts to flux and added background flux
;       29-Jul-2013 - Richard Schwartz (gsfc), fixed some documentation typos
;       14-Oct-2013 - Richard Schwartz (gsfc), added help keyword to display documentation
;       14-Oct-2013 - Laszlo I. Etesi (FHNW), removed version 1
;       06-Nov-2013 - Shaun Bloomfield (TCD), added configuration
;                     settings for call to modified stx_sim_flare.pro
;       05-Nov-2014 - Laszlo I. Etesi (FHNW), using non-ambiguous keywords
;-

;+
; :description:
;    runs and visualizes the grid response simulation by Shaun Bloomfield .
;    a gaussian point source is simulated
;
; :keywords:
;    src_xcen:  in, type="double", default="0"
;               source centroid in Heliocentric X arcseconds in the
;               plane-of-sky. Positive corresponds to Solar West.
;
;    src_ycen:  in, type="double", default="0"
;               source centroid in Heliocentric Y arcseconds in the
;               plane-of-sky. Positive corresponds to Solar North.
;
;    src_fwhm:  in, type="double", default="0"
;               Gaussian source full-width half-maximum in arcseconds.
;
;    src_flux:  in, type="long", default="10000"
;               flux of simulated source photons in cm^-2. This is
;               not the total number of photons simulated to fall on
;               the STIX front face subcollimators, which is instead
;               32 x 2.2 x 2.0 x src_flux (i.e., 32 subcollimators,
;               each with dimensions of 22 mm by 20 mm).
;
;    bkg_flux:  in, type="long", default="10"
;               flux of simulated background photons in cm^-2. This is
;               not the total number of background photons simulated
;               as being "recorded" by the STIX detectors, which is
;               instead 32 x 0.88 x 0.92 x bkg_flux (i.e., 32 detector
;               units, each with dimensions of 8.8 mm by 9.2 mm).
;
;    save:      in, type="bool", default="empty/false"
;               if set the demo will dump the simulation result
;               (stx_pixel_data, visibilities and map) in a local file.
;
;    map:       out, type="hsi_map", default="empty/false"
;               returns the map of the back brojection
;
;    pixel_data: in/out, type="stx_pixel_data", default="empty/false"
;               input/output variable; if not set it returns the result
;               of the simulation in the pixel data.
;
;    visibilities: in/out, type="stx_vis", default="empty/false"
;               input/output variable; if not set it returns the visibilities
;               created from the simulation result in the pixel data.
;
;-
pro stx_sim_subc_demo, src_shape=src_shape, src_xcen=src_xcen, src_ycen=src_ycen, src_fwhm_wd=src_fwhm_wd, $
                       src_fwhm_ht=src_fwhm_ht, src_phi=src_phi, src_loop_ht=src_loop_ht, src_duration=src_duration, $
                       src_flux=src_flux, src_distance=src_distance, src_spectra=src_spectra, bkg_flux=bkg_flux, $
                       bkg_duration=bkg_duration, save=save, map=map, pixel_data=pixel_data, visibilities=visibilities,help=help
  if keyword_set( help ) then begin
    stx_help_doc, 'stx_sim_subc_demo'
    return
  endif
  
  sas  = stx_analysis_software()
  sas->set, $
            sim_src_shape    = src_shape,     $
            sim_src_xcen     = src_xcen,     $
            sim_src_ycen     = src_ycen,     $
            sim_src_duration = src_duration, $
            sim_src_flux     = src_flux,     $
            sim_src_distance = src_distance, $
            sim_src_fwhm_wd  = src_fwhm_wd,  $
            sim_src_fwhm_ht  = src_fwhm_ht,  $
            sim_src_phi      = src_phi,      $
            sim_src_loop_ht  = src_loop_ht,  $
            sim_src_spectra  = src_spectra,  $
            sim_bkg_flux     = bkg_flux,     $
            sim_bkg_duration = bkg_duration
            
  if(keyword_set(pixel_data) and keyword_set(visibilities)) then message, "Please only set one input variable; either 'visibilities' or 'pixel_data'." 
  
  if(keyword_set(pixel_data)) then input_data = pixel_data $
  else pixel_data = sas->getdata(out_type='stx_pixel_data',skip_ivs=1)
  
  if(keyword_set(visibilities)) then input_data = visibilities $
  else visibilities = sas->getdata(input_data=input_data, out_type='stx_visibility',skip_ivs=1)
  
  src_xcen = sas->get(/sim_src_xcen)
  src_ycen = sas->get(/sim_src_ycen)
  src_fwhm_wd = sas->get(/sim_src_fwhm_wd)
  src_fwhm_ht = sas->get(/sim_src_fwhm_ht)
  src_flux = sas->get(/sim_src_flux)
  bkg_flux = sas->get(/sim_bkg_flux)
  
  if keyword_set(save) then save, pixel_data, visibilities, map, $
                                  file='sim_'+strjoin(trim([src_xcen,src_ycen,src_fwhm_wd,fwhm_ht]),'_')+'.sav'
  
  stx_pixel_data_viewer, sas , title='SimulationData: '+strjoin(trim([src_xcen,src_ycen,src_fwhm_wd,src_fwhm_ht,src_flux,mean(bkg_flux)]),' '), multi=0
  
end