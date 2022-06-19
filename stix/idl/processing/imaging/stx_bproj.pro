FUNCTION stx_bproj,vis,imsize,pixel,aux_data,silent=silent,uni=uni

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
  
  this_time_range=stx_time2any(vis[0].time_range,/vms)  
  
  ;rotate map to heliocentric view
  b_map=bp_map
  b_map.data=rotate(bp_map.data,1)
  
  stx_pointing = aux_data.stx_pointing
  ; Compute the mapcenter
  this_mapcenter = vis[0].xyoffset + stx_pointing

  b_map.xc = this_mapcenter[0]
  b_map.yc = this_mapcenter[1]
  b_map=rot_map(b_map,-aux_data.ROLL_ANGLE,rcenter=[0.,0.])
  b_map.ROLL_ANGLE = 0.
  add_prop,b_map,rsun = aux_data.RSUN
  add_prop,b_map,B0   = aux_data.B0
  add_prop,b_map,L0   = aux_data.L0
  
  return,b_map

END
