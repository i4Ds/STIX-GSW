;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_fits_info_params
;
; :description:
;    This procedure generates a structure containing useful spectroscopy info parameters which will then
;    be written out to the spectrum and srm FITS files.
;
;
; :categories:
;    spectroscopy, fits, info
;
; :keywords:
;
;    fits_path_data : in, type="string"
;                     The path to the sci-xray-cpd (or sci-xray-l1) observation file;
;
;    data_level : in, type="long"
;                 The STIX science data compression level of the observation
;
;    distance : in, type="float", default= "1."
;               The distance between Solar Orbiter and the Sun centre in Astronomical Units needed to correct flux.
;
;    time_shift : in, type="float", default="0."
;                 The difference in seconds in light travel time between the Sun and Earth and the Sun and Solar Orbiter
;                 i.e. Time(Sun to Earth) - Time(Sun to S/C)
;
;    fits_path_bk : in, type="string"
;                   The path to file containing the background observation this should be in pixel data format
;                   i.e. sci-xray-cpd (or sci-xray-l1)
;
;    uid : in, type="ulong"
;          Unique Request ID for the Observation
;
;    generate_fits : in, type="boolean"
;                    If set spectrum and srm FITS files will be generated and read using the stx_read_sp using the
;                    SPEX_ANY_SPECFILE strategy. Otherwise use the spex_user_data strategy to pass in the data
;                    directly to the ospex object.
;
;    specfile : in, type="string", default="'stx_spectrum_' + UID + '.fits'"
;               File name to use when saving the spectrum FITS file for OSPEX input.
;
;    srmfile : in, type="string"
;              File name to use when saving the srm FITS file for OSPEX input.
;
;    elut_file : in, type="string",
;                String with filename of ELUT csv
; :returns:
;    Structure containing all input values to be passed to stx_write_ospex_fits and written out to
;    the spectrum and srm FITS files.
;
;
; :examples:
;      fits_info_params = stx_fits_info_params( fits_path_data = fits_path_data, data_level = data_level, $
;    distance = distance, time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
;    generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_filename)
;
; :history:
;    17-Aug-2022 - ECMD (Graz), initial release
;    05-Apr-2023 - ECMD (Graz), fix issue with taking header distance as default 
;
;-
function stx_fits_info_params, fits_path_data = fits_path_data, data_level = data_level, $
  distance = distance,  time_shift = time_shift, fits_path_bk = fits_path_bk, uid = uid, $
  generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_file

  if n_elements(generate_fits) ne 0 then begin
    if generate_fits eq 0 and keyword_set(specfile) || keyword_set(srmfile) then begin
      message, 'FITS file generation has been set to 0 but an output filename has been specified.'
    endif
  endif

  background_subtracted = keyword_set(fits_path_bk)

  default, generate_fits, 1
  default, specfile, ''
  default, srmfile, ''
  default, elut_file, ''
  default, fits_background_file, ''
  default, detused, ''
  
  ;if distance is not set use the average value from the fits header
  stx_get_header_corrections, fits_path_data, distance = header_distance
  default, distance, header_distance
  print, 'Using Solar Orbiter distance of : ' + strtrim(distance,2) +  ' AU'
  
  break_file, fits_path_data, disk, dir, data_file_name, ext
  fits_data_file = data_file_name + '.fits'
  if background_subtracted then begin
    break_file, fits_path_bk, disk, dir, bk_file_name, ext
    fits_background_file = bk_file_name + '.fits'
  end

  if specfile ne '' then begin
    break_file, specfile, disk, dira, sp_file_name, ext
    specfile = sp_file_name + '.fits'
  end

  if srmfile ne '' then begin
    break_file, srmfile, disk, dir, rm_file_name, ext
    srmfile = rm_file_name + '.fits'
  end


  stx_fits_info = {uid:uid, fits_data_file:fits_data_file, data_level:data_level, $
    distance:distance, time_shift:time_shift, grid_factor:0., $
    background_subtracted:background_subtracted, fits_background_file:fits_background_file, $
    generate_fits:generate_fits, specfile:specfile, srmfile:srmfile, elut_file:elut_file, detused:detused}

  return, stx_fits_info

end