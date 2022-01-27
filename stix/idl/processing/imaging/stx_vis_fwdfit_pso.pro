;+
;
; NAME:
;   stx_vis_fwdfit_pso
;
; PURPOSE:
;   Wrapper around vis_fwdfit_pso
;
;-
;
function stx_vis_fwdfit_pso, type, vis, $
  lb = lb, ub = ub, $
  param_opt = param_opt, $
  SwarmSize = SwarmSize, TolFun = TolFun, maxiter = maxiter, $
  uncertainty = uncertainty, $
  imsize=imsize, pixel=pixel, $
  silent = silent, $
  srcstr = srcstr, $
  fitsigmas =fitsigmas, $
  seedstart = seedstart
  
  
  param_out = vis_fwdfit_pso(type, vis, $
    lb = lb, ub = ub, $
    param_opt = param_opt, $
    SwarmSize = SwarmSize, TolFun = TolFun, maxiter = maxiter, $
    uncertainty = uncertainty, $
    imsize=imsize, pixel=pixel, $
    silent = silent, $
    seedstart = seedstart)
  
  srcstr = param_out.srcstr
  fitsigmas = param_out.fitsigmas
  fwdfit_pso_map = vis_FWDFIT_PSO_SOURCE2MAP(srcstr, type=type, pixel=pixel, imsize=imsize, xyoffset=vis[0].xyoffset)

  this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
  fwdfit_pso_map.ID = 'STIX VIS_PSO '+this_estring+': '
  fwdfit_pso_map.dx = pixel[0]
  fwdfit_pso_map.dy = pixel[1]
  fwdfit_pso_map.xc = vis[0].xyoffset[0]
  fwdfit_pso_map.yc = vis[0].xyoffset[1]
  this_time_range   = stx_time2any(vis[0].time_range,/vms)
  fwdfit_pso_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
  fwdfit_pso_map.DUR  = anytim(this_time_range[1])-anytim(this_time_range[0])
  ;eventually fill in radial distance etc
  add_prop,fwdfit_pso_map,rsun=0.
  add_prop,fwdfit_pso_map,B0=0.
  add_prop,fwdfit_pso_map,L0=0.
  
return, fwdfit_pso_map
end
  