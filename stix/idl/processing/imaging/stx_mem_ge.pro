FUNCTION stx_mem_ge,vis,imsize,pixel,aux_data,silent=silent, total_flux=total_flux, percent_lambda=percent_lambda

  ; wrapper around MEM_GE
  ; output map structure has north up
  ;
  ; 10-Sep-2021: Paolo Massa, first version
  ; 22-Aug-2022: Paolo Massa, map created with stx_make_map
  
  default, percent_lambda, stx_mem_ge_percent_lambda(stx_vis_get_snr(vis))
  default, silent, 0

  if ~keyword_set(total_flux) then total_flux=vis_estimate_flux(vis, imsize[0]*pixel[0], silent=silent) ;estimate of the total flux of the image
  this_vis = vis
  mem_ge_im = mem_ge(this_vis, total_flux, percent_lambda=percent_lambda, imsize=imsize, pixel=pixel, silent=silent, makemap=0)
  
  method     = 'MEM_GE'
  mem_ge_map = stx_make_map(mem_ge_im, aux_data, pixel, method, vis)
  
  return, mem_ge_map

END