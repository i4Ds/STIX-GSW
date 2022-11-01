;+
;
; NAME:
;   stx_vis_fwdfit_pso
;
; PURPOSE:
;   Wrapper around vis_fwdfit_pso
;
; INPUTS:
;   configuration: array containing parametric shapes chosen for the forward fitting method (one for each source component)
;                    - 'circle' : Gaussian circular source
;                    - 'ellipse': Gaussian elliptical source
;                    - 'loop'   : single curved elliptical gaussian
;
;   vis         : struct containing  the observed visibility values
;     vis.obsvis: array containing the values of the observed visibilities
;     vis.sigamp: array containing the values of the errors on the observed visibility amplitudes
;     vis.u     : u coordinates of the sampling frequencies
;     vis.v     : v coordinates of the sampling frequencies
;     
;  aux_data: structure containing the average values of SAS solution, apparent radius of the Sun, roll angle, pitch, yaw, L0 and B0
;             computed over a considered time range
;
; KEYWORDS:
;   SRCIN       : struct containing for each source the parameters to optimize and those fixed, upper and lower bound of the variables.
;                 to create the structure srcin:
;                     srcin = VIS_FWDFIT_PSO_MULTIPLE_SRC_CREATE(vis, configuration) 
;                                  
;                 If not entered, default values are used (see:
;                                                             - vis_fwdfit_pso_circle_struct_define for the circle                                                         
;                                                             - vis_fwdfit_pso_ellipse_struct_define for the ellipse
;                                                             - vis_fwdfit_pso_loop_struct_define for the loop)
;                                                             
;   N_BIRDS     : number of particles used in PSO 
;                 (default is 100)
;   TOLERANCE   : tolerance for the stopping criterion 
;                 (default is 1e-6)
;   MAXITER     : maximum number of iterations of PSO
;                 (default is the product between of the numbers of parameters and the number of particles)
;   UNCERTAINTY : set to 1 for the computation of the parameters uncertainty (confidence strip approach)
;                 (default is 0) 
;   IMSIZE      : array containing the size (number of pixels) of the image to reconstruct
;                 (default is [128., 128.])
;   PIXEL       : array containing the pixel size (in arcsec) of the image to reconstruct
;                 (default is [1., 1.])
;   SILENT      : set to 1 for avoiding the print of the retrieved parameters
;
; OUTPUTS:
;   fit parameters and uncertaintly  (srcin and fitsigams)
;   reduced chi^2 (redchisq)
;   image map (output map structure has north up)


