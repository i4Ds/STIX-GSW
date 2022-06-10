
; NAME:
;   vis_fwdfit_func_pso
;
; PURPOSE:
;   Internal routine used by vis_fwdfit_pso that calculates expected visibilities at specified u,v points 
;   for a given set of source parameters.
;   
; OUTPUT: 
;   It returns the reduced chi-squared: chi is the square sum of the error estimates, they are obtained by difference 
;                                       between the fitted and measured values, divided by the error (sigamp).


function vis_fwdfit_func_pso, xx, extra = extra

  
  visobs = extra.visobs
  sigamp = extra.sigamp
  u = extra.u
  v = extra.v
  n_free = extra.n_free
  configuration = extra.configuration
  param_opt = extra.param_opt
  mapcenter = extra.mapcenter
  
  loc_circle  = where(configuration eq 'circle', n_circle)>0
  loc_ellipse = where(configuration eq 'ellipse', n_ellipse)>0
  loc_loop    = where(configuration eq 'loop', n_loop)>0

  n_particles = (size(xx,/dimension))[0]
  n_sources   = n_elements(configuration)
  n_vis       = n_elements(u)
  u           = reform(u, [1, n_vis])
  v           = reform(v, [1, n_vis])

  ones = fltarr(1, n_vis) + 1.

  vispred_re = fltarr(n_particles, n_vis)
  vispred_im = fltarr(n_particles, n_vis)
  

  if n_circle gt 0 then begin
    
    for i=0, n_circle-1 do begin
      
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_flux_circle:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_flux_circle
      ; Cause type conversion error.
      if flag then xx[*, 4*i] = xx[*, 4*i] * 0. + double(param_opt[4*i])
      flux = xx[*, 4*i]
      flux = reform(flux, [n_particles,1])
      flux = flux # ones

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_x_circle:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_x_circle
      ; Cause type conversion error.
      if flag then xx[*, 4*i+1] = xx[*, 4*i+1] * 0. + double(param_opt[4*i+1]) - mapcenter[0]
      x_loc = reform(xx[*, 4*i+1], [n_particles,1])

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_y_circle:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_y_circle
      ; Cause type conversion error.
      if flag then xx[*, 4*i+2] = xx[*, 4*i+2] * 0. + double(param_opt[4*i+2]) - mapcenter[1]
      y_loc = reform(xx[*,4*i+2], [n_particles,1])

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_f_circle:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_f_circle
      ; Cause type conversion error.
      if flag then xx[*, 4*i+3] = xx[*, 4*i+3] * 0. + double(param_opt[4*i+3])
      fwhm = reform(xx[*,4*i+3], [n_particles,1])
      
      vispred_re += flux * exp(-(!pi^2. * fwhm^2. / (4.*alog(2.)))#(u^2. + v^2.))*cos(2*!pi*((x_loc#u)+(y_loc#v)))
      vispred_im += flux * exp(-(!pi^2. * fwhm^2. / (4.*alog(2.)))#(u^2. + v^2.))*sin(2*!pi*((x_loc#u)+(y_loc#v)))
      
    endfor
    
  endif   
  
  
  if n_ellipse gt 0 then begin

    for i=0, n_ellipse-1 do begin 
      
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_flux_ellipse:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_flux_ellipse
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+6*i] = xx[*, n_circle*4+6*i] * 0. + double(param_opt[n_circle*4+6*i])
      flux = xx[*, n_circle*4+6*i]
      flux = reform(flux, [n_particles,1])
      flux = flux # ones

      eccos = reform(xx[*,n_circle*4+6*i+4], [n_particles,1])
      ecsin = reform(xx[*,n_circle*4+6*i+5], [n_particles,1])

      ecmsr = sqrt( eccos^2. + ecsin^2. )
      eccen = sqrt(1. - exp(-2. * ecmsr))

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhmmax_ellipse:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhmmax_ellipse
      if flag then fwhmmajor = eccen * 0. + double(param_opt[n_circle*4+6*i+3])

      flag1=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhmmin_ellipse:
        flag1=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhmmin_ellipse
      if flag1 then fwhmminor = eccen * 0. + double(param_opt[n_circle*4+6*i+4])

      if flag and ~flag1 then fwhmminor = fwhmmajor * ((1 - eccen^2.)^0.25)^2.
      if ~flag and flag1 then  fwhmmajor = fwhmminor / ((1 - eccen^2.)^0.25)^2.
      if ~flag and ~flag1 then begin

        fwhm = xx[*,n_circle*4+6*i+3]
        fwhm = reform(fwhm, [n_particles,1])
        fwhmminor = fwhm * (1 - eccen^2.)^0.25
        fwhmmajor = fwhm / (1 - eccen^2.)^0.25

      endif

      fwhmminor = fwhmminor # ones
      fwhmmajor = fwhmmajor # ones

      pa = fltarr(size(eccen, /dim))

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_alpha_ellipse:
        pa = atan(ecsin, eccos) * !radeg
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_alpha_ellipse
      ; Cause type conversion error.
      if flag then pa += double(param_opt[n_circle*4+6*i+5])

      pa = reform(pa, [n_particles,1])

      xx[*,n_circle*4+6*i+3] = reform(sqrt(fwhmmajor[*, 0] * fwhmminor[*, 0]))
      ecmsr   = reform(-alog(fwhmminor[*, 0] / fwhmmajor[*, 0]))

      xx[*,n_circle*4+6*i+4] = ecmsr * cos(reform(pa * !dtor))
      xx[*,n_circle*4+6*i+5] = ecmsr * sin(reform(pa * !dtor))

      u1 = cos(pa * !dtor) # u + sin(pa * !dtor) # v
      v1 = -sin(pa * !dtor) # u + cos(pa * !dtor) # v

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_x_ellipse:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_x_ellipse
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+6*i+1] = xx[*, n_circle*4+6*i+1] * 0. + double(param_opt[n_circle*4+6*i+1]) - mapcenter[0]
      x_loc = reform(xx[*,n_circle*4+6*i+1], [n_particles,1])

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_y_ellipse:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_y_ellipse
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+6*i+2] = xx[*, n_circle*4+6*i+2] * 0. + double(param_opt[n_circle*4+6*i+2]) - mapcenter[1]
      y_loc = reform(xx[*,n_circle*4+6*i+2], [n_particles,1])

      vispred_re += flux * exp(-(!pi^2. / (4.*alog(2.)))*((u1 * fwhmmajor)^2. + (v1 * fwhmminor)^2.))*cos(2*!pi*((x_loc#u)+(y_loc#v)))
      vispred_im += flux * exp(-(!pi^2. / (4.*alog(2.)))*((u1 * fwhmmajor)^2. + (v1 * fwhmminor)^2.))*sin(2*!pi*((x_loc#u)+(y_loc#v)))
           
    endfor
    
  endif  
  
  
  if n_loop gt 0 then begin

    for i=0, n_loop-1 do begin
  
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_flux_loop:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_flux_loop
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+n_ellipse*6+7*i] = xx[*, n_circle*4+n_ellipse*6+7*i] * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i])
      flux = xx[*, n_circle*4+n_ellipse*6+7*i]
      ;flux = reform(flux, [n_particles,1])
      ;flux = flux # ones
    
      eccos = reform(xx[*,n_circle*4+n_ellipse*6+7*i+4], [n_particles,1])
      ecsin = reform(xx[*,n_circle*4+n_ellipse*6+7*i+5], [n_particles,1])
    
      ecmsr = sqrt( eccos^2. + ecsin^2. )
      eccen = sqrt(1. - exp(-2. * ecmsr))
    
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhmmax_loop:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhmmax_loop
      if flag then fwhmmajor = eccen * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i+3])
    
      flag1=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhmmin_loop:
        flag1=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhmmin_loop
      if flag1 then fwhmminor = eccen * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i+4])
    
      if flag and ~flag1 then fwhmminor = fwhmmajor * ((1 - eccen^2.)^0.25)^2.
      if ~flag and flag1 then  fwhmmajor = fwhmminor / ((1 - eccen^2.)^0.25)^2.
      if ~flag and ~flag1 then begin
    
        fwhm1 = xx[*,n_circle*4+n_ellipse*6+7*i+3]
        fwhm1 = reform(fwhm1, [n_particles,1])
        fwhmminor = fwhm1 * (1 - eccen^2.)^0.25
        fwhmmajor = fwhm1 / (1 - eccen^2.)^0.25
    
      endif
    
      fwhmminor = fwhmminor # ones
      fwhmmajor = fwhmmajor # ones
    
      pa = fltarr(size(eccen, /dim))
    
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_alpha_loop:
        pa = atan(ecsin, eccos) * !radeg
        ;      pa      = eccen * 0.
        ;      ind     = where(eccen GT 0.001)
        ;      pa[ind] = ATAN(ecsin[ind], eccos[ind]) * !RADEG
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_alpha_loop
      ; Cause type conversion error.
      if flag then pa += double(param_opt[n_circle*4+n_ellipse*6+7*i+5])
      pa = reform(pa, [n_particles,1])
    
      xx[*,n_circle*4+n_ellipse*6+7*i+3] = reform(sqrt(fwhmmajor[*, 0] * fwhmminor[*, 0]))
      ecmsr   = reform(-alog(fwhmminor[*, 0] / fwhmmajor[*, 0]))
    
      xx[*,n_circle*4+n_ellipse*6+7*i+4] = ecmsr * cos(reform(pa * !dtor))
      xx[*,n_circle*4+n_ellipse*6+7*i+5] = ecmsr * sin(reform(pa * !dtor))
    
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_x_loop:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_x_loop
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+n_ellipse*6+7*i+1] = xx[*, n_circle*4+n_ellipse*6+7*i+1] * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i+1]) - mapcenter[0]
      x_loc = reform(xx[*,n_circle*4+n_ellipse*6+7*i+1], [n_particles,1])
    
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_y_loop:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_y_loop
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+n_ellipse*6+7*i+2] = xx[*, n_circle*4+n_ellipse*6+7*i+2] * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i+2]) - mapcenter[1]
      y_loc = reform(xx[*,n_circle*4+n_ellipse*6+7*i+2], [n_particles,1])
    
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_loop_angle:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_loop_angle
      ; Cause type conversion error.
      if flag then xx[*, n_circle*4+n_ellipse*6+7*i+6] = xx[*, n_circle*4+n_ellipse*6+7*i+6] * 0. + double(param_opt[n_circle*4+n_ellipse*6+7*i+6])
      loop_angle = reform(xx[*,n_circle*4+n_ellipse*6+7*i+6], [n_particles,1])
    
      vis_pred = vis_fwdfit_pso_func_makealoop( flux, xx[*,n_circle*4+n_ellipse*6+7*i+3], eccen, x_loc, y_loc, pa, loop_angle, u, v)
    
      vispred_re += vis_pred[*,0:n_elements(u)-1]
      vispred_im += vis_pred[*, n_elements(u):2*n_elements(u)-1]
      
    endfor
  endif  

  vispred = [[vispred_re], [vispred_im]]
  chi = total(abs(vispred - visobs)^2./sigamp^2., 2)/n_free

  RETURN, chi

end