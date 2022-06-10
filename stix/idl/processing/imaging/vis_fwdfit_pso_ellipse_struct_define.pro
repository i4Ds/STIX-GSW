function vis_fwdfit_pso_ellipse_struct_define, vis, $
                    param_opt_ellipse=param_opt_ellipse, lower_bound_ellipse=lower_bound_ellipse, upper_bound_ellipse=upper_bound_ellipse
  
  ;Internal routine used by vis_fwdfit_pso that returns a structure that defines one component of a Gaussian elliptical source.
  
  ;vis: struct containing the observed visibility values.
    
  phi= max(abs(vis.obsvis)) ;estimate_flux
    
  default, param_opt_ellipse, {param_flux: 'fit', param_x: 'fit', param_y:'fit', param_fwhm_max: 'fit', param_fwhm_min: 'fit', param_alpha: 'fit'}
  default, lower_bound_ellipse, {l_b_flux: 0.1*phi, l_b_x: -100., l_b_y: -100., l_b_fwhm: 1., l_b_eccos: -5., l_b_ecsin: 0.}
  default, upper_bound_ellipse,  {u_b_flux: 1.5*phi, u_b_x: 100., u_b_y: 100., u_b_fwhm: 100., u_b_eccos: 5., u_b_ecsin: 1.}
  
  
  ellipse_struct = {  type:'ellipse', $
                      param_opt: param_opt_ellipse, $
                      lower_bound: lower_bound_ellipse, $
                      upper_bound: upper_bound_ellipse }
  
  RETURN, ellipse_struct
END