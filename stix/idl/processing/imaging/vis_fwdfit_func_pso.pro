FUNCTION vis_fwdfit_func_pso, xx, extra = extra


  type = extra.type
  visobs = extra.visobs
  sigamp = extra.sigamp
  u = extra.u
  v = extra.v
  n_free = extra.n_free
  param_opt = extra.param_opt
  mapcenter = extra.mapcenter

  n_particles = (size(xx,/dimension))[0]
  n_vis    = n_elements(u)
  u        = reform(u, [1, n_vis])
  v        = reform(v, [1, n_vis])

  if type eq 'circle' then begin
    
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
    if flag then xx[*, 0] = xx[*, 0] * 0. + double(param_opt[0])
    flux = xx[*, 0]
    ones = fltarr(1, n_vis) + 1.
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
    if flag then xx[*, 1] = xx[*, 1] * 0. + double(param_opt[1]) - mapcenter[0]
    x_loc = reform(xx[*, 1], [n_particles,1])
    
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
    if flag then xx[*, 2] = xx[*, 2] * 0. + double(param_opt[2]) - mapcenter[1]
    y_loc = reform(xx[*,2], [n_particles,1])
    
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
    if flag then xx[*, 3] = xx[*, 3] * 0. + double(param_opt[3])
    fwhm = reform(xx[*,3], [n_particles,1])

    vispred_re = flux * exp(-(!pi^2. * fwhm^2. / (4.*alog(2.)))#(u^2. + v^2.))*cos(2*!pi*((x_loc#u)+(y_loc#v)))
    vispred_im = flux * exp(-(!pi^2. * fwhm^2. / (4.*alog(2.)))#(u^2. + v^2.))*sin(2*!pi*((x_loc#u)+(y_loc#v)))
    
  endif


  if type eq 'ellipse' then begin

    ones = fltarr(1, n_vis) + 1.
    
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
    if flag then xx[*, 0] = xx[*, 0] * 0. + double(param_opt[0])
    flux = xx[*, 0]
    ones = fltarr(1, n_vis) + 1.
    flux = reform(flux, [n_particles,1])
    flux = flux # ones
    
    eccos = reform(xx[*,2], [n_particles,1])
    ecsin = reform(xx[*,3], [n_particles,1])
    
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
    if flag then fwhmmajor = eccen * 0. + double(param_opt[1])

    flag1=1
    Catch, theError
    IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      bad_fwhmmin_ellipse:
      flag1=0
    ENDIF
    ; Set up file I/O error handling.
    ON_IOError, bad_fwhmmin_ellipse
    if flag1 then fwhmminor = eccen * 0. + double(param_opt[2])  
    
    if flag and ~flag1 then fwhmminor = fwhmmajor * ((1 - eccen^2.)^0.25)^2.
    if ~flag and flag1 then  fwhmmajor = fwhmminor / ((1 - eccen^2.)^0.25)^2.
    if ~flag and ~flag1 then begin
      
      fwhm = xx[*,1]
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
    if flag then pa += double(param_opt[3])

    pa = reform(pa, [n_particles,1])  

    xx[*,1] = reform(sqrt(fwhmmajor[*, 0] * fwhmminor[*, 0]))
    ecmsr   = reform(-alog(fwhmminor[*, 0] / fwhmmajor[*, 0]))

    xx[*,2] = ecmsr * cos(reform(pa * !dtor))
    xx[*,3] = ecmsr * sin(reform(pa * !dtor))

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
    if flag then xx[*, 4] = xx[*, 4] * 0. + double(param_opt[4]) - mapcenter[0]
    x_loc = reform(xx[*,4], [n_particles,1])
    
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
    if flag then xx[*, 5] = xx[*, 5] * 0. + double(param_opt[5]) - mapcenter[1]
    y_loc = reform(xx[*,5], [n_particles,1])

    vispred_re = flux * exp(-(!pi^2. / (4.*alog(2.)))*((u1 * fwhmmajor)^2. + (v1 * fwhmminor)^2.))*cos(2*!pi*((x_loc#u)+(y_loc#v)))
    vispred_im = flux * exp(-(!pi^2. / (4.*alog(2.)))*((u1 * fwhmmajor)^2. + (v1 * fwhmminor)^2.))*sin(2*!pi*((x_loc#u)+(y_loc#v)))

  endif
  
   
  if type eq 'multi' then begin
    
      ones = fltarr(1, n_vis) + 1.

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhm1_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhm1_multi
      ; Cause type conversion error.
      if flag then xx[*, 0] = xx[*, 0] * 0. + double(param_opt[0])
      fwhm1 = reform(xx[*,0], [n_particles,1])
      
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_flux1_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_flux1_multi
      ; Cause type conversion error.
      if flag then xx[*, 1] = xx[*, 1] * 0. + double(param_opt[1]) 
      flux1 = xx[*,1]
      flux1 = reform(flux1, [n_particles,1])
      flux1 = flux1 # ones

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_fwhm2_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_fwhm2_multi
      ; Cause type conversion error.
      if flag then xx[*, 2] = xx[*, 2] * 0. + double(param_opt[2])      
      fwhm2 = reform(xx[*,2], [n_particles,1])     

         
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_flux2_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_flux2_multi
      ; Cause type conversion error.
      if flag then xx[*, 3] = xx[*, 3] * 0. + double(param_opt[3])
      flux2 = xx[*,3]
      flux2 = reform(flux2, [n_particles,1])
      flux2 = flux2 # ones
      
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_x1_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_x1_multi
      ; Cause type conversion error.
      if flag then xx[*, 4] = xx[*, 4] * 0. + double(param_opt[4]) - mapcenter[0]
      x1 = reform(xx[*,4], [n_particles,1])
            
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_y1_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_y1_multi
      ; Cause type conversion error.
      if flag then xx[*, 5] = xx[*, 5] * 0. + double(param_opt[5]) - mapcenter[1]
      y1 = reform(xx[*,5], [n_particles,1])
      
      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_x2_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_x2_multi
      ; Cause type conversion error.
      if flag then xx[*, 6] = xx[*, 6] * 0. + double(param_opt[6]) - mapcenter[0]
      x2 = reform(xx[*, 6], [n_particles,1])

      flag=1
      Catch, theError
      IF theError NE 0 THEN BEGIN
        Catch, /Cancel
        bad_y2_multi:
        flag=0
      ENDIF
      ; Set up file I/O error handling.
      ON_IOError, bad_y2_multi
      ; Cause type conversion error.
      if flag then xx[*, 7] = xx[*, 7] * 0. + double(param_opt[7]) - mapcenter[1]
      y2 = reform(xx[*,7], [n_particles,1])
      
      re_obs1 = flux1 * exp(-(!pi^2. * fwhm1^2. / (4.*alog(2.)))#(u^2. + v^2.))*cos(2*!pi*((x1#u)+(y1#v)))
      im_obs1 = flux1 * exp(-(!pi^2. * fwhm1^2. / (4.*alog(2.)))#(u^2. + v^2.))*sin(2*!pi*((x1#u)+(y1#v)))

      re_obs2 = flux2 * exp(-(!pi^2. * fwhm2^2. / (4.* alog(2.)))#(u^2. + v^2.))*cos(2*!pi*((x2#u)+(y2#v)))
      im_obs2 =  flux2 * exp(-(!pi^2. * fwhm2^2. / (4.* alog(2.)))#(u^2. + v^2.))*sin(2*!pi*((x2#u)+(y2#v)))

      vispred_re = re_obs1 + re_obs2
      vispred_im = im_obs1 + im_obs2
      
  endif
  

  if type eq 'loop' then begin

    ones = fltarr(1, n_vis) + 1.

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
    if flag then xx[*, 0] = xx[*, 0] * 0. + double(param_opt[0])
    flux = xx[*, 0]
    ones = fltarr(1, n_vis) + 1.
    ;flux = reform(flux, [n_particles,1])
    ;flux = flux # ones

    eccos = reform(xx[*,2], [n_particles,1])
    ecsin = reform(xx[*,3], [n_particles,1])

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
    if flag then fwhmmajor = eccen * 0. + double(param_opt[1])

    flag1=1
    Catch, theError
    IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      bad_fwhmmin_loop:
      flag1=0
    ENDIF
    ; Set up file I/O error handling.
    ON_IOError, bad_fwhmmin_loop
    if flag1 then fwhmminor = eccen * 0. + double(param_opt[2])

    if flag and ~flag1 then fwhmminor = fwhmmajor * ((1 - eccen^2.)^0.25)^2.
    if ~flag and flag1 then  fwhmmajor = fwhmminor / ((1 - eccen^2.)^0.25)^2.
    if ~flag and ~flag1 then begin

      fwhm1 = xx[*,1]
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
    if flag then pa += double(param_opt[3])
    pa = reform(pa, [n_particles,1])

    xx[*,1] = reform(sqrt(fwhmmajor[*, 0] * fwhmminor[*, 0]))
    ecmsr   = reform(-alog(fwhmminor[*, 0] / fwhmmajor[*, 0]))

    xx[*,2] = ecmsr * cos(reform(pa * !dtor))
    xx[*,3] = ecmsr * sin(reform(pa * !dtor))

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
    if flag then xx[*, 4] = xx[*, 4] * 0. + double(param_opt[4]) - mapcenter[0]
    x_loc = reform(xx[*,4], [n_particles,1])

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
    if flag then xx[*, 5] = xx[*, 5] * 0. + double(param_opt[5]) - mapcenter[1]
    y_loc = reform(xx[*,5], [n_particles,1])
    
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
    if flag then xx[*, 6] = xx[*, 6] * 0. + double(param_opt[6])
    loop_angle = reform(xx[*,6], [n_particles,1])
    
    vis_pred = vis_fwdfit_pso_func_makealoop( flux, xx[*,1], eccen, x_loc, y_loc, pa, loop_angle, u, v)
       
    vispred_re = vis_pred[*,0:n_elements(u)-1]
    vispred_im = vis_pred[*, n_elements(u):2*n_elements(u)-1]

endif
  
  

  vispred = [[vispred_re], [vispred_im]]
  chi = total(abs(vispred - visobs)^2./sigamp^2., 2)/n_free
  
  RETURN, chi

END