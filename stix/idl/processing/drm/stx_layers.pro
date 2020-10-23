;+
; :Description:
;    Reformats the material and component list from Shane M into a
;    structure that can be easily used in computations
;
; :Params:
;    component_struct
; :Keywords:
;   csv_filename - defaults to 'stx_components.csv'
;   path - path to be used with loc_file() to find the component csv filename, if not set defaults to curdir()
;   fits_filename - if set, write a FITS file binary table using component_struct
;
;
;
; :Author: rschwartz70@gmail.com
;-
pro stx_layers, component_struct, csv_filename = csv_filename, $
  filename = filename, path = path

  default, csv_filename, 'stx_components.csv'
  if ~file_exist( csv_filename ) then begin
    default, path, ''
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