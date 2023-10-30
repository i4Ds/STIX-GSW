;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_location4spectroscopy
;
; :description:
;    This converts a flare location from Helioprojective Cartesian coordinate frame at Solar Orbiter (HPC) to STIX coordinate frame (STX)
;    for calculation of grid transmission. 
;    
; :categories:
;    spectroscopy, transmission 
;
; :keywords:
;    flare_location_hpc : in, type="2 element float array"
;               the location of the flare (X,Y) in Helioprojective Cartesian coordinates as seen from Solar Orbiter [arcsec]
;               If input the HPC flare location will be transformed to the STIX coordinate frame
;               Otherwise a dummy array of [Nan, Nan] will be passed out to the given named variable
;               
;    aux_fits_file :in, required if flare_location_hpc is passed in, type="string"
;                the path of the auxiliary ephemeris FITS file to be read."
;    
;    time_range: in, type="string array"
;                array containing the UTC start time and end time of the spectrogram
;
; :returns:
;    flare_location_stx: out, type="2 element float array"
;    the flare location in the STIX coordinate frame
;
; :examples:
;   
;   flare_location_hpc = [-1550,-800]
;   aux_fits_file = '/STIX-GSW/stix/dbase/demo/imaging/solo_L2_stix-aux-ephemeris_20200607_V01.fits'
;   time_range = ['07-Jun-20 21:37:09.684', '07-Jun-20 21:52:08.784']
;   flare_location_stx = stx_location4spectroscopy( flare_location_hpc = flare_location_hpc , aux_fits_file = aux_fits_file, time_range = time_range)
;
; :history:
;    15-Jun-2023 - ECMD (Graz), initial release
;
;-
function stx_location4spectroscopy, flare_location_hpc = flare_location_hpc, aux_fits_file = aux_fits_file, time_range = time_range

  if n_elements(flare_location_hpc) ne 0 then begin
    
    if n_elements(aux_fits_file) eq 0 then $
      message, 'To correct for flare location the corresponding auxiliary ephemeris file must be provided.' $
    else aux_data = stx_create_auxiliary_data(aux_fits_file, time_range)
    
    flare_location_stx = stx_hpc2stx_coord(flare_location_hpc, aux_data)
  endif else begin

    print,'Flare location data not provided, using on-axis approximation.'
    flare_location_stx = [0.,0.]
    flare_location_hpc = [!values.f_nan,!values.f_nan]
  endelse

  return, flare_location_stx
  end