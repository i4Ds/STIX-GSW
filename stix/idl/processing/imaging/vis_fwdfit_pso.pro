
; NAME:
;   vis_fwdfit_pso
;
; PURPOSE:
;   forward fitting method from visibility based on Particle Swarm Optimization
;
; CALLING SEQUENCE:
;   vis_fwdfit_pso, configuration, vis
;
; CALLS:
;   cmreplicate                    [replicates an array or scalar into a larger array, as REPLICATE does.]
;   vis_fwdfit_func_pso            [to calculate visibilities for a given set of source parameters]
;   vis_fwdfit_pso_func_makealoop  [to calculate loop Fourier trasform]
;   swarmintelligence              [PSO procedure for optimizing the parameters]
;   vis_fwdfit_pso_src_structure   [to create the sources structure]
;   vis_fwdfit_pso_src_nfurcate    [to create a modified source structure based on replication of input source structure]
;   vis_fwdfit_pso_source2map      [to create the map from the optimized parameters]
;
;
; INPUTS:
;   configuration: array containing parametric shapes chosen for the forward fitting method (one for each source component)
;                    - 'circle' : Gaussian circular source
;                    - 'ellipse': Gaussian elliptical source
;                    - 'loop'   : single curved elliptical gaussian
;
;
;   vis         : struct containing  the observed visibility values
;     vis.obsvis: array containing the values of the observed visibilit
;     vis.sigamp: array containing the values of the errors on the observed visibility amplitudes
;     vis.u     : u coordinates of the sampling frequencies
;     vis.v     : v coordinates of the sampling frequencies
;
;     
;   srcin       : struct containing for each source the parameters to optimize and those fixed, upper and lower bound of the variables.
;                 to create the structure srcin:
;                     srcin = VIS_FWDFIT_PSO_MULTIPLE_SRC_CREATE(vis, configuration)
;
;                 If not entered, default values are used (see:
;                                                             - vis_fwdfit_pso_circle_struct_define for the circle
;                                                             - vis_fwdfit_pso_ellipse_struct_define for the ellipse
;                                                             - vis_fwdfit_pso_loop_struct_define for the loop)
;
;               PARAM_OPT  : struct containing the values of the parameters to keep fixed during the optimization.
;                           If an entry of 'param_opt' is set equal to 'fit', then the corresponding variable is optimized.
;                           Otherwise, its value is kept fixed equal to the entry of 'param_opt'
;               LOWER_BOUND: struct containing the lower bound values of the variables to optimize.
;               UPPER_BOUND: struct containing the upper bound values of the variables to optimize.
;
;               For different shapes we have:
;                 - 'circle'  : param_opt, lower_bound, upper_bound = [flux, x location, y location, FWHM]
;                 - 'ellipse' : param_opt = [flux, x location, y location, FWHM max, FWHM min, alpha]
;                               lower_bound, upper_bound = [flux, x location, y location, FWHM, ecc * cos(alpha), ecc * sin(alpha)]
;                                 'ecc' is the eccentricity of the ellipse and 'alpha' is the orientation angle
;                 - 'loop'    : param_opt = [flux, x location, y location, FWHM max, FWHM min, alpha, loop_angle]
;                               lower_bound, upper_bound = [flux, x location, y location, FWHM, ecc * cos(alpha), ecc * sin(alpha), loop_angle]
;
;
; KEYWORDS:
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
;   WARNING_CONF: warning if the uncertainty can not be computed for the chosen confuguration
;
;
;   SRCSTR: structure containing the values of the fitted parameters.
;   FITSIGMAS: structure containing the values of the uncertainty on the fitted parameters.
;   REDCHISQ: returns reduced chi^2
;
; OUTPUTS:
;   fit parameters and uncertaintly
;   reduced chi^2 (redchisq)
;   image map
;
;
; HISTORY: April 2022, Volpara A. created
;
; CONTACT:
;   volpara [at] dima.unige.it


