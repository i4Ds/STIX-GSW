function vis_fwdfit_pso_circle_struct_define, vis, $
                    param_opt_circle=param_opt_circle, lower_bound_circle=lower_bound_circle, upper_bound_circle=upper_bound_circle
   
  ;Internal routine used by vis_fwdfit_pso that returns a structure that defines one component of a Gaussian circular source.
  
  ;vis: struct containing the observed visibility values.
                                
  phi= max(abs(vis.obsvis)) ;estimate_flux

  default, param_opt_circle, {param_flux: 'fit', param_x: 'fit', param_y:'fit', param_fwhm: 'fit'}
  default, lower_bound_circle, {l_b_flux: 0.1*phi, l_b_x: -100., l_b_y: -100., l_b_fwhm: 1.}
  default, upper_bound_circle, {u_b_flux: 1.5*phi, u_b_x: 100., u_b_y: 100., u_b_fwhm: 100.}

  circle_struct = {    type: 'circle', $
                       param_opt: param_opt_circle, $
                       lower_bound: lower_bound_circle, $
                       upper_bound: upper_bound_circle}
                       
  RETURN, circle_struct
END