  ;+
  ; :description:
  ;    this function returns a determination of the detector-averaged background counts from a ql interval (background monitor)
  ;    for this purpose, the function determines if the background determination is enable, if a flare is detected, and then sum the flux over several pixels given by a mask of pixels to determine the background (2 pixels available)
  ;
  ; :categories:
  ;   stix flight software simulator, background
  ;
  ; :params:
  ;   ql_bkgd_accumulator : in, required, type='stx_fsw_ql_bkgd_monitor'
  ;     the latest accumulated background
  ;     
  ;   lt_bkgd_accumulator : in, required, type='stx_fsw_ql_bkgd_monitor_lt'
  ;     the latest livetime for the background
  ;   
  ;   previous_background : in, required, type='fltarr(nql)'
  ;     previous value for background (nql is the number of energy intervals in background accumulators)
  ;     
  ;   background_determination_enable : in, required, type='boolean'
  ;     1 if enable, 0 if disable the background determination (default background is returned)
  ;     
  ;   flare_flag : in, required, type='boolean'
  ;     1 for ongoing flare, 0 if no flare detected
  ;     
  ;   pixel_mask : in, optional, type='bytarr(12)', default='bytarr(12)+1b'
  ;     pixels which should be use are labelled 1
  ;     
  ; :keywords:
  ;   default_background : in, optional, type='fltarr(nql)', default='fltarr(nql) + 1.'
  ;     default value for background (nql is the number of energy intervals in background accumulators)
  ;   
  ; :returns:
  ;   flat array of detector-averaged background counts (counts/sec)
  ;   
  ; :examples:
  ;   background = stx_fsw_background_determination(ql_bkgd_accumulator, lt_bkgd_accumulator, prev_bkgd, bkgd_det_enable, flaretag)
  ;   background = stx_fsw_background_determination(ql_bkgd_accumulator, lt_bkgd_accumulator, prev_bkgd, bkgd_det_enable, flaretag, default_background=[1.,1.2,1.,1.])
  ;   
  ; :history:
  ;   26-may-2014 - Sophie Musset (LESIA), initial release
  ;   27-may-2014 - Laszlo I. Etesi (FHWN), updated routine to work on background ql only (not complete accumulator structure), various small adjustments
  ;   28-jul-2014 - Sophie Musset (LESIA), minor change to declare nql parameter
  ;   28-oct-2014 - Shaun Bloomfield (TCD), corrected BKG subcollimator covered pixel indices
  ;   11-nov-2014 - Shaun Bloomfield (TCD), de-hardcoded multiplying
  ;                 factor for detector-area-to-large-pixel-area. Now
  ;                 calculated from stx_subcollimator_structure
  ;   26-nov-2014 - Shaun Bloomfield (TCD), fixed my own bug for the
  ;                 correct pixel for use in area multiplying factor
  ;   26-may-2015 - Sophie Musset (LESIA) added pixel_mask parameter and calculation of the background is now the sum over the pixels given by pixel_mask
  ;   02-jul-2015 - Laszlo I. Etesi (FHNW), minor cleanup and changes to comments/documentation
  ;   07-jan-2016 - Laszlo I. Etesi (FHNW), updated for new background structure
  ;   07-Dez-2016 - Nicky Hochmuth (FHNW), updated simplified background algo. STIX-TN-0105-FHNW_i2r3_FSW_Background_Determ…ation_signed.pdf
  ; 
  ; :todo:
  ;   26-may-2014 - Sophie Musset (LESIA), check and change default values of nql, xx, yy, default_background, trigger_duration
  ;   26-may-2014 - Sophie Musset (LESIA), what to do with several time intervals in ql accumulators ? here always time interval 0 selected, other ignored
  ;   
  ;-
  
  function stx_fsw_background_determination, ql_bkgd_accumulator, background_determination_enable, default_background=default_background, int_time=int_time
  ;--------------------------------------------------------------------------------------------
  ; values which have to be check but which will be fixed onboard ? (not input of the function)
  ;--------------------------------------------------------------------------------------------
  
  sz = size(ql_bkgd_accumulator.accumulated_counts)      
  nql = sz(1)                                          ; read number of energy bands in background monitor quick_look accumulator
  default, int_time , 32.d                             ; 32 sec
  
  ; default value for default background
  default, default_background, [1UL,1,1,1,1,1,1,1]
  
 
  ;--------------------------------------------------------------------------------------------
  ; determination of detector background count
  ;--------------------------------------------------------------------------------------------
  
  if ~background_determination_enable then begin  ; check if background determination is disable and reaction
    print, '*** background determination disabled ***'
    return, stx_fsw_m_background(n_energies=nql, background=default_background[0:nql])   
  endif else begin
      summed_counts = total(ql_bkgd_accumulator.accumulated_counts, 2, /preserve_type) 
      return, stx_fsw_m_background(background = summed_counts)
  endelse
  
end  
  