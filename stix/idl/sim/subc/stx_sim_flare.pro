;+
; :description:
;    This function simulates the detector counts recorded in all STIX
;    subcollimators for a solar flare from a given source location and
;    Gaussian width.
;
; :params:
;
;
; :keywords:
;    sky_xcen:    in, optional, type="float", default="0"
;                 source centroid in Heliocentric X arcseconds in the
;                 plane-of-sky. Positive corresponds to Solar West.
;
;    sky_ycen:    in, optional, type="float", default="0"
;                 source centroid in Heliocentric Y arcseconds in the
;                 plane-of-sky. Positive corresponds to Solar North.
;
;    sky_fwhm:    in, optional, type="float", default="0"
;                 Gaussian source full-width at half maximum (FWHM) in 
;                 arcseconds.
;
;    sky_flux:    in, optional, type="long", default="10000"
;                 flux of simulated source photons in cm^-2. This is
;                 not the total number of photons simulated to fall on
;                 the STIX front face subcollimators, which is instead
;                 32 x 2.2 x 2.0 x sky_flux (i.e., 32 subcollimators, 
;                 each with dimensions of 22 mm by 20 mm).
;
;    bkg_flux:    in, optional, type="long", default="10"
;                 flux of simulated background photons in cm^-2. This is
;                 not the total number of background photons simulated
;                 as being "recorded" by the STIX detectors, which is
;                 instead 32 x 0.88 x 0.92 x bkg_flux (i.e., 32 detector
;                 units, each with dimensions of 8.8 mm by 9.2 mm).
;
;    src_dur:     in, optional, type="long", default="1"
;                 total temporal duration to be simulated in s. This
;                 is used in conjunction with the flux of source
;                 photons to calculate the total number of photons for
;                 each source simulated.
;
;    subc_file:   in, optional, type="string", default="$STX_GRID/stx_subc_params.txt"
;                 full file path of subcollimator characteristics
;                 look-up file.
;
;    subc_det_n:  out, type="byte", default="empty/false"
;                 32-element array containing subcollimator detector 
;                 numbers.
;
;    subc_label:  out, type="string", default="empty/false"
;                 32-element array containing subcollimator 
;                 resolution/orientation labels.
;
;    ph_loc:      out, type="float", default="empty/false"
;                 [n, 2, 3] array containing the locations for n
;                 photons (1st dimension) in coordinates of [X, Y]
;                 relative to the STIX optical axis (2nd dimension),
;                 at the [front grid, rear grid, detector] planes
;                 (3rd dimension) that are actually recorded.
;
; :returns:
;    [12, 32] array containing recorded photon counts in all detector
;    pixels of all subcollimators (30 Fourier channels, 1 coarse flare
;    locator, and 1 flux monitor).
;
; :errors:
;    If an incorrect number of background flux values are provided 
;    (neither 32 nor 1), this function returns -1.
;
; :history:
;    21-Aug-2012 - Shaun Bloomfield (TCD) and Tomek Mrozek (Wro),
;                  created routine
;    20-Nov-2012 - Shaun Bloomfield (TCD), implemented final angle
;                  conventions
;    06-Dec-2012 - Shaun Bloomfield (TCD), added photon locations as
;                  an optional output and removed sky background
;    14-Jan-2013 - Shaun Bloomfield (TCD), new keyword default logic
;                  and revised subcollimator structure tagnames
;    22-Jan-2013 - Laszlo I. Etesi (FHNW), returning stx_pixel_data
;                  instead of "raw obs" data
;    25-Jan-2013 - Shaun Bloomfield (TCD), changed definition of sky
;                  source width from 1-sigma to FWHM
;    30-Apr-2013 - Shaun Bloomfield (TCD), changed sky source counts
;                  to flux, added background flux, vectorized photon
;                  handling, and made inputs optional with defaults
;    21-Aug-2013 - Shaun Bloomfield (TCD), fixed environmental typo,
;                  changed getenv('SSW_GRID') to getenv('STX_GRID')
;    15-Oct-2013 - Shaun Bloomfield (TCD), integrated multiple source
;                  generation and added temporal duration
;    23-Oct-2013 - Shaun Bloomfield (TCD), source flux, position and
;                  geometry defined as that being viewed from 1 AU,
;                  with values altered to STIX viewpoint
;    25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator 
;                  reading routine stx_construct_subcollimator.pro
;                  and incorporated modified structure tagnames
;    05-Nov-2013 - Shaun Bloomfield (TCD), modified to output list of
;                  photons (as a stx_sim_photon structure array) and
;                  optional output of a single ideal-grid pixel_data
;                  structure. Modified for dimension ordering of new
;                  flat pixel_data structure.
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), removed background inputs from stx_sim_photon_path, 
;                  "made it work" with the recently introduced changes to the simulation
;    17-Jun-2015 - ECMD (Graz), previously the source structure was not passed to stx_sim_photon_path 
;                  but this is now needed                   
;                  
;-
function stx_sim_flare, src_struct=src_struct, src_file=src_file, src_widget=src_widget, $
                        src_shape=src_shape, src_xcen=src_xcen, src_ycen=src_ycen, src_fwhm_wd=src_fwhm_wd, $
                        src_fwhm_ht=src_fwhm_ht, src_phi=src_phi, src_loop_ht=src_loop_ht, src_duration=src_duration, $
                        src_flux=src_flux, src_distance=src_distance, src_spectra=src_spectra, bkg_flux=bkg_flux, $
                        bkg_duration=bkg_duration, subc_file=subc_file, subc_det_n=subc_det_n, subc_label=subc_label, $
                        ph_loc=ph_loc, pixel_data=pixel_data, _extra=_extra
  
  ;  Set optional keyword defaults
  src_struct_flag = data_chk(src_struct, /struct)
  src_file_flag = file_exist(src_file)
  src_widget = keyword_set(src_widget)
  default, src_struct, stx_sim_source_structure()
  default, src_shape, 'point'
  default, src_xcen, 0.
  default, src_ycen, 0.
  default, src_duration, 1l
  default, src_flux, 10000l
  default, src_distance, 1.
  default, src_fwhm_wd, 0.
  default, src_fwhm_ht, 0.
  default, src_phi, 0.
  default, src_loop_ht, 0.
  default, src_spectra, 0.
  default, bkg_flux, lonarr(32)+10
  default, bkg_duration, src_struct.duration
  subc_file = exist(subc_file) ? subc_file : loc_file( 'stx_subc_params.txt', path = getenv('STX_GRID') )
  
  ;  Ensure duration is positive and non-zero
  src_struct.duration = src_struct.duration > 1
  src_duration = src_duration > 1
  bkg_duration = bkg_duration > 1
  
  ;  Run through hierarchy of optional input formats
  case 1 of 
     ;  Test input source structure for correct format, returning 
     ;  error code if it is not a 'stx_sim_source' named structure
     src_struct_flag:  if ( ppl_typeof( src_struct ) eq 'stx_sim_source_array' or $
                            ppl_typeof( src_struct ) eq 'stx_sim_source' ) then $
                          ;  Create photon structure from input
                          ;  source structure
                          ph_src = stx_sim_multisource_sourcestruct2photon( src_struct ) $
                          ;  Otherwise, create photon structure from
                          ;  widget interface
                       else begin
                          print, 'Incorrect structure format provided, expects {stx_sim_source}'
                          print, 'Launching widget interface...'
                          ph_src = stx_sim_widget_set_sources()
                       endelse
     ;  load a text file containing parameters of simulated sources
     src_file_flag:  if file_exist(src_file) then begin
                        ;  Load photon source(s) information table file
                        src_struct = stx_sim_load_tabstructure( src_file )
                        ;  Create photon structure containing all photons from all sources
                        ph_src = stx_sim_multisource_sourcestruct2photon( src_struct )
                     endif else begin
                        print, 'File "'+strtrim(src_file, 2)+'" does not exist'
                        print, 'Launching widget interface...'
                        ph_src = stx_sim_widget_set_sources()
                     endelse
     ;  Run source simulation widget
     src_widget ne 0b:  ph_src = stx_sim_widget_set_sources()
     ;  Otherwise, build source structure from individually input 
     ;  source keywords
     else:  begin
               ;  Determine number of source-type definitions
               n_src = n_elements(src_shape)
               ;  Test that all source-specifying keywords have 
               ;  the same number of elements
               if ( ( n_elements(src_xcen)     eq n_src ) and $
                    ( n_elements(src_ycen)     eq n_src ) and $
                    ( n_elements(src_fwhm_wd)  eq n_src ) and $
                    ( n_elements(src_fwhm_ht)  eq n_src ) and $
                    ( n_elements(src_phi)      eq n_src ) and $
                    ( n_elements(src_loop_ht)  eq n_src ) and $
                    ( n_elements(src_duration) eq n_src ) and $
                    ( n_elements(src_flux)     eq n_src ) and $
                    ( n_elements(src_distance) eq n_src ) and $
                    ( n_elements(src_spectra)  eq n_src ) ) then begin
                       ;  Create final source structure
                       src_struct = replicate( stx_sim_source_structure(), n_src )
                       src_struct.source_id   = 1+indgen(n_src)
                       src_struct.shape    = src_shape
                       src_struct.xcen     = src_xcen
                       src_struct.ycen     = src_ycen
                       src_struct.duration = src_duration
                       src_struct.flux     = src_flux
                       src_struct.distance = src_distance
                       src_struct.fwhm_wd  = src_fwhm_wd
                       src_struct.fwhm_ht  = src_fwhm_ht
                       src_struct.phi      = src_phi
                       src_struct.loop_ht  = src_loop_ht
                       ;src_struct.spectra  = src_spectra
                    ;  Return error code if source-specifying
                    ;  keywords do not have matching element numbers
                    endif else return, -98
               ;  Create photon structure containing all photons from all sources
               ph_src = stx_sim_multisource_sourcestruct2photon( src_struct )
            end
  endcase
  
  ;  Ensure background flux values are positive
  bkg_flux = bkg_flux > 0
  
  ;  Determine number of background flux values supplied
  n_bkg = n_elements(bkg_flux)
  ;  Check if values are provided for each subcollimator
  if ( n_bkg ne 32 ) then $
     ;  When only one value is provided, repeat value for all 
     ;  32 subcollimators
     if ( n_bkg eq 1 ) then bkg_flux = replicate( bkg_flux, 32 ) else begin
           ;  Otherwise return error message
           print, 'Incorrect background flux format -- should be a single value or a 32-element array'
           return, -1
        endelse
  
  ;  Build subcollimator geometry structure from look-up file
  subc_str = stx_construct_subcollimator( subc_file )
  ;  Check valid subcollimator structure exists
  if ~data_chk( subc_str, /struct ) then return, subc_str
  
  ;  Create subcollimator detector number and resolution/orientation 
  ;  arrays for optional output
  subc_det_n = subc_str.det_n
  subc_label = subc_str.label
  
  ;  Determine detector pixel and subcollimator indices for each
  ;  simulated photon (i.e., all sources and background)
  ;    N.B. Number of elements in ph_src is expanded by creation
  ;         of background photons in stx_sim_photon_path.pro
  det_sub = stx_sim_photon_path( ph_src, subc_str, src_struct, $;bkg_flux, bkg_duration, $
                                 ph_loc = ph_loc, _extra = _extra )
  
  
  ;  Create pixel data structure from obs
  pixel_data = stx_construct_pixel_data( live_time = (fltarr(16)+1.), energy_range = [0., 1.], $
                                   time_range = stx_construct_time(time = [anytim(0,/mjd), anytim(1,/mjd)]), $
                                   counts = det_sub )
  
  ;  Pass out simulated source and background photon list
  return, ph_src
  
end
