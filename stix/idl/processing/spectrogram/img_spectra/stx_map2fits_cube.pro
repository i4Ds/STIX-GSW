
;+
; :Description:
;    STX_MAP2FITS_CUBE is a procedure that takes a STIX map structure which conforms to a 4-d 
;    x, y, energy, time cube and writes it to an MAP FITS file. A SUMMARY extension is included
;    which gives the time and energy axes for the cube.
;
; :Params:
;    image_str
;    IDL> help, image_str,/st
;        ** Structure <1edad2f0>, 8 tags, length=275160, data length=275128, refs=1:
;        DIRTY_MAP       STRUCT    -> <Anonymous> Array[1]
;        RESID_MAP       STRUCT    -> <Anonymous> Array[1]
;        MAP_CL_RES      STRUCT    -> <Anonymous> Array[1]
;        MAP             STRUCT    -> <Anonymous> Array[1]
;        TYPE            STRING    'stx_image'
;        ALGO            STRING    'clean'
;        TIME_RANGE      STRUCT    -> STX_TIME Array[2]
;        ENERGY_RANGE    FLOAT     Array[2]
;    filename - fits filename to be written, should append FITS suffix. not done automatically
;    maps
;
; :Keywords:
;    energy_axis - extracted from image_str
;    time_axis   - extracted from image_str
;    date_obs    - optional, added to time_axis from image_str, anytim format
;    asw_obj     - object that created image_str
;
; :Author: 27-sep-2016, rschwartz70@gmail.com
;-
pro stx_map2fits_cube, image_str, filename, maps, energy_axis = energy_axis, time_axis = time_axis, $
  date_obs = date_obs, asw_obj = asw
  default, DATE_OBS, '13-SEP-2019'

  default, rcr, 1
  default, filename, 'stix_cube_test.fits'
  image_str = is_struct( image_str ) ? image_str : asw->getdata(out_type='stx_cube_image')
  
  stx_map2fits_cube_axes, image_str, map, energy_axis, time_axis
  
  ;use map2fits to make the map structure fits header and then
  ;use mwrfits to write the specific information
  map2fits, map, filename
  
  ;write a summary extension that gives energy axis and time axis
  summary = {energy_axis: energy_axis, time_axis: time_axis, date_obs: anytim( date_obs, /vms),$
    time_axis_vms: anytim( anytim( date_obs ) + time_axis, /vms )}
  mwrfits, summary, filename, /silent
  fits_info, filename, /silent, n_ext=n_ext
  fxhmodify,filename,extension = n_ext, 'EXTNAME ', 'SUMMARY INFO'
  ;Add a few more keywords to the header, this is meant to become more refined in the future
  hdr = headfits( filename )
  sxaddpar, hdr, 'ORIGIN ','SOLAR PROBE'

  sxaddpar, hdr, 'TELESCOP','STIX'
  sxaddpar, hdr, 'INSTRUME', 'STIX'
  sxaddpar, hdr, 'FILETYPE','IMAGE CUBE'
  sxaddpar, hdr, 'ENERGY_L', string( energy_axis[0] )
  sxaddpar, hdr, 'ENERGY_H', string( energy_axis[-1] )
  sxaddpar, hdr, 'DATE_END', last_item( summary.time_axis_vms )
  sxaddpar, hdr, 'TIMEUNIT', 's     ','Does not take leap seconds into account'
  sxaddpar, hdr, 'IMAGE_ALG', image_str[0].algo
  sxaddpar, hdr, 'DATAUNIT','Photons cm!u-2!n s!u-1!n'
  ;put the header back after updating
  modfits, filename, o, hdr

  ;Common values go into a control extension and uniq values go into a summary extension
  ;map2fits, map, filename
end

;Get cube axes
