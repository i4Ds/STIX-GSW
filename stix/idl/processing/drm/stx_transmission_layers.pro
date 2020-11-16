;+
; :Description:
;    Reformats the material and component list from Shane M into a
;    structure that can be easily used in computations
; :Examples:
;  IDL> stx_transmission_layers, component_struct,fits_filename = 'stx_layers.fits'
;  
;  IDL> help, component_struct
;  COMPONENT_STRUCT
;  STRUCT    = -> <Anonymous> Array[16]
;  IDL> help, component_struct,/st
;  ** Structure <1d305240>, 5 tags, length=104, data length=100, refs=1:
;  LAYER           STRING    'front_window'
;  MATERIAL        STRING    'solarblack'
;  MICRONS         DOUBLE           5.0000000
;  ZS              INT       Array[10]
;  GM_PER_CM2      FLOAT     Array[10]
;  IDL> component_struct.layer
;  front_window
;  front_window
;  rear_window
;  grid_covers
;  dem
;  attenuator
;  mli
;  mli
;  mli
;  mli
;  mli
;  mli
;  mli
;  calibration_foil
;  calibration_foil
;  dead_layer
;  IDL> component_struct.material
;  solarblack
;  be
;  be
;  kapton
;  kapton
;  al
;  al
;  kapton
;  al
;  mylar
;  pet
;  kapton
;  al
;  al
;  kapton
;  te_o2
;  IDL> help, mrdfits('stx_layers.fits', 1)
;  MRDFITS: Binary table.  5 columns by  16 rows.
;  <Expression>    STRUCT    = -> <Anonymous> Array[16]
;  IDL> help, mrdfits('stx_layers.fits', 1),/st
;  MRDFITS: Binary table.  5 columns by  16 rows.
;  ** Structure <1d3028a0>, 5 tags, length=104, data length=100, refs=1:
;  LAYER           STRING    'front_window    '
;  MATERIAL        STRING    'solarblack'
;  MICRONS         DOUBLE           5.0000000
;  ZS              INT       Array[10]
;  GM_PER_CM2      FLOAT     Array[10]
; :Params:
;    component_struct
; :Keywords:
;   csv_filename - defaults to 'stx_components.csv'
;   path - path to be used with loc_file() to find the component csv filename, if not set defaults to curdir()
;     defaults to concat_dir('ssw_stix','idl/processing/drm')
;   fits_filename - if set, write a FITS file binary table using component_struct
;
;
;
; :Author: rschwartz70@gmail.com, 23-oct-2020
;-
pro stx_transmission_layers, component_struct, csv_filename = csv_filename, $
  fits_filename = fits_filename, path = path

  default, csv_filename, 'stx_components.csv'
  if ~file_exist( csv_filename ) then begin
    default, path, concat_dir('SSW_STIX','idl/processing/drm')
    env_name = getenv( path )
    path = keyword_set( env_name ) ? env_name : path
    path = file_dirname(path) ;if we need to strip a filename
    default, file, loc_file( path = path, csv_filename)
  endif else file = csv_filename

  csv = read_csv( file, header=h)
  component_struct = replicate( create_struct( h[*],'','',0.0d0), n_elements(csv.(0)))
  for i=0,2 do component_struct.(i) = csv.(i)
  mtrl = ptrarr(8,/alloc)

  *mtrl[0] = {name: 'AL', z:[13],frc:[1.0],dens:2.7}
  *mtrl[1] = {name: 'BE', z:[4], frc:[1.0], dens:1.85 }
  *mtrl[2] = {name: 'KAPTON', z:[1,6,7,8], frc:[0.026362,  0.691133, 0.07327,  0.209235], dens:1.43}
  *mtrl[3] = {name: 'MYLAR',  z:[1,6,8], frc:[0.041959,  0.625017,  0.333025 ], dens:1.38}
  *mtrl[4] = {name: 'PET', Z:[1,6,8], frc:[0.041959,  0.625017,  0.333025 ], dens:1.37}
  *mtrl[5] = {name: 'SOLARBLACK', Z:[1,8, 20, 25], frc:[0.002,  0.415,  0.396,  0.187], dens:3.2}
  *mtrl[6] = {name: 'SOLARBLACK', Z:[6,20,15], frc:[0.301,  0.503,  0.195], dens:3.2}
  *mtrl[7] = {name: 'TE_O2', Z:[52, 8], FRC: [ 0.7995, 0.2005], dens:5.67}

  for i=0, 7 do az = append_arr( az, (*mtrl[i]).z)

  az = get_uniq( az )
  component_struct = add_tag( component_struct, az,'zs')

  component_struct = add_tag( component_struct, az*0.0,'gm_per_cm2')


  stx_layers = ''
  nc = n_elements( component_struct)
  smtrl = ''
  for i=0, 7 do smtrl = append_arr( smtrl, (*mtrl[i]).name)
  smtrl = smtrl[1:*]
  for i= 0, nc -1 do begin
    component_structi = component_struct[i]
    imt = (where( stregex(/boo,/fold, smtrl, component_structi.material) ))[0]
    mtrli = *mtrl[imt]
    qz = value_locate( az, mtrli.z)
    component_structi.gm_per_cm2[qz] = mtrli.frc * mtrli.dens * component_structi.microns /1e4
    component_struct[i] = component_structi
  endfor
  if keyword_set( fits_filename ) && is_string( fits_filename ) then $
    mwrfits, component_struct, fits_filename, /create
  ;
end