function stx_vis_fwdfit_pso, configuration, vis, aux_data, $
                              srcin = srcin, $
                              n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, $
                              uncertainty = uncertainty, $
                              imsize=imsize, pixel=pixel, $
                              silent = silent, $
                              srcstr = srcstr,fitsigmas =fitsigmas, redchisq = redchisq, $
                              seedstart = seedstart


  default, imsize, [128,128]
  default, pixel, [1.,1.]
  default, n_birds, 100

  ; stix view
  this_vis = vis
  
  roll_angle = aux_data.ROLL_ANGLE * !dtor

  phi= max(abs(vis.obsvis)) ;estimate_flux

  loc_circle  = where(configuration eq 'circle', n_circle)>0
  loc_ellipse = where(configuration eq 'ellipse', n_ellipse)>0
  loc_loop    = where(configuration eq 'loop', n_loop)>0

  n_sources = n_elements(configuration)

  if keyword_set(SRCIN) then begin

    if n_circle gt 0 then begin

      for j=0, n_circle-1 do begin

        flag1=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_c:
          flag1=0
          this_x_c = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_c
        ; Cause type conversion error.
        if flag1 then this_x_c = double(srcin.circle[j].param_opt.param_x)
        
        flag2=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_c:
          flag2=0
          this_y_c = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_c
        ; Cause type conversion error.
        if flag2 then this_y_c = double(srcin.circle[j].param_opt.param_y)
       

        if (((flag1 eq 0) and (flag2 eq 1)) or ((flag1 eq 1 ) and (flag2 eq 0))) then begin
          Catch, /Cancel
          message, "Fix both x and y positions or none of them."
        endif
        if ((flag1 eq 1) and (flag2 eq 1)) then begin

          this_xy_c = stx_hpc2stx_coord([double(srcin.circle[j].param_opt.param_x),double(srcin.circle[j].param_opt.param_y)], aux_data)
          
          srcin.circle[j].param_opt.param_x = string(this_xy_c[0])
          srcin.circle[j].param_opt.param_y = string(this_xy_c[1])
          
        endif

        
      endfor
    endif

    if n_ellipse gt 0 then begin
      for j=0, n_ellipse-1 do begin

        flag3=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_e:
          flag3=0
          this_x_e = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_e
        ; Cause type conversion error.
        if flag3 then this_x_e = double(srcin.ellipse[j].param_opt.param_x)
        
        flag4=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_e:
          flag4=0
          this_y_e = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_e
        ; Cause type conversion error.
        if flag4 then this_y_e = double(srcin.ellipse[j].param_opt.param_y)
        
        if (((flag3 eq 0) and (flag4 eq 1)) or ((flag3 eq 1 ) and (flag4 eq 0))) then begin
          Catch, /Cancel
          message, "Fix both x and y positions or none of them."
        endif
        if ((flag3 eq 1) and (flag4 eq 1)) then begin
        
          this_xy_e = stx_hpc2stx_coord([double(srcin.ellipse[j].param_opt.param_x),double(srcin.ellipse[j].param_opt.param_y)], aux_data)

          srcin.ellipse[j].param_opt.param_x = string(this_xy_e[0])
          srcin.ellipse[j].param_opt.param_y = string(this_xy_e[1])
        
        endif

        
        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          alpha_stix_e:
          flag=0
          srcin.ellipse[j].param_opt.param_alpha = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, alpha_stix_e
        ; Cause type conversion error.
        if flag then srcin.ellipse[j].param_opt.param_alpha = string(double(srcin.ellipse[j].param_opt.param_alpha) - 90.0 - aux_data.roll_angle)
                
      endfor
    endif

    if n_loop gt 0 then begin
      for j=0, n_loop-1 do begin

        flag5=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_l:
          flag5=0
          this_x_l = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_l
        ; Cause type conversion error.
        if flag5 then this_x_l =  double(srcin.loop[j].param_opt.param_x)
        
        flag6=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_l:
          flag6=0
          this_y_l = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_l
        ; Cause type conversion error.
        if flag6 then this_y_l = double(srcin.loop[j].param_opt.param_y)
        
        if (((flag5 eq 0) and (flag6 eq 1)) or ((flag5 eq 1 ) and (flag6 eq 0))) then begin
          Catch, /Cancel
          message, "Fix both x and y positions or none of them."
        endif
        if ((flag5 eq 1) and (flag6 eq 1)) then begin
          
          this_xy_l = stx_hpc2stx_coord([double(srcin.loop[j].param_opt.param_x),double(srcin.loop[j].param_opt.param_y)], aux_data)

          srcin.loop[j].param_opt.param_x = string(this_xy_l[0])
          srcin.loop[j].param_opt.param_y = string(this_xy_l[1])
          
        endif
        
        
        
        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          alpha_stix_l:
          flag=0
          srcin.loop[j].param_opt.param_alpha = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, alpha_stix_l
        ; Cause type conversion error.
        if flag then srcin.loop[j].param_opt.param_alpha = string(double(srcin.loop[j].param_opt.param_alpha) - 90. - aux_data.roll_angle)

      endfor
    endif

  endif else begin

    srcin = vis_fwdfit_pso_multiple_src_create(vis, configuration)

  endelse


  param_out = vis_fwdfit_pso(configuration, this_vis, srcin, $
                              n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, $
                              uncertainty = uncertainty, $
                              imsize=imsize, pixel=pixel, $
                              silent = silent, $
                              seedstart = seedstart)

  srcstr = param_out.srcstr
  fitsigmas = param_out.fitsigmas
  redchisq = param_out.redchisq
  
  fwdfit_pso_map = stx_make_map(param_out.data, aux_data, pixel, "FWDFIT_PSO", vis)

  if ~keyword_set(silent) then begin

    PRINT
    PRINT, 'COMPONENT    TYPE          FLUX       FWHM MAX    FWHM MIN      Angle     X loc      Y loc      Loop FWHM'
    PRINT, '                     cts/s/keV/cm^2    arcsec      arcsec        deg      arcsec     arcsec        deg   '
    PRINT

  endif

  nsrc = N_ELEMENTS(srcstr)
  FOR n = 0, nsrc-1 DO BEGIN
      
      xy_hpc = stx_hpc2stx_coord([srcstr[n].srcx,srcstr[n].srcy], aux_data, /inverse)
      
      srcstr[n].srcx = xy_hpc[0]
      srcstr[n].srcy = xy_hpc[1]
      
      if ~(srcstr[n].srctype eq 'circle') then begin
          srcstr[n].SRCPA = atan(sin((srcstr[n].SRCPA+90.)*!dtor+roll_angle), cos((srcstr[n].SRCPA+90.)*!dtor+roll_angle))*180/!pi
          if srcstr[n].SRCPA lt 0. then begin
            srcstr[n].srcpa += 180.
            if srcstr[n].srctype eq 'loop' then srcstr[n].loop_angle = -srcstr[n].loop_angle
          endif
      endif

    if ~keyword_set(silent) then begin

      temp        = [ srcstr[n].srcflux,srcstr[n].srcfwhm_max,  srcstr[n].srcfwhm_min, $
        srcstr[n].srcpa, $
        srcstr[n].srcx, srcstr[n].srcy, srcstr[n].loop_angle]
      PRINT, n+1, srcstr[n].srctype, temp, FORMAT="(I5, A13, F13.2, 1F13.1, F12.1, 2F11.1, F11.1, 2F12.1)"

      temp        = [ fitsigmas[n].srcflux,fitsigmas[n].srcfwhm_max, fitsigmas[n].srcfwhm_min, $
        fitsigmas[n].srcpa, fitsigmas[n].srcy, fitsigmas[n].srcx, fitsigmas[n].loop_angle]
      PRINT, ' ', '(std)', temp, FORMAT="(A7, A11, F13.2, 1F13.1, F12.1, 2F11.1, F11.1, 2F12.1)"
      PRINT, ' '

    endif

  endfor

  undefine, srcin

  return, fwdfit_pso_map

end