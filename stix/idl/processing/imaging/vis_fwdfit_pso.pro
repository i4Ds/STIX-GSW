
; NAME:
;   vis_fwdfit_pso
;
; PURPOSE:
;   forward fitting method from visibility based on Particle Swarm Optimization
;
; CALLING SEQUENCE:
;   vis_fwdfit_pso, type, vis
;
; CALLS:
;   cmreplicate                     [replicates an array or scalar into a larger array, as REPLICATE does.]
;   vis_fwdfit_func_pso             [to calculate visibilities for a given set of source parameters]
;   vis_fwdfit_pso_func_makealoop   [to calculate loop Fourier trasform]
;   swarmintelligence               [to PSO procedure for optimizing the parameters]
;   vis_fwdfit_pso_src_structure    [to create the source structure]
;   vis_fwdfit_pso_src_bifurcate    [to create a modified source structure based on bifurcation of input source structure]
;   vis_fwdfit_pso_source2map       [to create the map from the optimized parameters]
;
;
; INPUTS:
;   type: parametric shape to use for the forward fitting method
;         - 'circle' : Gaussian circular source
;         - 'ellipse': Gaussian elliptical source
;         - 'multi'  : doupper_boundle Gaussian circular source
;         - 'loop'   : single curved elliptical gaussian
;
;   vis         : struct containing  the observed visibility values
;     vis.obsvis: array containing the values of the observed visibilit
;     vis.sigamp: array containing the values of the errors on the observed visibility amplitudes
;     vis.u     : u coordinates of the sampling frequencies
;     vis.v     : v coordinates of the sampling frequencies
;
;
; KEYWORDS:
;   lower_bound: array containing the lower bound values of the variables to optimize
;   upper_bound: array containing the upper bound values of the variables to optimize
;
;   For different shapes we have:
;
;       - 'circle'  : lower_bound,upper_bound = [flux, x location, y location, FWHM]
;       - 'ellipse' : lower_bound,upper_bound = [flux, FWHM, ecc * cos(alpha), ecc * sin(alpha), x location, y location]
;                     'ecc' is the eccentricity of the ellipse and 'alpha' is the orientation angle
;       - 'multi'   : lower_bound,upper_bound = [FWHM1, flux1, FWHM2, flux2, x1 location, y1 location, x2 location, y2 location]
;       - 'loop'    : lower_bound,upper_bound = [flux, FWHM, ecc * cos(alpha), ecc * sin(alpha), x location, y location, loop_angle]
;
;   param_opt: array containing the values of the parameters to keep fixed during the optimization.
;              If an entry of 'param_opt' is set equal to 'fit', then the corresponding variable is optimized.
;              Otherwise, its value is kept fixed equal to the entry of 'param_opt'
;
;   For different shapes we have:
;
;       - 'circle'  : param_opt = [flux, x location, y location, FWHM]
;       - 'ellipse' : param_opt = [flux, FWHM max, FWHM min, alpha, x location, y location]
;                     'alpha' is the orientation angle of the source
;       - 'multi'   : param_opt = [FWHM1, flux1, FWHM2, flux2, x1 location, y1 location, x2 location, y2 location]
;       - 'loop'    : param_opt = [flux, FWHM max, FWHM min, alpha, x location, y location, loop_angle]
;
;   Example (circular source): setting param_opt = ['10', 'fit', 'fit', 'fit'], we fix the total flux of the source equal to 10
;                              and we fit the remaining parameters
;
;   n_birds   : number of particles used in PSO (default is 100)
;   tolerance : tolerance for the stopping criterion (default is 1e-6)
;   maxiter   : maximum number of iterations of PSO
;              (defult is the product between of the numbers of parameters and the number of particles)
;   uncertainty : set to 1 for the computation of the parameters uncertainty (confidence strip approach)
;   silent      : set to 1 for avoiding the print of the retrieved parameters
;
;
;   SRCSTR: structure containing the values of the fitted parameters.
;   FITSIGMAS structure containing the values of the uncertainty on the fitted parameters.
;
; HISTORY: November 2021, Volpara A. created
;
; CONTACT:
;   volpara [at] dima.unige.it

