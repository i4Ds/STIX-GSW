; NAME:
;   vis_fwdfit_pso_multiple_src_create
;
; PURPOSE:
;   create the input structure for stx_vis_fwdfit_pso.
;   it returns a structure whose main fields are 'circle', 'ellipse', 'loop', replicated according to the number of times they are
;   repeated in the configuration. 
;   Each shape contains 3 fields: parameters to be optimised, characteristic for each shape (param_opt), lower and upper bound 
;   for each variable.
;   
; INPUT:
;   vis :struct containing  the observed visibility values
;   
;   configuration: array containing parametric shapes chosen for the forward fitting method (one for each source component)
;                    - 'circle' : Gaussian circular source
;                    - 'ellipse': Gaussian elliptical source
;                    - 'loop'   : single curved elliptical gaussian
;
; Example: if configuration=['circle', 'ellipse', 'circle'], srcin has two main fields: srcin.circle and srcin.ellipse
;                                                                srcin.circle has two main fields srcin.circle[0] and srcin.circle[1]
;                                                                both srcin.circle[0], srcin.circle[1] and srcin.ellipse have 3 fields:
;                                                                param_opt, lower_bound and upper_bound


FUNCTION VIS_FWDFIT_PSO_MULTIPLE_SRC_CREATE, vis, configuration

  loc_circle  = where(configuration eq 'circle', n_circle)>0 
  loc_ellipse = where(configuration eq 'ellipse', n_ellipse)>0
  loc_loop    = where(configuration eq 'loop', n_loop)>0
  
  if n_circle gt 0 then begin
    src_circle = vis_fwdfit_pso_circle_struct_define(vis)
    src_circle = cmreplicate(src_circle, n_circle)
  endif
  
  if n_ellipse gt 0 then begin
    src_ellipse = vis_fwdfit_pso_ellipse_struct_define(vis)
    src_ellipse = cmreplicate(src_ellipse, n_ellipse)
  endif
  
  if n_loop gt 0 then begin
    src_loop = vis_fwdfit_pso_loop_struct_define(vis)
    src_loop = cmreplicate(src_loop, n_loop)
  endif
  
  case 1 of 
    ((n_circle gt 0) and (n_ellipse gt 0) and (n_loop gt 0)): begin
                      srcin={circle: src_circle, ellipse: src_ellipse, loop: src_loop}
    end
    
    ((n_circle eq 0) and (n_ellipse gt 0) and (n_loop gt 0)): begin
                      srcin={ellipse: src_ellipse, loop: src_loop}
    end
    
    ((n_circle eq 0) and (n_ellipse eq 0) and (n_loop gt 0)): begin
                      srcin={loop: src_loop}
    end
    
    ((n_circle eq 0) and (n_ellipse gt 0) and (n_loop eq 0)): begin
                      srcin={ellipse: src_ellipse}
    end
    
    ((n_circle gt 0) and (n_ellipse eq 0) and (n_loop eq 0)): begin
                      srcin={circle: src_circle}
    end

    ((n_circle gt 0) and (n_ellipse gt 0) and (n_loop eq 0)): begin
                      srcin={circle: src_circle, ellipse: src_ellipse}
    end

    ((n_circle gt 0) and (n_ellipse eq 0) and (n_loop gt 0)): begin
                      srcin={circle: src_circle, loop: src_loop}
    end
    
    
  endcase
  
return, srcin
end