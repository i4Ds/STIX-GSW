;+
; Project     : ssw
;
; Name        : STX_FITS2MAPCUBE
;
; Purpose     : Convert a 4-D fits file to
;               a map or array of maps
;
; Category    :
;
; Syntax      : stx_fits2mapcube, filename, map
;
; Inputs      : filename =  4-D STIX FITS file
;
; Output      : map = array of maps.  If 4-D, order of maps is all times
;               for each energy band, ie e x t
;
; Keywords    : sep - default is set, keep energy and time dimensions separate, i.e. return
;                 array dimensioned [nx,ny,nenergy,ntime] instead of [nx,ny,nenergy*ntime]
;
; History     : 13-sep-2016, ras, adopted from hsi_fits2map
;
; Modifications:

;
; Contact     : 28-sep-2016, rschwartz70@gmail.com, richard.schwartz@nasa.gov
;-

pro stx_fits2mapcube, filename, sep=sep, is_cube = is_cube, $
  map, index = index, header = header, time_axis = times, energy_axis = ebands, error = error
  
  error = 1
  ;Read in all the map structures
  fits2map, filename,map, /silent, /no_angles
  header = headfits( filename )
  index = fitshead2struct( header )
  fits_info, filename, /silent, n_ext = n_ext, extname = extname
  summary = 0
  if n_ext ge 1 then begin
    summary_test = where( stregex( extname, /fold, /boolean, 'SUMMARY INFO'), nsummtest )
    if nsummtest ge 1 then summary = mrdfits( filename, summary_test[0], /silent )
  endif
  if ~keyword_set( is_cube ) &&  ~stregex( get_tag_value( index, /filetype,/quiet ),'CUBE',/fold,/boo) then begin
    print, filename + ' is not an image cube. Returning '
    return
  endif
  ;data = reform( data )
  instrument = index.instrume + ' '


  ; old files have times_arr & ebands_arr, new ones have time_axis & energy_axis
  times = tag_exist(index, 'times_arr') ? index.times_arr : summary.time_axis
  times += anytim( summary.time_axis ) + anytim( index.date_obs )
  ebands = tag_exist(index, 'ebands_arr') ? index.ebands_arr : summary.energy_axis


  n_times  = n_elements( times ) / 2
  n_ebands = n_elements( ebands ) / 2
  map = add_tag( map, fltarr(2), 'eband' )
  map = reform( map, /over, n_ebands, n_times )
  
  for i = 0, n_ebands - 1 do $
    for j = 0, n_times - 1 do begin
    map.time   = anytim( times[ 0, j ], /vms )
    map[i,j].id     = instrument + trim(ebands[0,i],'(f12.1)') + $
      '-' + trim(ebands[1,i], '(f12.1)') + ' keV'
    map[i,j].dur = times[1,j] - times[0,j]
    map[i,j].eband = ebands[*,i]
  endfor

  error = 0 ;success
end
