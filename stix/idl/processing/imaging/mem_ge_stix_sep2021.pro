FUNCTION mem_ge_stix_sep2021,vis,imsize,pixel,silent=silent, total_flux=total_flux, percent_lambda=percent_lambda

  ; wrapper around MEM_GE
  ; output map structure has north up
  ;
  ; 10-Sep-2021: Paolo Massa: first version
  
  default, percent_lambda, 0.02
  default, silent, 0

  if ~keyword_set(total_flux) then total_flux=vis_estimate_flux(vis, imsize[0]*pixel[0], silent=silent) ;estimate of the total flux of the image
  mem_ge_im = mem_ge(vis, total_flux, percent_lambda=percent_lambda, imsize=imsize, pixel=pixel, silent=silent, makemap=0)
  mem_ge_map = make_map(mem_ge_im)
  this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
  mem_ge_map.ID = 'STIX MEM_GE '+this_estring+': '
  mem_ge_map.dx = pixel[0]
  mem_ge_map.dy = pixel[1]
  mem_ge_map.xc = vis[0].xyoffset[0]
  mem_ge_map.yc = vis[0].xyoffset[1]
  this_time_range=stx_time2any(vis[0].time_range,/vms)
  mem_ge_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
  mem_ge_map.DUR = anytim(this_time_range[1])-anytim(this_time_range[0])
  ;eventually fill in radial distance etc
  add_prop,mem_ge_map,rsun=0.
  add_prop,mem_ge_map,B0=0.
  add_prop,mem_ge_map,L0=0.
  
  ;rotate map to heliocentric view
  mem__ge_map=mem_ge_map
  mem__ge_map.data=rotate(mem_ge_map.data,1)

  return,mem__ge_map

END