function vis_fwdfit_pso, type, vis, $
  lower_bound = lower_bound, upper_bound = upper_bound, $
  param_opt = param_opt, $
  n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, $
  uncertainty = uncertainty, $
  imsize=imsize, pixel=pixel, $
  silent = silent, $
  seedstart = seedstart


  default, n_birds, 100.
  default, tolerance, 1e-06
  default, silent, 0
  default, imsize, [128,128]
  default, pixel, [1.,1.]
  default, seedstart, fix(randomu(seed) * 100)

  phi= max(abs(vis.obsvis)) ;estimate_flux

  case type of

    'circle': begin
      default, param_opt, ['fit', 'fit', 'fit', 'fit']
      default, lower_bound, [0.1*phi, -100., -100., 1.]
      default, upper_bound, [1.5*phi, 100., 100., 100.]
    end

    'ellipse': begin
      default, param_opt, ['fit', 'fit', 'fit', 'fit', 'fit', 'fit']
      default, lower_bound, [0.1*phi,  1., -5., 0., -100., -100.]
      default, upper_bound, [1.5*phi, 100., 5., 1., 100., 100.]
    end

    'multi': begin
      default, param_opt, ['fit' , 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit']
      default, lower_bound, [0.,  0.1*phi, 0.,  0.1*phi, -100., -100., -100., -100.]
      default, upper_bound, [100., 1.5*phi, 100., 1.5*phi, 100., 100., 100., 100.]
    end

    'loop': begin
      default, param_opt, ['fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit']
      default, lower_bound, [0.1*phi,  1., -5., 0., -100., -100., -180.]
      default, upper_bound, [1.5*phi, 100., 5., 1., 100., 100., 180.]
    end

  endcase


  obj_fun_name = 'vis_fwdfit_func_pso'
  Nvars = n_elements(lower_bound)

  visobs = [real_part(vis.obsvis), imaginary(vis.obsvis)]
  nvis   = N_ELEMENTS(visobs)
  vvisobs = transpose(cmreplicate(visobs, n_birds))
  sigamp  = [vis.sigamp,vis.sigamp]
  ssigamp = transpose(cmreplicate(sigamp, n_birds))

  extra = {type: type, $
    visobs: vvisobs, $
    sigamp: ssigamp, $
    u: vis.u, $
    v: vis.v, $
    n_free: nvis - Nvars, $    ;n_free: degrees of freedom (difference between the number of visibility amplitudes
    ;and the number of parameters of the source shape)
    param_opt: param_opt, $
    mapcenter : vis.xyoffset }

  if type eq 'circle' then begin

    n_free = nvis - 4.

    if (n_elements(param_opt) ne 4) or (n_elements(lower_bound) ne 4) or (n_elements(upper_bound) ne 4) then begin
      UNDEFINE, lower_bound
      UNDEFINE, upper_bound
      UNDEFINE, param_opt
      message, 'Wrong number of elements of lower bound, upper bound or parameter mask'
    endif

    optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
      n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
    xopt = optim_f.xopt

    srcstr = {vis_fwdfit_pso_src_structure}
    srcstr.srctype ='circle'

    fitsigmas = {vis_fwdfit_pso_src_structure}
    fitsigmas.srctype ='std.dev'

    srcstr.srcflux         = xopt[0]
    srcstr.srcx            = xopt[1] + vis[0].xyoffset[0]
    srcstr.srcy            = xopt[2] + vis[0].xyoffset[1]
    srcstr.srcfwhm_max     = xopt[3]
    srcstr.srcfwhm_min     = xopt[3]

    if keyword_set(uncertainty) then begin

      print, ' '
      print, 'Uncertainty: '
      print, '

      ntry = 20

      trial_results = fltarr(Nvars, ntry)
      iseed = findgen(ntry)+seedstart

      for n=0,ntry-1 do begin

        testerror = RANDOMN(iseed[n], nvis)                   ; nvis element vector normally distributed with sigma = 1
        vistest   = visobs + testerror * sigamp
        vistest   = transpose(cmreplicate(vistest, n_birds))

        extra = {type: type, $
          visobs: vistest, $
          sigamp: ssigamp, $
          u: vis.u, $
          v: vis.v, $
          n_free: nvis - Nvars, $
          param_opt: param_opt, $
          mapcenter : vis.xyoffset}

        optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
          n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
        xopt = optim_f.xopt

        trial_results[*,n]  = xopt

      endfor

      std_dev_par = stddev(trial_results, dimension=2)

      fitsigmas.srcflux      = std_dev_par[0]
      fitsigmas.srcx         = std_dev_par[1]
      fitsigmas.srcy         = std_dev_par[2]
      fitsigmas.srcfwhm_max  = std_dev_par[3]
      fitsigmas.srcfwhm_min  = std_dev_par[3]

    endif

  endif

  if type eq 'ellipse' then begin

    n_free = nvis-6.

    if (n_elements(param_opt) ne 6) or (n_elements(lower_bound) ne 6) or (n_elements(upper_bound) ne 6) then begin
      UNDEFINE, lower_bound
      UNDEFINE, upper_bound
      UNDEFINE, param_opt
      message, 'Wrong number of elements of lower bound, upper bound or parameter mask'
    endif


    optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
      n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
    xopt = optim_f.xopt

    srcstr = {vis_fwdfit_pso_src_structure}
    srcstr.srctype    ='ellipse'

    fitsigmas = {vis_fwdfit_pso_src_structure}
    fitsigmas.srctype ='std.dev'

    srcstr.srcflux = xopt[0]

    ecmsr = REFORM(SQRT(xopt[2]^2 + xopt[3]^2))
    eccen = SQRT(1 - EXP(-2*ecmsr))

    srcstr.eccen = eccen

    IF ecmsr GT 0 THEN srcstr.srcpa = reform(ATAN(xopt[3], xopt[2]) * !RADEG)
    IF srcstr.srcpa lt 0. then srcstr.srcpa += 180.

    srcstr.srcfwhm_min = xopt[1] * (1-eccen^2)^0.25
    srcstr.srcfwhm_max = xopt[1] / (1-eccen^2)^0.25
    srcstr.srcx        = xopt[4] + vis[0].xyoffset[0]
    srcstr.srcy        = xopt[5] + vis[0].xyoffset[1]

    if keyword_set(uncertainty) then begin

      print, ' '
      print, 'Uncertainty: '
      print, '

      ntry = 20

      trial_results = fltarr(Nvars, ntry)
      iseed=findgen(ntry)+seedstart

      for n=0,ntry-1 do begin
        testerror = RANDOMN(iseed[n], nvis)
        vistest   = visobs + testerror * sigamp
        vistest   = transpose(cmreplicate(vistest, n_birds))

        extra = {type: type, $
          visobs: vistest, $
          sigamp: ssigamp, $
          u: vis.u, $
          v: vis.v, $
          n_free: nvis - Nvars, $
          param_opt: param_opt, $
          mapcenter : vis.xyoffset}

        optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
          n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
        xopt = optim_f.xopt


        ecmsr = REFORM(SQRT(xopt[2]^2 + xopt[3]^2))
        eccen = SQRT(1 - EXP(-2*ecmsr))

        IF ecmsr GT 0 THEN trial_results[3,n] = reform(ATAN(xopt[3], xopt[2]) * !RADEG) + 180.

        trial_results[0,n]  = xopt[0]
        trial_results[1,n]  = xopt[1] / (1-eccen^2)^0.25
        trial_results[2,n]  = xopt[1] * (1-eccen^2)^0.25
        trial_results[4,n]  = xopt[4]
        trial_results[5,n]  = xopt[5]

      endfor

      fitsigmas.srcflux        = stddev(trial_results[0, *])
      fitsigmas.srcfwhm_max    = stddev(trial_results[1, *])
      fitsigmas.srcfwhm_min    = stddev(trial_results[2, *])
      avsrcpa                  = ATAN(TOTAL(SIN(trial_results[3, *] * !DTOR)), $
        TOTAL(COS(trial_results[3, *] * !DTOR))) * !RADEG
      groupedpa                = (810 + avsrcpa - trial_results[3, *]) MOD 180.
      fitsigmas.srcpa          = STDDEV(groupedpa)
      fitsigmas.srcx           = stddev(trial_results[4,*])
      fitsigmas.srcy           = stddev(trial_results[5,*])
    endif

  endif

  if type EQ 'multi' then begin

    n_free = nvis-8.

    if (n_elements(param_opt) ne 8) or (n_elements(lower_bound) ne 8) or (n_elements(upper_bound) ne 8) then begin
      UNDEFINE, lower_bound
      UNDEFINE, upper_bound
      UNDEFINE, param_opt
      message, 'Wrong number of elements of lower bound, upper bound or parameter mask'
    endif

    Nruns = 20
    xx_opt = []
    f = fltarr(Nruns)

    for i = 0,Nruns-1 do begin
      optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
        n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
      f[i]    = optim_f.fopt
      xx_opt  = [[xx_opt],optim_f.xopt]
    endfor

    dummy = min(f,location)
    xopt  = xx_opt(location,*)

    srcstr = {vis_fwdfit_pso_src_structure}
    srcstr.srctype ='ellipse'
    srcstr = VIS_FWDFIT_PSO_SRC_BIFURCATE(srcstr)

    fitsigmas = {vis_fwdfit_pso_src_structure}
    fitsigmas.srctype ='std.dev'
    fitsigmas = VIS_FWDFIT_PSO_SRC_BIFURCATE(fitsigmas)

    ;top–left footpoint is referred to as first source
    if (xopt[5] - xopt[7]) ge 3. then begin

      srcstr[0].srcflux       = xopt[1]
      srcstr[0].srcfwhm_max   = xopt[0]
      srcstr[0].srcfwhm_min   = xopt[0]
      srcstr[0].srcx          = xopt[4] + vis[0].xyoffset[0]
      srcstr[0].srcy          = xopt[5] + vis[0].xyoffset[1]

      srcstr[1].srcflux       = xopt[3]
      srcstr[1].srcfwhm_max   = xopt[2]
      srcstr[1].srcfwhm_min   = xopt[2]
      srcstr[1].srcx          = xopt[6] + vis[0].xyoffset[0]
      srcstr[1].srcy          = xopt[7] + vis[0].xyoffset[1]

    endif else begin
      if (xopt[7] - xopt[5]) ge 3. then begin

        srcstr[1].srcflux       = xopt[1]
        srcstr[1].srcfwhm_max   = xopt[0]
        srcstr[1].srcfwhm_min   = xopt[0]
        srcstr[1].srcx          = xopt[4] + vis[0].xyoffset[0]
        srcstr[1].srcy          = xopt[5] + vis[0].xyoffset[1]

        srcstr[0].srcflux       = xopt[3]
        srcstr[0].srcfwhm_max   = xopt[2]
        srcstr[0].srcfwhm_min   = xopt[2]
        srcstr[0].srcx          = xopt[6] + vis[0].xyoffset[0]
        srcstr[0].srcy          = xopt[7] + vis[0].xyoffset[1]

      endif else begin
        if xopt[4] ge xopt[6] then begin

          srcstr[0].srcflux       = xopt[1]
          srcstr[0].srcfwhm_max   = xopt[0]
          srcstr[0].srcfwhm_min   = xopt[0]
          srcstr[0].srcx          = xopt[4] + vis[0].xyoffset[0]
          srcstr[0].srcy          = xopt[5] + vis[0].xyoffset[1]

          srcstr[1].srcflux       = xopt[3]
          srcstr[1].srcfwhm_max   = xopt[2]
          srcstr[1].srcfwhm_min   = xopt[2]
          srcstr[1].srcx          = xopt[6] + vis[0].xyoffset[0]
          srcstr[1].srcy          = xopt[7] + vis[0].xyoffset[1]

        endif  else begin

          srcstr[1].srcflux       = xopt[1]
          srcstr[1].srcfwhm_max   = xopt[0]
          srcstr[1].srcfwhm_min   = xopt[0]
          srcstr[1].srcx          = xopt[4] + vis[0].xyoffset[0]
          srcstr[1].srcy          = xopt[5] + vis[0].xyoffset[1]

          srcstr[0].srcflux       = xopt[3]
          srcstr[0].srcfwhm_max   = xopt[2]
          srcstr[0].srcfwhm_min   = xopt[2]
          srcstr[0].srcx          = xopt[6] + vis[0].xyoffset[0]
          srcstr[0].srcy          = xopt[7] + vis[0].xyoffset[1]

        endelse
      endelse
    endelse


    if keyword_set(uncertainty) then begin

      print, ' '
      print, 'Uncertainty: '
      print, '

      ntry = 20
      trial_results = fltarr(Nvars, ntry)
      ;iseed=findgen(ntry)+seedstart

      Nruns = 5.

      lower_bound = [min([srcstr[0].srcfwhm_max, srcstr[1].srcfwhm_max])-30.>0., 0.4*min([srcstr[0].srcflux,srcstr[1].srcflux]),$
        min([srcstr[0].srcfwhm_max, srcstr[1].srcfwhm_max])-30.>0., 0.4*min([srcstr[0].srcflux,srcstr[1].srcflux]),$
        -100., -100., -100., -100.]

      upper_bound = [max([srcstr[0].srcfwhm_max, srcstr[1].srcfwhm_max])+30., 2.*max([srcstr[0].srcflux,srcstr[1].srcflux]),$
        max([srcstr[0].srcfwhm_max, srcstr[1].srcfwhm_max])+30., 2.*max([srcstr[0].srcflux,srcstr[1].srcflux]),$
        100., 100., 100., 100.]


      for n=0,ntry-1 do begin

        nn = n
        testerror  = RANDOMN(nn+seedstart, nvis)
        vistest    = visobs + testerror * sigamp
        vistest    = transpose(cmreplicate(vistest, n_birds))

        extra = {type: type, $
          visobs: vistest, $
          sigamp: ssigamp, $
          u: vis.u, $
          v: vis.v, $
          n_free: nvis - Nvars, $
          param_opt: param_opt, $
          mapcenter : vis.xyoffset}

        xx_opt = []
        f = fltarr(Nruns)

        for i = 0,Nruns-1 do begin
          optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
            n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
          f[i]    = optim_f.fopt
          xx_opt  = [[xx_opt],optim_f.xopt]
        endfor

        dummy = min(f,location)
        xopt  = xx_opt(location,*)

        d_45_0 = sqrt((xopt[4] + vis[0].xyoffset[0] - srcstr[0].srcx )^2. + (xopt[5] + vis[0].xyoffset[1] - srcstr[0].srcy )^2.)
        d_45_1 = sqrt((xopt[4] + vis[0].xyoffset[0] - srcstr[1].srcx )^2. + (xopt[5] + vis[0].xyoffset[1] - srcstr[1].srcy )^2.)
        d_67_0 = sqrt((xopt[6] + vis[0].xyoffset[0] - srcstr[0].srcx )^2. + (xopt[7] + vis[0].xyoffset[1] - srcstr[0].srcy )^2.)
        d_67_1 = sqrt((xopt[6] + vis[0].xyoffset[0] - srcstr[1].srcx )^2. + (xopt[7] + vis[0].xyoffset[1] - srcstr[1].srcy )^2.)

        dist_min = min([d_45_0, d_45_1, d_67_0, d_67_1], dist_loc)


        ; (4;5) closest to first source or (6;7) closest to second source
        if (dist_loc eq 0) or (dist_loc eq 3) then begin

          trial_results[0, n] = xopt[1]                   ;flux1
          trial_results[1, n] = xopt[0]                   ;FWHM1
          trial_results[2, n] = xopt[3]                   ;flux2
          trial_results[3, n] = xopt[2]                   ;FWHM2

          trial_results[4, n] = xopt[4]                   ;x1
          trial_results[5, n] = xopt[5]                   ;y1

          trial_results[6, n] = xopt[6]                   ;x2
          trial_results[7, n] = xopt[7]                   ;y2

        endif else begin

          trial_results[0, n] = xopt[3]                   ;flux1
          trial_results[1, n] = xopt[2]                   ;FWHM1
          trial_results[2, n] = xopt[1]                   ;flux2
          trial_results[3, n] = xopt[0]                   ;FWHM2

          trial_results[4, n] = xopt[6]                   ;x1
          trial_results[5, n] = xopt[7]                   ;y1

          trial_results[6, n] = xopt[4]                   ;x2
          trial_results[7, n] = xopt[5]                   ;y2

        endelse

      endfor


      fitsigmas[0].srcflux     = stddev(trial_results[0,*])
      fitsigmas[0].srcfwhm_max = stddev(trial_results[1,*])
      fitsigmas[0].srcfwhm_min = stddev(trial_results[1,*])
      fitsigmas[0].srcx        = stddev(trial_results[4,*])
      fitsigmas[0].srcy        = stddev(trial_results[5,*])

      fitsigmas[1].srcflux     = stddev(trial_results[2,*])
      fitsigmas[1].srcfwhm_max = stddev(trial_results[3,*])
      fitsigmas[1].srcfwhm_min = stddev(trial_results[3,*])
      fitsigmas[1].srcx        = stddev(trial_results[6,*])
      fitsigmas[1].srcy        = stddev(trial_results[7,*])


    endif

  endif

  if type eq 'loop' then begin

    n_free = nvis-7.

    if (n_elements(param_opt) ne 7) or (n_elements(lower_bound) ne 7) or (n_elements(upper_bound) ne 7) then begin
      UNDEFINE, lower_bound
      UNDEFINE, upper_bound
      UNDEFINE, param_opt
      message, 'Wrong number of elements of lower bound, upper bound or parameter mask'
    endif

    Nruns = 5
    xx_opt = []
    f = fltarr(Nruns)

    for i = 0,Nruns-1 do begin
      optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
        n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
      f[i]    = optim_f.fopt
      xx_opt  = [[xx_opt],optim_f.xopt]
    endfor

    dummy = min(f,location)
    xopt  = xx_opt(location,*)

    srcstr = {vis_fwdfit_pso_src_structure}
    srcstr.srctype = 'loop'

    fitsigmas = {vis_fwdfit_pso_src_structure}
    fitsigmas.srctype = 'std.dev'

    srcstr.srcflux = xopt[0]

    ecmsr = REFORM(SQRT(xopt[2]^2 + xopt[3]^2))
    eccen = SQRT(1 - EXP(-2*ecmsr))

    srcstr.eccen = eccen

    IF eccen GT 0.001 THEN srcstr.srcpa = reform(ATAN(xopt[3], xopt[2]) * !RADEG)
    IF srcstr.srcpa lt 0. then srcstr.srcpa += 180.

    srcstr.srcfwhm_min = xopt[1] * (1-eccen^2)^0.25
    srcstr.srcfwhm_max = xopt[1] / (1-eccen^2)^0.25

    srcstr.srcx        = xopt[4] + vis[0].xyoffset[0]
    srcstr.srcy        = xopt[5] + vis[0].xyoffset[1]

    srcstr.loop_angle  = xopt[6]

    if keyword_set(uncertainty) then begin

      print, ' '
      print, 'Uncertainty: '
      print, '

      ntry = 20
      trial_results = fltarr(Nvars, ntry)

      for n=0,ntry-1 do begin
        nn=n
        testerror = RANDOMN(nn+seedstart, nvis)          ; nvis element vector normally distributed with sigma = 1
        vistest   = visobs + testerror * sigamp
        vistest   = transpose(cmreplicate(vistest, n_birds))

        extra = {type: type, $
          visobs: vistest, $
          sigamp: ssigamp, $
          u: vis.u, $
          v: vis.v, $
          n_free: nvis - Nvars, $
          param_opt: param_opt, $
          mapcenter : vis.xyoffset}

        xx_opt = []
        f = fltarr(Nruns)

        for i = 0,Nruns-1 do begin
          optim_f = swarmintelligence(obj_fun_name, lower_bound, upper_bound, $
            n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
          f[i]    = optim_f.fopt
          xx_opt  = [[xx_opt],optim_f.xopt]
        endfor

        dummy = min(f,location)
        xopt  = xx_opt(location,*)

        ecmsr = REFORM(SQRT(xopt[2]^2 + xopt[3]^2))
        eccen = SQRT(1 - EXP(-2*ecmsr))

        IF ecmsr GT 0 THEN trial_results[3,n] = reform(ATAN(xopt[3], xopt[2]) * !RADEG) + 180.

        trial_results[0,n]  = xopt[0]
        trial_results[1,n]  = xopt[1] / (1-eccen^2)^0.25
        trial_results[2,n]  = xopt[1] * (1-eccen^2)^0.25
        trial_results[4,n]  = xopt[4]
        trial_results[5,n]  = xopt[5]
        trial_results[6,n]  = xopt[6]

      endfor

      fitsigmas.srcflux        = stddev(trial_results[0, *])
      fitsigmas.srcfwhm_max    = stddev(trial_results[1, *])
      fitsigmas.srcfwhm_min    = stddev(trial_results[2, *])
      avsrcpa                  = ATAN(TOTAL(SIN(trial_results[3, *] * !DTOR)), $
        TOTAL(COS(trial_results[3, *] * !DTOR))) * !RADEG
      groupedpa                = (810 + avsrcpa - trial_results[3, *]) MOD 180.
      fitsigmas.srcpa          = STDDEV(groupedpa)
      fitsigmas.srcx           = stddev(trial_results[4,*])
      fitsigmas.srcy           = stddev(trial_results[5,*])
      fitsigmas.loop_angle     = stddev(trial_results[6,*])
    endif


  endif


  UNDEFINE, lower_bound
  UNDEFINE, upper_bound
  UNDEFINE, param_opt

  fwdfit_pso_im = vis_FWDFIT_PSO_SOURCE2MAP(srcstr, type=type, pixel=pixel, imsize=imsize, xyoffset=vis[0].xyoffset)


  param_out = { srcstr: srcstr, fitsigmas: fitsigmas, data: fwdfit_pso_im}

  return, param_out

end