FUNCTION stx_mem_ge,vis,imsize,pixel,aux_data,silent=silent, total_flux=total_flux, percent_lambda=percent_lambda

  ; wrapper around MEM_GE
  ; output map structure has north up
  ;
  ; 10-Sep-2021: Paolo Massa: first version
  
  default, percent_lambda, stx_mem_ge_percent_lambda(stx_vis_get_snr(vis))
  default, silent, 0

  if ~keyword_set(total_flux) then total_flux=vis_estimate_flux(vis, imsize[0]*pixel[0], silent=silent) ;estimate of the total flux of the image
  mem_ge_im = mem_ge(vis, total_flux, percent_lambda=percent_lambda, imsize=imsize, pixel=pixel, silent=silent, makemap=0)
  mem_ge_map = make_map(mem_ge_im)
  this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
  mem_ge_map.ID = 'STIX MEM_GE '+this_estring+': '
  mem_ge_map.dx = pixel[0]
  mem_ge_map.dy = pixel[1]
  
  this_time_range=stx_time2any(vis[0].time_range,/vms)
     
  mem_ge_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
  mem_ge_map.DUR = anytim(this_time_range[1])-anytim(this_time_range[0])
  
  ;rotate map to heliocentric view
  mem__ge_map=mem_ge_map
  mem__ge_map.data=rotate(mem_ge_map.data,1)
  
  ; Correct mapcenter:
  ; - if 'aux_data' contains the SAS solution, then we read it and we correct tha map center accordingly
  ; - if 'aux_data' does not contain the SAS solution, then we apply an average shift value to the map center
  mapcenter_corr_factors = read_csv(loc_file( 'Mapcenter_correction_factors.csv', path = getenv('STX_VIS_DEMO') ), $
    header=header, table_header=tableheader, n_table_header=1 )
  if ~aux_data.Z_SRF.isnan() and ~aux_data.Y_SRF.isnan() then begin
    ; coor_mapcenter = SAS solution + discrepancy factor
    coor_mapcenter = [aux_data.Y_SRF, -aux_data.Z_SRF] + [mapcenter_corr_factors.FIELD3, mapcenter_corr_factors.FIELD4]
  endif else begin
    coor_mapcenter = [mapcenter_corr_factors.FIELD1,mapcenter_corr_factors.FIELD2] + [aux_data.YAW, aux_data.PITCH]
  endelse
  mem__ge_map.xc = vis[0].xyoffset[0] + coor_mapcenter[0]
  mem__ge_map.yc = vis[0].xyoffset[1] + coor_mapcenter[1]

  mem__ge_map.roll_angle    = aux_data.ROLL_ANGLE
  add_prop,mem__ge_map,rsun = aux_data.RSUN
  add_prop,mem__ge_map,B0   = aux_data.B0
  add_prop,mem__ge_map,L0   = aux_data.L0
  
  return,mem__ge_map

END