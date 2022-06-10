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
;   SEEDSTART   : costant used to initialize the random perturbation of visibilities when uncertainty is computed
;                 (default is fix(randomu(seed) * 100))
;
;
; OUTPUTS:
;   fit parameters and uncertaintly  (srcstr and fitsigams)
;   reduced chi^2 (redchisq)
;   image map (output map structure has north up)


function stx_vis_fwdfit_pso, configuration, vis, $
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
  this_vis.xyoffset[0] = vis.xyoffset[1]
  this_vis.xyoffset[1] = - vis.xyoffset[0]

  phi= max(abs(vis.obsvis)) ;estimate_flux

  loc_circle  = where(configuration eq 'circle', n_circle)>0
  loc_ellipse = where(configuration eq 'ellipse', n_ellipse)>0
  loc_loop    = where(configuration eq 'loop', n_loop)>0

  n_sources = n_elements(configuration)

  if keyword_set(SRCIN) then begin
    
    if n_circle gt 0 then begin

      for j=0, n_circle-1 do begin

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_c:
          flag=0
          this_x_c = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_c
        ; Cause type conversion error.
        if flag then this_x_c = string(double(srcin.circle[j].param_opt.param_y) - 58.2)

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_c:
          flag=0
          this_y_c = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_c
        ; Cause type conversion error.
        if flag then this_y_c = string( - double(srcin.circle[j].param_opt.param_x) + 26.1)

        srcin.circle[j].param_opt.param_x = this_x_c
        srcin.circle[j].param_opt.param_y = this_y_c

      endfor
    endif

    if n_ellipse gt 0 then begin
      for j=0, n_ellipse-1 do begin

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_e:
          flag=0
          this_x_e = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_e
        ; Cause type conversion error.
        if flag then this_x_e = string(double(srcin.ellipse[j].param_opt.param_y) - 58.2)

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_e:
          flag=0
          this_y_e = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_e
        ; Cause type conversion error.
        if flag then this_y_e = string( - double(srcin.ellipse[j].param_opt.param_x) + 26.1)
        
        srcin.ellipse[j].param_opt.param_x = this_x_e
        srcin.ellipse[j].param_opt.param_y = this_y_e

      endfor
    endif

    if n_loop gt 0 then begin
      for j=0, n_loop-1 do begin

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          x_stix_l:
          flag=0
          this_x_l = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, x_stix_l
        ; Cause type conversion error.
        if flag then this_x_l = string(double(srcin.loop[j].param_opt.param_y) - 58.2)

        flag=1
        Catch, theError
        IF theError NE 0 THEN BEGIN
          Catch, /Cancel
          y_stix_l:
          flag=0
          this_y_l = 'fit'
        ENDIF
        ; Set up file I/O error handling.
        ON_IOError, y_stix_l
        ; Cause type conversion error.
        if flag then this_y_l = string( - double(srcin.loop[j].param_opt.param_x) + 26.1)
        
        srcin.loop[j].param_opt.param_x = this_x_l
        srcin.loop[j].param_opt.param_y = this_y_l

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
                                seedstart = seedstart, warning_conf=warning_conf)

  srcstr = param_out.srcstr
  fitsigmas = param_out.fitsigmas
  redchisq = param_out.redchisq
  fwdfit_pso_map = make_map(param_out.data)
  this_estring=strtrim(fix(vis[0].energy_range[0]),2)+'-'+strtrim(fix(vis[0].energy_range[1]),2)+' keV'
  fwdfit_pso_map.ID = 'STIX VIS_PSO '+this_estring+': '
  fwdfit_pso_map.dx = pixel[0]
  fwdfit_pso_map.dy = pixel[1]

  this_time_range = stx_time2any(vis[0].time_range,/vms)

  fwdfit_pso_map.time = anytim((anytim(this_time_range[1])+anytim(this_time_range[0]))/2.,/vms)
  fwdfit_pso_map.DUR  = anytim(this_time_range[1])-anytim(this_time_range[0])
  
  ;rotate map to heliocentric view
  fwdfit_pso__map = fwdfit_pso_map
  fwdfit_pso__map.data = rotate(fwdfit_pso_map.data,1)

;  fwdfit_pso__map.xc = vis[0].xyoffset[0] + stx_pointing[0]
;  fwdfit_pso__map.yc = vis[0].xyoffset[1] + stx_pointing[1]
;
;  fwdfit_pso__map=rot_map(fwdfit_pso__map,-aux_data.ROLL_ANGLE,rcenter=[0.,0.])
;  fwdfit_pso__map.ROLL_ANGLE = 0.
;  add_prop,fwdfit_pso__map,rsun = aux_data.RSUN
;  add_prop,fwdfit_pso__map,B0   = aux_data.B0
;  add_prop,fwdfit_pso__map,L0   = aux_data.L0


  fwdfit_pso_map.xc = vis[0].xyoffset[0]
  fwdfit_pso_map.yc = vis[0].xyoffset[1]

  ;rotate map to heliocentric view
  fwdfit_pso__map = fwdfit_pso_map
  fwdfit_pso__map.data = rotate(fwdfit_pso_map.data,1)

  ;; Mapcenter corrected for Frederic's mean shift values
  fwdfit_pso__map.xc = vis[0].xyoffset[0] + 26.1
  fwdfit_pso__map.yc = vis[0].xyoffset[1] + 58.2

  data = stx_get_l0_b0_rsun_roll_temp(this_time_range[0])

  fwdfit_pso__map.roll_angle    = data.ROLL_ANGLE
  add_prop,fwdfit_pso__map,rsun = data.RSUN
  add_prop,fwdfit_pso__map,B0   = data.B0
  add_prop,fwdfit_pso__map,L0   = data.L0

  if ~keyword_set(silent) then begin

    PRINT
    PRINT, 'COMPONENT    TYPE          FLUX       FWHM MAX    FWHM MIN      Angle     X loc      Y loc      Loop FWHM'
    PRINT, '                     cts/s/keV/cm^2    arcsec      arcsec        deg      arcsec     arcsec        deg   '
    PRINT

  endif

  nsrc = N_ELEMENTS(srcstr)
  FOR n = 0, nsrc-1 DO BEGIN
    
    ; heliocentric view
    x_new = srcstr[n].srcy - this_vis[0].xyoffset[1]
    y_new = srcstr[n].srcx - this_vis[0].xyoffset[0]

    ;; Center of the sources corrected for Frederic's mean shift values
    srcstr[n].srcx        = - x_new + vis[0].xyoffset[0] + 26.1
    srcstr[n].srcy        = y_new + vis[0].xyoffset[1]  + 58.2
  
    srcstr[n].SRCPA += 90.

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
  
  if warning_conf then begin
    
    print, ' '
    print, ' '
    print, 'Warning: for this configuration it is not possible to compute the uncertainty on the parameters. '
    print, 'Try using a simpler configuration. '
    print, ' '
    print, ' '
    
  endif

  undefine, srcin

  return, fwdfit_pso__map

end