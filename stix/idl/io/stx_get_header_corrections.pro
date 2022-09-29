;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_get_header_corrections
;
; :description:
;    This procedure reads the ephemeris data in the primary header of a STIX science data FITS file and returns the
;    parameters necessary for spectroscopy. Note that these parameters refer to the centre of the Sun and the average time of the file and so
;    may not be sufficiently accurate for all purposes.
;
; :categories:
;    spectroscopy, FITS
;
; :params:
;    fits_path : in, required, type="string"
;                The path to the STIX science data FITS file.
;
; :keywords:
;    distance    : out, type="float"
;                  The distance between Solar Orbiter and the Sun centre in Astronomical Units
;
;    time_shift  : out, type="float"
;                  Difference in light travel time from the Sun centre to Earth and the Sun centre to Solar Orbiter in seconds.
;                  i.e. Time(Sun to Earth) - Time(Sun to S/C)
;
; :examples:
;
;    fits_path = loc_file('solo_L1A_stix-sci-spectrogram-2104170001_20210417T153019-20210417T171825_033898_V01.fits', path = concat_dir( getenv('STX_DEMO_DATA'),'ospex',/dir) )
;    stx_get_header_corrections, fits_path, distance = distance, time_shift = time_shift
;
; :history:
;    26-Jan-2022 - ECMD (Graz), initial release
;    21-Feb-2022 - ECMD (Graz), documented, added error messages  
;
;-
pro stx_get_header_corrections, fits_path, distance = distance, time_shift = time_shift

  primary_header = headfits(fits_path)

  au = wcs_au()

  abort_message = 'FITS file header. If L1A file was downloaded prior to 08-Feb-2022 please redownload.'

  distance_sun_m = (sxpar(primary_header, 'DSUN_OBS', abort_message, /nan, count = count_distance))

  distance = distance_sun_m/au

  time_shift = (sxpar(primary_header, 'EAR_TDEL', abort_message, /nan,count = count_time))

  if ~(count_distance && count_time) then message, 'Error retrieving parameters from header.'
end
