function vis_fwdfit_pso_loop_struct_define, vis, $
                    param_opt_loop=param_opt_loop, lower_bound_loop=lower_bound_loop, upper_bound_loop=upper_bound_loop
  
  ;Internal routine used by vis_fwdfit_pso that returns a structure that defines one component of a single curved elliptical gaussian.
  
  ;vis: struct containing the observed visibility values.
  
  phi= max(abs(vis.obsvis)) ;estimate_flux
  
  default, param_opt_loop, {param_flux: 'fit', param_x: 'fit', param_y:'fit', param_fwhm_max: 'fit', param_fwhm_min: 'fit', param_alpha: 'fit', param_loopangle:'fit'}
  default, lower_bound_loop, {l_b_flux: 0.1*phi, l_b_x: -100., l_b_y: -100., l_b_fwhm: 1., l_b_eccos: -5., l_b_ecsin: 0., l_b_loopangle: -180.}
  default, upper_bound_loop, {u_b_flux: 1.5*phi, u_b_x: 100., u_b_y: 100., u_b_fwhm: 100., u_b_eccos: 5., u_b_ecsin: 1., u_b_loopangle: 180.}
  
  loop_struct = {  type:'loop', $
                   param_opt: param_opt_loop, $
                   lower_bound: lower_bound_loop, $
                   upper_bound: upper_bound_loop }
                   
  RETURN,loop_struct
END