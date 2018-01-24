
;+
; :Description:
;    STX_MAP2FITS_CUBE_AXES is a procedure that extracts maps and axes
;    from a stix image structure. The data is assumed to be a 4-d cube
;    with maps of the same size and dimension.  To be a cube
;    the maps must fall and cover the extracted energy and time axes
;          IDL> help, image_str,/st
;          ** Structure <1edad2f0>, 8 tags, length=275160, data length=275128, refs=1:
;          DIRTY_MAP       STRUCT    -> <Anonymous> Array[1]
;          RESID_MAP       STRUCT    -> <Anonymous> Array[1]
;          MAP_CL_RES      STRUCT    -> <Anonymous> Array[1]
;          MAP             STRUCT    -> <Anonymous> Array[1]
;          TYPE            STRING    'stx_image'
;          ALGO            STRING    'clean'
;          TIME_RANGE      STRUCT    -> STX_TIME Array[2]
;          ENERGY_RANGE    FLOAT     Array[2];
; :Output Params:
;    image_str - input STIX image map structures
;    map       - map object structures
;    energy_axis -
;    time_axis
;
;
;
; :Author: 27-sep-2016, rschwartz70@gmail.com
;-
pro stx_map2fits_cube_axes, image_str, map, energy_axis, time_axis

  map = image_str.map
  nmap = n_elements( map )
  energy_range = image_str.energy_range
  num_ebin = n_elements( get_uniq( energy_range[0,*], iuniq ) )
  energy_axis = energy_range[*, iuniq]
  time_sec_1979 = anytim( image_str.time_range.value )
  num_tbin   = n_elements(get_uniq( time_sec_1979[0,*], iuniq ) )
  time_axis  = time_sec_1979[ *, iuniq ]
  map = reform(/over, map, [ num_ebin, num_tbin])
end