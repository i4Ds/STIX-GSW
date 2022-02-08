function vis_FWDFIT_PSO_SOURCE2MAP, srcstr, type=type, pixel=pixel, imsize=mapsize, xyoffset=xyoffset

  default, pixel, [1., 1.]
  default, mapsize, [128, 128]
  default, xyoffset, [0., 0.]

  ; Define the map and its axes.
  data    = FLTARR(mapsize[0],mapsize[1])
  xy      = Reform( ( Pixel_coord( [mapsize[0], mapsize[1]] ) ), 2, mapsize[0], mapsize[1] )
  x       = reform(xy[0, *, *])*pixel[0] + xyoffset[0]
  y       = reform(xy[1, *, *])*pixel[1] + xyoffset[1]
  
  im_tmp=x*0.

  nsrc = N_ELEMENTS(srcstr)

  FOR n = 0, nsrc-1 DO BEGIN

    if type eq 'loop' then begin

      ; LOOP CREATION
      ncirc0      = 21     ; Upper limit to number of ~equispaced circles that will be used to approximate loop.
      PLUSMINUS   = [-1,1]
      SIG2FWHM    = SQRT(8 * ALOG(2.))

      ; Calculate the relative strengths of the sources to reproduce a gaussian and their collective stddev.
      iseq0       = INDGEN(ncirc0)
      relflux0    = FLTARR(ncirc0)
      relflux0    = FACTORIAL(ncirc0-1) / (FLOAT(FACTORIAL(iseq0)*FACTORIAL(ncirc0-1-iseq0))) / 2.^(ncirc0-1) ; TOTAL(relflux)=1
      ok          = WHERE(relflux0 GT 0.01, ncirc)      ; Just keep circles that contain at least 1% of flux
      relflux     = relflux0[ok] / TOTAL(relflux0[ok])
      iseq        = INDGEN(ncirc)
      reltheta    = (iseq/(ncirc-1.) - 0.5)                       ; locations of circles for arclength=1
      factor      = SQRT(TOTAL(reltheta^2 *relflux)) * SIG2FWHM   ; FWHM of binomial distribution for arclength=1

      loopangle   = srcstr.loop_angle* !DTOR / factor
      IF ABS(loopangle) GT 1.99*!PI THEN MESSAGE, 'Internal parameterization error - Loop arc exceeds 2pi.'
      IF loopangle EQ 0 THEN loopangle = 0.01                     ; radians. Avoids problems if loopangle = 0
      
      theta       = ABS(loopangle) * (iseq/(ncirc-1.) - 0.5)      ; equispaced between +- loopangle/2
      xloop       = SIN(theta)                                    ; for unit radius of curvature, R
      yloop       = COS(theta)                                    ; relaive to center of curvature
      IF loopangle LT 0 THEN yloop = -yloop                       ; Sign of loopangle determines sense of loop curvature

      ; Determine the size and location of the equivalent separated components in a coord system where...
      ; x is an axis parallel to the line joining the footpoints
      ; Note that there are combinations of loop angle, sigminor and sigmajor that cannot occur with radius>1arcsec.
      ; In such a case circle radius is set to 1.  Such cases will lead to bad solutions and be flagged as such at the end.

      sigminor    = srcstr.srcfwhm_min / SIG2FWHM
      sigmajor    = srcstr.srcfwhm_max / SIG2FWHM
      fsumx2      = TOTAL(xloop^2*relflux)         ; scale-free factors describing loop moments for endpoint separation=1
      fsumy       = TOTAL(yloop*relflux)
      fsumy2      = TOTAL(yloop^2*relflux)
      loopradius  = SQRT((sigmajor^2 - sigminor ^2) / (fsumx2  - fsumy2  + fsumy^2))
      term        = (sigmajor^2 - loopradius^2 *fsumx2) > 0    ; >0 condition avoids problems in next step.
      circfwhm    = SIG2FWHM * SQRT(term) > 1                  ; Set minimum to avoid display problems

      sep         = 2.*loopradius * ABS(SIN(theta[0]))
      cgshift     = loopradius  * fsumy                ; will enable emission centroid location to be unchanged
      relx        = xloop * loopradius                 ; x is axis joining 'footpoints'
      rely        = yloop * loopradius  - cgshift
      ;
      ; Calculate source structures for each circle.
      pasep       = srcstr.srcpa *!DTOR
      eccen_new   = 0                                  ; Circular sources
      pa_new      = 0

      sinus       = sin(pasep*!dtor)
      cosinus     = cos(pasep*!dtor)

      FOR i = 0,n_elements(iseq)-1 do begin

        flux_new    = srcstr.srcflux * relflux[i]               ; Split the flux between components.
        x_loc_new   = srcstr.srcx - relx[i]* SIN(pasep) + rely[i]* COS(pasep)
        y_loc_new   = srcstr.srcy + relx[i]* COS(pasep) + rely[i]* SIN(pasep)

        x_tmp       = ((x-x_loc_new)*cosinus) + ((y-y_loc_new)*sinus)
        y_tmp       = - ((x-x_loc_new)*sinus) + ((y-y_loc_new)*cosinus)
        x_tmp       = 2.*sqrt( 2.*alog(2.) )*x_tmp/circfwhm
        y_tmp       = 2.*sqrt( 2.*alog(2.) )*y_tmp/circfwhm
        im_tmp      = exp(-((x_tmp)^2. + (y_tmp)^2.)/2.)
        data       += im_tmp/(total(im_tmp)*pixel[0]*pixel[1])*flux_new

      ENDFOR

    endif else begin

      xcen     = srcstr[n].srcx
      ycen     = srcstr[n].srcy
      flux     = srcstr[n].srcflux

      fwhm_max = srcstr[n].srcfwhm_max
      fwhm_min = srcstr[n].srcfwhm_min
      pa       = srcstr[n].srcpa

      sinus    = sin(pa*!dtor)
      cosinus  = cos(pa*!dtor)

      x_tmp    = ((x-xcen)*cosinus) + ((y-ycen)*sinus)
      y_tmp    = - ((x-xcen)*sinus) + ((y-ycen)*cosinus)
      
    if fwhm_max eq 0 or fwhm_min eq 0 then begin
      
        x_tmp = x_tmp*0.
        y_tmp = y_tmp*0.
        
     endif else begin
      
        x_tmp    = 2.*sqrt( 2.*alog(2.) )*x_tmp/fwhm_max
        y_tmp    = 2.*sqrt( 2.*alog(2.) )*y_tmp/fwhm_min
           
     endelse

     im_tmp   = exp(-((x_tmp)^2. + (y_tmp)^2.)/2.)
      
     if max(im_tmp) ne 0. then begin

        data    += im_tmp/(total(im_tmp)*pixel[0]*pixel[1])*flux
    
     endif

    endelse


  ENDFOR

  return, data
  ;make_map(data, xcen=xyoffset[0],ycen=xyoffset[1], dx = pixel[0], dy = pixel[1], id = 'STIX PSO' )

END