function vis_fwdfit_pso, configuration, vis, srcin, $
                          n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, $
                          uncertainty = uncertainty, $
                          imsize=imsize, pixel=pixel, $
                          silent = silent, $
                          seedstart = seedstart, warning_conf=warning_conf


  default, n_birds, 100.
  default, tolerance, 1e-06
  default, silent, 0
  default, imsize, [128,128]
  default, pixel, [1.,1.]
  default, seedstart, fix(randomu(seed) * 100)
  default, warning_conf, 0

  loc_circle  = where(configuration eq 'circle', n_circle)>0
  loc_ellipse = where(configuration eq 'ellipse', n_ellipse)>0
  loc_loop    = where(configuration eq 'loop', n_loop)>0

  Nvars = n_elements(param_opt)

  obj_fun_name = 'vis_fwdfit_func_pso'
  Nvars        = 4.*n_circle+6.*n_ellipse+8.*n_loop
  visobs       = [real_part(vis.obsvis), imaginary(vis.obsvis)]
  nvis         = N_ELEMENTS(visobs)
  vvisobs      = transpose(cmreplicate(visobs, n_birds))
  sigamp       = [vis.sigamp,vis.sigamp]
  ssigamp      = transpose(cmreplicate(sigamp, n_birds))
  
  param_opt=[]
  lower_bound=[]
  upper_bound=[]
  
  if n_circle gt 0 then begin

    for j=0, n_circle-1 do begin

      param_opt=[param_opt, string(srcin.circle[j].param_opt.param_flux), $
                  string(srcin.circle[j].param_opt.param_x), $
                  string(srcin.circle[j].param_opt.param_y), $
                  string(srcin.circle[j].param_opt.param_fwhm)]

      lower_bound = [lower_bound, srcin.circle[j].lower_bound.l_b_flux, $
                      srcin.circle[j].lower_bound.l_b_x, $
                      srcin.circle[j].lower_bound.l_b_y, $
                      srcin.circle[j].lower_bound.l_b_fwhm]

      upper_bound = [upper_bound, srcin.circle[j].upper_bound.u_b_flux, $
                      srcin.circle[j].upper_bound.u_b_x, $
                      srcin.circle[j].upper_bound.u_b_y, $
                      srcin.circle[j].upper_bound.u_b_fwhm]

    endfor
  endif

  if n_ellipse gt 0 then begin
    for j=0, n_ellipse-1 do begin

      param_opt   = [param_opt, string(srcin.ellipse[j].param_opt.param_flux), $
                      string(srcin.ellipse[j].param_opt.param_x), $
                      string(srcin.ellipse[j].param_opt.param_y), $
                      string(srcin.ellipse[j].param_opt.param_fwhm_max), $
                      string(srcin.ellipse[j].param_opt.param_fwhm_min), $
                      string(srcin.ellipse[j].param_opt.param_alpha)]

      lower_bound = [lower_bound, srcin.ellipse[j].lower_bound.l_b_flux, $
                      srcin.ellipse[j].lower_bound.l_b_x, $
                      srcin.ellipse[j].lower_bound.l_b_y, $
                      srcin.ellipse[j].lower_bound.l_b_fwhm, $
                      srcin.ellipse[j].lower_bound.l_b_eccos, $
                      srcin.ellipse[j].lower_bound.l_b_ecsin]

      upper_bound = [upper_bound, srcin.ellipse[j].upper_bound.u_b_flux, $
                      srcin.ellipse[j].upper_bound.u_b_x, $
                      srcin.ellipse[j].upper_bound.u_b_y, $
                      srcin.ellipse[j].upper_bound.u_b_fwhm, $
                      srcin.ellipse[j].upper_bound.u_b_eccos, $
                      srcin.ellipse[j].upper_bound.u_b_ecsin]

    endfor
  endif

  if n_loop gt 0 then begin
    for j=0, n_loop-1 do begin

      param_opt   = [param_opt, string(srcin.loop[j].param_opt.param_flux), $
                      string(srcin.loop[j].param_opt.param_x), $
                      string(srcin.loop[j].param_opt.param_y), $
                      string(srcin.loop[j].param_opt.param_fwhm_max), $
                      string(srcin.loop[j].param_opt.param_fwhm_min), $
                      string(srcin.loop[j].param_opt.param_alpha), $
                      string(srcin.loop[j].param_opt.param_loopangle)]

      lower_bound = [lower_bound, srcin.loop[j].lower_bound.l_b_flux, $
                      srcin.loop[j].lower_bound.l_b_x, $
                      srcin.loop[j].lower_bound.l_b_y, $
                      srcin.loop[j].lower_bound.l_b_fwhm, $
                      srcin.loop[j].lower_bound.l_b_eccos, $
                      srcin.loop[j].lower_bound.l_b_ecsin, $
                      srcin.loop[j].lower_bound.l_b_loopangle]

      upper_bound = [upper_bound, srcin.loop[j].upper_bound.u_b_flux, $
                      srcin.loop[j].upper_bound.u_b_x, $
                      srcin.loop[j].upper_bound.u_b_y, $
                      srcin.loop[j].upper_bound.u_b_fwhm, $
                      srcin.loop[j].upper_bound.u_b_eccos, $
                      srcin.loop[j].upper_bound.u_b_ecsin, $
                      srcin.loop[j].upper_bound.u_b_loopangle]

    endfor
  endif

  n_sources = n_elements(configuration)
  
  extra = {visobs: vvisobs, $
    sigamp: ssigamp, $
    u: vis.u, $
    v: vis.v, $
    n_free: nvis - Nvars, $    ;n_free: degrees of freedom (difference between the number of visibility amplitudes
                               ;and the number of parameters of the source shape)
    param_opt: param_opt, $
    mapcenter : vis.xyoffset, $
    configuration: configuration }

  if n_elements(configuration) eq 1 then begin
    if configuration[0] eq 'loop' then begin
      Nruns = 5.
    endif else begin
      Nruns = 1.
    endelse
  endif

  if n_elements(configuration) ge 2 then Nruns = 20.

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

  redchisq  = dummy

  srcstr = {vis_fwdfit_pso_src_structure}
  srcstr.srctype ='circle'
  srcstr = VIS_FWDFIT_PSO_SRC_NFURCATE(srcstr, n_sources)

  fitsigmas = {vis_fwdfit_pso_src_structure}
  fitsigmas.srctype ='std.dev'
  fitsigmas = VIS_FWDFIT_PSO_SRC_NFURCATE(fitsigmas, n_sources)

  ;************************************************************ circle
  if n_circle gt 0 then begin
    for i=0, n_circle-1 do begin
      srcstr[i].srctype = 'circle'
      srcstr[i].srcflux = xopt[4*i]
      srcstr[i].srcx    = xopt[4*i+1] + vis[0].xyoffset[0]
      srcstr[i].srcy    = xopt[4*i+2] + vis[0].xyoffset[1]
      srcstr[i].srcfwhm_max = xopt[4*i+3]
      srcstr[i].srcfwhm_min = xopt[4*i+3]
    endfor
  endif

  ;************************************************************ ellipse
  if n_ellipse gt 0 then begin
    for i=0, n_ellipse-1 do begin
      srcstr[n_circle+i].srctype = 'ellipse'

      ecmsr = REFORM(SQRT(xopt[n_circle*4+6*i+4]^2 + xopt[n_circle*4+6*i+5]^2))
      eccen = SQRT(1 - EXP(-2*ecmsr))

      srcstr[n_circle+i].eccen   = eccen
      srcstr[n_circle+i].srcflux = xopt[n_circle*4+6*i]
      srcstr[n_circle+i].srcx    = xopt[n_circle*4+6*i+1] + vis[0].xyoffset[0]
      srcstr[n_circle+i].srcy    = xopt[n_circle*4+6*i+2] + vis[0].xyoffset[1]
      srcstr[n_circle+i].srcfwhm_max = xopt[n_circle*4+6*i+3] / (1-eccen^2)^0.25
      srcstr[n_circle+i].srcfwhm_min = xopt[n_circle*4+6*i+3] * (1-eccen^2)^0.25
      srcstr[n_circle+i].eccen   = eccen

      IF ecmsr GT 0 THEN srcstr[n_circle+i].srcpa = reform(ATAN(xopt[n_circle*4+6*i+5], xopt[n_circle*4+6*i+4]) * !RADEG)
      IF srcstr[n_circle+i].srcpa lt 0. then srcstr[n_circle+i].srcpa += 180.
    endfor
  endif

  ;************************************************************ loop
  if n_loop gt 0 then begin
    for i=0, n_loop-1 do begin
      srcstr[n_circle+n_ellipse+i].srctype = 'loop'

      ecmsr = REFORM(SQRT(xopt[n_circle*4+6*n_ellipse+7*i*4+4]^2 + xopt[n_circle*4+6*n_ellipse+7*i*4+5]^2))
      eccen = SQRT(1 - EXP(-2*ecmsr))

      srcstr[n_circle+n_ellipse+i].eccen   = eccen
      srcstr[n_circle+n_ellipse+i].srcflux = xopt[n_circle*4+6*n_ellipse+7*i]
      srcstr[n_circle+n_ellipse+i].srcx    = xopt[n_circle*4+6*n_ellipse+7*i+1] + vis[0].xyoffset[0]
      srcstr[n_circle+n_ellipse+i].srcy    = xopt[n_circle*4+6*n_ellipse+7*i+2] + vis[0].xyoffset[1]
      srcstr[n_circle+n_ellipse+i].srcfwhm_max = xopt[n_circle*4+6*n_ellipse+7*i+3] / (1-eccen^2)^0.25
      srcstr[n_circle+n_ellipse+i].srcfwhm_min = xopt[n_circle*4+6*n_ellipse+7*i+3] * (1-eccen^2)^0.25
      srcstr[n_circle+n_ellipse+i].eccen   = eccen

      IF ecmsr GT 0 THEN srcstr[n_circle+n_ellipse+i].srcpa = reform(ATAN(xopt[n_circle*4+6*n_ellipse+7*i+5], xopt[n_circle*4+6*n_ellipse+7*i+4]) * !RADEG)
      IF srcstr[n_circle+n_ellipse+i].srcpa lt 0. then srcstr[n_circle+n_ellipse+i].srcpa += 180.

      srcstr[n_circle+n_ellipse+i].loop_angle  = xopt[n_circle*4+6*n_ellipse+7*i+6]
    endfor
  endif


  if keyword_set(uncertainty) then begin

    print, ' '
    print, 'Uncertainty: '
    print, '

    ntry = 20
    trial_results = fltarr(Nvars, ntry)

    ;  Nruns = 20.
    check = 1
    vect_check = fltarr(ntry)

    ; lower bound, upper_bound
    if n_elements(configuration) eq 1 then begin
      if configuration[0] eq 'loop' then begin
        Nruns = 3.
      endif else begin
        Nruns = 1.
      endelse
    endif else begin
      Nruns = 10.
    endelse
    lower_bound_unc = []
    upper_bound_unc = []

    if n_circle gt 0. then begin
      lower_bound_c_unc = [0.7*min(srcstr.srcflux), -100., -100., min(srcstr.srcfwhm_min)-30.>0.]
      upper_bound_c_unc = [2.0*max(srcstr.srcflux), 100., 100., max(srcstr.srcfwhm_max)+30.]

      lower_bound_c_unc = cmreplicate(lower_bound_c_unc, n_circle)
      upper_bound_c_unc = cmreplicate(upper_bound_c_unc, n_circle)

      lower_bound_c_unc = reform(lower_bound_c_unc, [4. *n_circle, 1])
      upper_bound_c_unc = reform(upper_bound_c_unc, [4. *n_circle, 1])

      lower_bound_unc = [lower_bound_unc, [lower_bound_c_unc]]
      upper_bound_unc = [upper_bound_unc, [upper_bound_c_unc]]

    endif

    if n_ellipse gt 0. then begin

      fwhm_e = srcstr.srcfwhm_max * (1 - srcstr.eccen^2.)^0.25

      lower_bound_e_unc = [0.7*min(srcstr.srcflux), -100., -100., min(fwhm_e)-30.>0., -5., 0.]
      upper_bound_e_unc = [2.0*max(srcstr.srcflux), 100., 100., max(fwhm_e)+30., 5., 1. ]

      lower_bound_e_unc = cmreplicate(lower_bound_e_unc, n_ellipse)
      upper_bound_e_unc = cmreplicate(upper_bound_e_unc, n_ellipse)

      lower_bound_e_unc = reform(lower_bound_e_unc, [6. *n_ellipse, 1])
      upper_bound_e_unc = reform(upper_bound_e_unc, [6. *n_ellipse, 1])

      lower_bound_unc = [lower_bound_unc, [lower_bound_e_unc]]
      upper_bound_unc = [upper_bound_unc, [upper_bound_e_unc]]

    endif

    if n_loop gt 0. then begin

      fwhm_l = srcstr.srcfwhm_max * (1 - srcstr.eccen^2.)^0.25

      lower_bound_l_unc = [0.7*min(srcstr.srcflux), -100., -100., min(fwhm_l)-30.>0., -5., 0.,-180.]
      upper_bound_l_unc = [2.0*max(srcstr.srcflux), 100., 100., max(fwhm_l)+30., 5., 1. ,180.]

      lower_bound_l_unc = cmreplicate(lower_bound_l_unc, n_loop)
      upper_bound_l_unc = cmreplicate(upper_bound_l_unc, n_loop)

      lower_bound_l_unc = reform(lower_bound_l_unc, [7. *n_loop, 1])
      upper_bound_l_unc = reform(upper_bound_l_unc, [7. *n_loop, 1])

      lower_bound_unc = [lower_bound, [lower_bound_l_unc]]
      upper_bound_unc = [upper_bound, [upper_bound_l_unc]]

    endif


    for n=0,ntry-1 do begin

      nn = n
      testerror  = RANDOMN(nn+seedstart, nvis)
      vistest    = visobs + testerror * sigamp
      vistest    = transpose(cmreplicate(vistest, n_birds))

      extra = {visobs: vistest, $
        sigamp: ssigamp, $
        u: vis.u, $
        v: vis.v, $
        n_free: nvis - Nvars, $    ;n_free: degrees of freedom (difference between the number of visibility amplitudes
                                   ;and the number of parameters of the source shape)
        param_opt: param_opt, $
        mapcenter : vis.xyoffset, $
        configuration: configuration }

      xx_opt = []
      f = fltarr(Nruns)

      for i = 0,Nruns-1 do begin
        optim_f = swarmintelligence(obj_fun_name, lower_bound_unc, upper_bound_unc, $
          n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent )
        f[i]    = optim_f.fopt
        xx_opt  = [[xx_opt],optim_f.xopt]
      endfor

      dummy = min(f,location)
      xopt  = xx_opt(location,*)

      ;************************************************************ circle
      if n_circle gt 0 then begin
        matrix_dist_circle  = fltarr(n_circle, n_circle)
        for i=0,n_circle-1 do begin
          for j=0,n_circle-1 do begin
            d_i_j = sqrt((xopt[4*i+1] + vis[0].xyoffset[0] - srcstr[j].srcx )^2. + (xopt[4*i+2] + vis[0].xyoffset[1] - srcstr[j].srcy )^2.)
            matrix_dist_circle[j,i] = d_i_j
          endfor
        endfor

        loc_dist_min0 = where( matrix_dist_circle eq min(matrix_dist_circle))
        coord_min = array_indices(matrix_dist_circle eq min(matrix_dist_circle), loc_dist_min0[0])

        trial_results[4*coord_min[0], n]   = xopt[4*coord_min[-1]]
        trial_results[4*coord_min[0]+1, n] = xopt[4*coord_min[-1]+1] + vis[0].xyoffset[0]
        trial_results[4*coord_min[0]+2, n] = xopt[4*coord_min[-1]+2] + vis[0].xyoffset[1]
        trial_results[4*coord_min[0]+3, n] = xopt[4*coord_min[-1]+3]

        matrix_dist_circle_norows = matrix_dist_circle
        coord_min_short=coord_min

        if n_circle gt 1 then begin
          for k=0, n_circle-2 do begin
            dims = Size(matrix_dist_circle_norows, /Dimensions)
            matrix_dist_circle_nocolums = matrix_dist_circle_norows[Where(~Histogram([coord_min_short[0]], MIN=0, MAX=dims[0]-1), /NULL),*]
            matrix_dist_circle_norows = matrix_dist_circle_nocolums[*,Where(~Histogram([coord_min_short[1]], MIN=0, MAX=dims[1]-1), /NULL)]

            loc_dist_min = where( matrix_dist_circle eq min(matrix_dist_circle_norows))
            loc_dist_min_short = where( matrix_dist_circle_norows eq min(matrix_dist_circle_norows))
            if n_elements(loc_dist_min0) eq n_circle then begin
              coord_min = array_indices(matrix_dist_circle eq min(matrix_dist_circle_norows), loc_dist_min[k+1])
              coord_min_short = array_indices(matrix_dist_circle_norows eq min(matrix_dist_circle_norows), loc_dist_min_short[0])
            endif else begin
              coord_min = array_indices(matrix_dist_circle eq min(matrix_dist_circle_norows), loc_dist_min)
              coord_min_short = array_indices(matrix_dist_circle_norows eq min(matrix_dist_circle_norows), loc_dist_min_short)
            endelse

            trial_results[4*coord_min[0], n]   = xopt[4*coord_min[1]]
            trial_results[4*coord_min[0]+1, n] = xopt[4*coord_min[1]+1] + vis[0].xyoffset[0]
            trial_results[4*coord_min[0]+2, n] = xopt[4*coord_min[1]+2] + vis[0].xyoffset[1]
            trial_results[4*coord_min[0]+3, n] = xopt[4*coord_min[1]+3]
          endfor
        endif
      endif


      ;************************************************************ ellipse
      if n_ellipse gt 0 then begin

        matrix_dist_ellipse  = fltarr(n_ellipse, n_ellipse)
        for i=0,n_ellipse-1 do begin
          for j=0,n_ellipse-1 do begin
            d_i_j = sqrt((xopt[n_circle*4+6*i+1] + vis[0].xyoffset[0] - srcstr[n_circle+j].srcx )^2. + (xopt[n_circle*4+6*i+2] + vis[0].xyoffset[1] - srcstr[n_circle+j].srcy )^2.)
            matrix_dist_ellipse[j,i] = d_i_j
          endfor
        endfor

        loc_dist_min0 = where(matrix_dist_ellipse eq min(matrix_dist_ellipse))
        coord_min = array_indices(matrix_dist_ellipse eq min(matrix_dist_ellipse), loc_dist_min0[0])

        ecmsr = REFORM(SQRT(xopt[n_circle*4+6*coord_min[0]+4]^2 + xopt[n_circle*4+6*coord_min[-1]+5]^2))
        eccen = SQRT(1 - EXP(-2*ecmsr))

        trial_results[4*n_circle+6*coord_min[0], n]   = xopt[n_circle*4+6*coord_min[-1]]
        trial_results[4*n_circle+6*coord_min[0]+1, n] = xopt[n_circle*4+6*coord_min[-1]+1] + vis[0].xyoffset[0]
        trial_results[4*n_circle+6*coord_min[0]+2, n] = xopt[n_circle*4+6*coord_min[-1]+2] + vis[0].xyoffset[1]
        trial_results[4*n_circle+6*coord_min[0]+3, n] = xopt[n_circle*4+6*coord_min[-1]+3] / (1-eccen^2)^0.25
        trial_results[4*n_circle+6*coord_min[0]+4, n] = xopt[n_circle*4+6*coord_min[-1]+3] * (1-eccen^2)^0.25

        IF ecmsr GT 0 THEN trial_results[4*n_circle+6*coord_min[0]+5, n] = reform(ATAN(xopt[n_circle*4+6*coord_min[-1]+5], xopt[n_circle*4+6*coord_min[-1]+4]) * !RADEG)
        IF trial_results[4*n_circle+6*coord_min[0]+5, n] lt 0. then trial_results[4*n_circle+6*coord_min[0]+5, n] += 180.

        matrix_dist_ellipse_norows = matrix_dist_ellipse
        coord_min_short=coord_min

        if n_ellipse gt 1 then begin
          for k=0, n_ellipse-2 do begin
            dims = Size(matrix_dist_ellipse_norows, /Dimensions)
            matrix_dist_ellipse_nocolums = matrix_dist_ellipse_norows[Where(~Histogram([coord_min_short[0]], MIN=0, MAX=dims[0]-1), /NULL),*]
            matrix_dist_ellipse_norows = matrix_dist_ellipse_nocolums[*,Where(~Histogram([coord_min_short[1]], MIN=0, MAX=dims[1]-1), /NULL)]

            loc_dist_min = where( matrix_dist_ellipse eq min(matrix_dist_ellipse_norows))
            loc_dist_min_short = where( matrix_dist_ellipse_norows eq min(matrix_dist_ellipse_norows))
            if n_elements(loc_dist_min0) eq n_ellipse then begin
              coord_min = array_indices(matrix_dist_ellipse eq min(matrix_dist_ellipse_norows), loc_dist_min[k+1])
              coord_min_short = array_indices(matrix_dist_ellipse_norows eq min(matrix_dist_ellipse_norows), loc_dist_min_short[0])
            endif else begin
              coord_min = array_indices(matrix_dist_ellipse eq min(matrix_dist_ellipse_norows), loc_dist_min)
              coord_min_short = array_indices(matrix_dist_ellipse_norows eq min(matrix_dist_ellipse_norows), loc_dist_min_short)
            endelse

            ecmsr = REFORM(SQRT(xopt[n_circle*4+6*coord_min[0]+4]^2 + xopt[n_circle*4+6*coord_min[1]+5]^2))
            eccen = SQRT(1 - EXP(-2*ecmsr))

            trial_results[4*n_circle+6*coord_min[0], n]   = xopt[n_circle*4+6*coord_min[1]]
            trial_results[4*n_circle+6*coord_min[0]+1, n] = xopt[n_circle*4+6*coord_min[1]+1] + vis[0].xyoffset[0]
            trial_results[4*n_circle+6*coord_min[0]+2, n] = xopt[n_circle*4+6*coord_min[1]+2] + vis[0].xyoffset[1]
            trial_results[4*n_circle+6*coord_min[0]+3, n] = xopt[n_circle*4+6*coord_min[1]+3] / (1-eccen^2)^0.25
            trial_results[4*n_circle+6*coord_min[0]+4, n] = xopt[n_circle*4+6*coord_min[1]+3] * (1-eccen^2)^0.25

            IF ecmsr GT 0 THEN trial_results[4*n_circle+6*coord_min[0]+5, n] = reform(ATAN(xopt[n_circle*4+6*coord_min[1]+5], xopt[n_circle*4+6*coord_min[1]+4]) * !RADEG)
            IF trial_results[4*n_circle+6*coord_min[0]+5, n] lt 0. then trial_results[4*n_circle+6*coord_min[0]+5, n] += 180.

          endfor
        endif
      endif


      ;************************************************************ loop
      if n_loop gt 0 then begin

        matrix_dist_loop  = fltarr(n_loop, n_loop)
        for i=0,n_loop-1 do begin
          for j=0,n_loop-1 do begin
            d_i_j = sqrt((xopt[n_circle*4+6*n_ellipse+7*i+1] + vis[0].xyoffset[0] - srcstr[n_circle+n_ellipse+j].srcx )^2. + (xopt[n_circle*4+6*n_ellipse+7*i+2] + vis[0].xyoffset[1] - srcstr[n_circle+n_ellipse+j].srcy )^2.)
            matrix_dist_loop[j,i] = d_i_j
          endfor
        endfor

        loc_dist_min0 = where( matrix_dist_loop eq min(matrix_dist_loop))
        coord_min = array_indices(matrix_dist_loop eq min(matrix_dist_loop), loc_dist_min0[0])

        ecmsr = REFORM(SQRT(xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]*4+4]^2 + xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]*4+5]^2))
        eccen = SQRT(1 - EXP(-2*ecmsr))

        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0], n]   = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]]
        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+1, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+1] + vis[0].xyoffset[0]
        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+2, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+2] + vis[0].xyoffset[1]
        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+3, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+3] / (1-eccen^2)^0.25
        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+4, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+3] * (1-eccen^2)^0.25

        IF ecmsr GT 0 THEN trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] = reform(ATAN(xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+5], xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+4]) * !RADEG)
        IF trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] lt 0. then trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] += 180.

        trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+6, n]  = xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+6]

        ;Moebius strip
        if xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+6] lt 0 then begin
          trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+6, n] = - xopt[n_circle*4+6*n_ellipse+7*coord_min[-1]+6]
          trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] +=180.
        endif

        matrix_dist_loop_norows = matrix_dist_loop
        coord_min_short = coord_min

        if n_loop gt 1 then begin
          for k=0, n_loop-2 do begin
            dims = Size(matrix_dist_loop_norows, /Dimensions)
            matrix_dist_loop_nocolums = matrix_dist_loop_norows[Where(~Histogram([coord_min_short[0]], MIN=0, MAX=dims[0]-1), /NULL),*]
            matrix_dist_loop_norows = matrix_dist_loop_nocolums[*,Where(~Histogram([coord_min_short[1]], MIN=0, MAX=dims[1]-1), /NULL)]

            loc_dist_min = where( matrix_dist_loop eq min(matrix_dist_loop_norows))
            loc_dist_min_short = where( matrix_dist_loop_norows eq min(matrix_dist_loop_norows))
            if n_elements(loc_dist_min0) eq n_loop then begin
              coord_min = array_indices(matrix_dist_loop eq min(matrix_dist_loop_norows), loc_dist_min[k+1])
              coord_min_short = array_indices(matrix_dist_loop_norows eq min(matrix_dist_loop_norows), loc_dist_min_short[0])
            endif else begin
              coord_min = array_indices(matrix_dist_loop eq min(matrix_dist_loop_norows), loc_dist_min)
              coord_min_short = array_indices(matrix_dist_loop_norows eq min(matrix_dist_loop_norows), loc_dist_min_short)
            endelse

            ecmsr = REFORM(SQRT(xopt[n_circle*4+6*n_ellipse+7*coord_min[1]*4+4]^2 + xopt[n_circle*4+6*n_ellipse+7*coord_min[1]*4+5]^2))
            eccen = SQRT(1 - EXP(-2*ecmsr))

            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0], n]   = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]]
            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+1, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+1] + vis[0].xyoffset[0]
            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+2, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+2] + vis[0].xyoffset[1]
            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+3, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+3] / (1-eccen^2)^0.25
            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+4, n] = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+3] * (1-eccen^2)^0.25

            IF ecmsr GT 0 THEN trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] = reform(ATAN(xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+5], xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+4]) * !RADEG)
            IF trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] lt 0. then trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] += 180.

            trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+6, n]  = xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+6]

            ;Moebius strip
            if xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+6] lt 0 then begin
              trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+6, n] = - xopt[n_circle*4+6*n_ellipse+7*coord_min[1]+6]
              trial_results[4*n_circle+6*n_ellipse+7*coord_min[0]+5, n] +=180.
            endif

          endfor
        endif
      endif


      ;************************************************************ stability check
      if (((n_ellipse gt 0) or (n_loop gt 0)) and (n_circle gt 0)) then begin

        dist__circle = fltarr(n_circle, n_sources - n_circle)
        for i = n_circle, n_sources-1 do begin
          for j = 0, n_circle-1 do begin
            d_ij = sqrt((trial_results[4*j+1,n] - srcstr[i].srcx )^2. + (trial_results[4*j+2,n]  - srcstr[i].srcy )^2.)
            dist__circle[j,i-n_circle] = d_ij
          endfor
        endfor
        if  min(dist__circle) lt min(matrix_dist_circle) then begin
          check +=1
          vect_check[n] += 1
        endif

      endif

      if (((n_circle gt 0) or (n_loop gt 0)) and (n_ellipse gt 0)) then begin

        dist__ellipse = fltarr(n_ellipse, n_sources - n_ellipse)
        for j = 0, n_ellipse-1 do begin
          for i = 0, n_circle-1 do begin
            d_ij = sqrt((trial_results[4*n_circle+6*j+1,n] - srcstr[i].srcx )^2. + (trial_results[4*n_circle+6*j+2,n] - srcstr[i].srcy )^2.)
            dist__ellipse[j,i] = d_ij
          endfor
          if (n_loop gt 0) then begin
            for i = n_circle + n_ellipse, n_sources - 1 do begin
              d_ij = sqrt((trial_results[4*n_circle+6*j+1,n]  - srcstr[i].srcx )^2. + (trial_results[4*n_circle+6*j+2,n] - srcstr[i].srcy )^2.)
              dist__ellipse[j,i-n_ellipse] = d_ij
            endfor
          endif
        endfor
        if  min(dist__ellipse) lt min(matrix_dist_ellipse) then begin
          check +=1
          vect_check[n] += 1
        endif
        
      endif

      if (((n_circle gt 0) or (n_ellipse gt 0)) and (n_loop gt 0)) then begin

        dist__loop = fltarr(n_loop, n_souces - n_loop)
        for i=0, n_circle+n_ellipse-1 do begin
          for j=0, n_loop-1 do begin
            d_ij = sqrt((trial_results[4*n_circle+6*n_ellipse+7*j+1,n] - srcstr[i].srcx )^2. + (trial_results[4*n_circle+6*n_ellipse+7*j+2,n] - srcstr[i].srcy )^2.)
            dist__loop[j,i] = d_ij
          endfor
        endfor
        if  min(dist__loop) lt min(matrix_dist_loop) then begin
          check +=1
          vect_check[n] += 1
        endif

      endif


    endfor

    swap_elements = where(vect_check ge 2., n_swap)
    if n_swap le 2 then begin
      if n_swap gt 0 then begin
        dims = size(trial_results, /dimensions)
        trial_results = trial_results[*,where(~Histogram(swap_elements, min=0, max=dims[1]-1), /null)]
      endif
      if n_circle gt 0 then begin
        for i=0, n_circle-1 do begin
          fitsigmas[i].srcflux = stddev(trial_results[4*i,*])
          fitsigmas[i].srcx    = stddev(trial_results[4*i+1,*])
          fitsigmas[i].srcy    = stddev(trial_results[4*i+2,*])
          fitsigmas[i].srcfwhm_max = stddev(trial_results[4*i+3,*])
          fitsigmas[i].srcfwhm_min = stddev(trial_results[4*i+3,*])
        endfor
      endif


      if n_ellipse gt 0 then begin
        for i=0, n_ellipse-1 do begin
          fitsigmas[n_circle+i].srcflux        = stddev(trial_results[n_circle*4+6*i, *])
          fitsigmas[n_circle+i].srcfwhm_max    = stddev(trial_results[n_circle*4+6*i+3, *])
          fitsigmas[n_circle+i].srcfwhm_min    = stddev(trial_results[n_circle*4+6*i+4, *])
          avsrcpa                  = ATAN(TOTAL(SIN(trial_results[4*n_circle+6*i+5, *] * !DTOR)), $
                                          TOTAL(COS(trial_results[4*n_circle+6*i+5, *] * !DTOR))) * !RADEG
          groupedpa                = (810 + avsrcpa - trial_results[4*n_circle+6*i+5, *]) MOD 180.
          fitsigmas[n_circle+i].srcpa          = STDDEV(groupedpa)
          fitsigmas[n_circle+i].srcx           = stddev(trial_results[4*n_circle+6*i+1,*])
          fitsigmas[n_circle+i].srcy           = stddev(trial_results[4*n_circle+6*i+2,*])
        endfor
      endif


      if n_loop gt 0 then begin
        for i=0, n_loop-1 do begin
          fitsigmas[n_circle+n_ellipse+i].srcflux        = stddev(trial_results[n_circle*4+6*n_ellipse+7*i, *])
          fitsigmas[n_circle+n_ellipse+i].srcfwhm_max    = stddev(trial_results[n_circle*4+6*n_ellipse+7*i+3, *])
          fitsigmas[n_circle+n_ellipse+i].srcfwhm_min    = stddev(trial_results[n_circle*4+6*n_ellipse+7*i+4, *])
          avsrcpa                  = ATAN(TOTAL(SIN(trial_results[4*n_circle+6*n_ellipse+7*i+5, *] * !DTOR)), $
                                          TOTAL(COS(trial_results[4*n_circle+6*n_ellipse+7*i+5, *] * !DTOR))) * !RADEG
          groupedpa                = (810 + avsrcpa - trial_results[4*n_circle+6*n_ellipse+7*i+5, *]) MOD 180.
          fitsigmas[n_circle+n_ellipse+i].srcpa          = STDDEV(groupedpa)
          fitsigmas[n_circle+n_ellipse+i].srcx           = stddev(trial_results[4*n_circle+6*n_ellipse+7*i+1,*])
          fitsigmas[n_circle+n_ellipse+i].srcy           = stddev(trial_results[4*n_circle+6*n_ellipse+7*i+2,*])
          fitsigmas[n_circle+n_ellipse+i].loop_angle     = stddev(trial_results[4*n_circle+6*n_ellipse+7*i+6,*])
        endfor
      endif

    endif else begin
      warning_conf=1

      for kk = 0, n_elements(configuration)-1 do begin
        fitsigmas[kk].srcflux     = !values.f_nan
        fitsigmas[kk].srcfwhm_max = !values.f_nan
        fitsigmas[kk].srcfwhm_min = !values.f_nan
        fitsigmas[kk].srcpa       = !values.f_nan
        fitsigmas[kk].srcx        = !values.f_nan
        fitsigmas[kk].srcy        = !values.f_nan
        fitsigmas[kk].loop_angle  = !values.f_nan

      endfor
   endelse

endif

  fwdfit_pso_im = vis_FWDFIT_PSO_SOURCE2MAP(srcstr, configuration, pixel=pixel, imsize=imsize, xyoffset=vis[0].xyoffset)

  param_out = { srcstr: srcstr, fitsigmas: fitsigmas, data: fwdfit_pso_im, redchisq: redchisq}

  return, param_out
end