FUNCTION bproj_stix_sep2021,vis,imsize,pixel,silent=silent,uni=uni

  ; wrapper around backprojection
  ; output map structure has north up
  ; 
  ; 10-Sep-2021: Sam: first version

  ;natural weighting is default
  vis_bpmap, vis,  MAP = map, BP_FOV = imsize[0]*pixel[0], PIXEL = pixel[0],uni=uni
  ;make map
  bp_map = make_map(map)
  this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
  bp_map.ID = 'STIX BPROJ '+this_estring+': '
  bp_map.dx = pixel[0]
  bp_map.dy = pixel[1]
  bp_map.xc = vis[0].xyoffset[0]
  bp_map.yc = vis[0].xyoffset[1]
  this_time_range=stx_time2any(vis[0].time_range,/vms)
  bp_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
  bp_map.DUR = anytim(this_time_range[1])-anytim(this_time_range[0])

  ;eventually fill in radial distance etc
  add_prop,bp_map,rsun=0.
  add_prop,bp_map,B0=0.
  add_prop,bp_map,L0=0.
  
  
  ;rotate map to heliocentric view
  b_map=bp_map
  b_map.data=rotate(bp_map.data,1)
  
  return,b_map

END
