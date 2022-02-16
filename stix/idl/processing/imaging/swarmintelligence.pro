;+
; NAME:
;   swarmintelligence
;
; PURPOSE:
;   Particle Swarm Optimization for constrained optimization
;
; CALLING SEQUENCE:
;   swarmintelligence(obj_fun_name, lower_bound_row, upper_bound_row)
;
; DESCRIPTION:
;     The SWARMINTELLIGENCE function initializes a swarm of points, called birds, and updates positions and velocities of the birds 
;     according to the best location, i.e. the minimum of the objective function. 
;     For reference see: 
;     Kennedy and Eberhart, Particle Swarm Optimization, 1995
;     Mezura-Montes and Coello Coello, Constraint-handling in nature-inspired numerical optimization: Past, present and future, 2011.
;
;
; INPUTS:
;   obj_fun_name     : objective function
;   lower_bound_row  : array containing the lower bound values of the variables to optimize
;   upper_bound_row  : array containing the upper bound values of the variables to optimize
;
; KEYWORDS:
;   n_birds   : number of birds used in PSO (default is 100)
;   tolerance : tolerance for the stopping criterion (default is 1e-6)
;   maxiter   : maximum number of iterations (defult is the product between of the numbers of parameters and the number of particles)
;   extra     : for setting parameters of the objective function
;   silent    : set to 1 for avoiding the print of the retrieved parameters
;
; OUTPUT:
;   The optimized parameters and the minimum value of the objective function.
;
; HISTORY: March 2021, Perracchione E., created

function swarmintelligence, obj_fun_name, lower_bound_row, upper_bound_row, $
                            n_birds = n_birds, tolerance = tolerance, maxiter = maxiter, extra = extra, silent = silent 
             
  default, n_birds, 100.                  
  default, tolerance, 1e-6       
  default, silent, 0
  
  n_variable = n_elements(lower_bound_row)
  
  default, maxiter, float(n_variable) * float(n_birds)
  
  if n_elements(lower_bound_row) ne n_elements(upper_bound_row) then message, "Lower and upper bounds must have the same dimension."
  
  lower_bound = transpose(cmreplicate(lower_bound_row, n_birds))
  upper_bound = transpose(cmreplicate(upper_bound_row, n_birds))
  
  ; create birds position and velocities and evaluate objective funtion
  birds_pos = lower_bound + randomu(seed,[n_birds,n_variable]) * (upper_bound-lower_bound)
  ones = fltarr(n_birds,1)
  birds_vel_aux = ones # reform(min([[upper_bound_row-lower_bound_row],[transpose([n_birds*(fltarr(1,n_variable)+1)])]], dimension=2), [1,n_variable])
  birds_vel_aux1 = 2. * birds_vel_aux * randomu(seed,[n_variable,n_birds])
  birds_vel = -birds_vel_aux + birds_vel_aux1
  
  obj_fun_eval = call_function(obj_fun_name, birds_pos, extra = extra)

  birds_best_fun_eval = obj_fun_eval
  birds_best_pos      = birds_pos

  ; identify lowest function value
  birds_global_best_fun_eval = min(obj_fun_eval)
  
  birds_best_fun_eval_iter   = (fltarr(20,1)+1)*!values.f_nan
  
  inertia_min = 0.1
  inertia_max = 1.1
  intertia_adapt_count = 0.
  inertia_adapt = inertia_max
  
  n_close_birds = max([2.,floor(n_birds/4.)])
  n_close_birds_adapt = n_close_birds
  
  self_behav_const   = 1.49
  social_behav_const = 1.49
  n_iteration_limit  = 20
  
  ; run the loop until maximum number of iterations is exceeded
  
  for iter=0,maxiter-1 do begin
    
    ; create close birds for each bird
    close_birds_ind = fltarr(n_birds, n_close_birds_adapt)
    close_birds_ind[*,0] = indgen(n_birds)
    
    for jj = 0,n_birds-1 do begin
      
      x_p = LINDGEN(n_birds-1)
      y_p = RANDOMU(dseed, n_birds-1)
      z = x_p[SORT(y_p)]
      close_birds = z[0:n_close_birds_adapt-2]
      close_birds[where([close_birds GE jj])] += 1.
      close_birds_ind[jj,1:-1] = close_birds
      
    endfor
    
   ; find best close bird 
   aux_vect = birds_best_fun_eval[close_birds_ind]
   dummy = min(aux_vect,best_birds_fun_eval_row, dimension=2)
   best_birds_fun_eval_row = ARRAY_INDICES(aux_vect, best_birds_fun_eval_row)
   best_birds_fun_eval_row = best_birds_fun_eval_row[1, *]

 
   randSelf = randomu(seed,[n_birds,n_variable])
   randSocial = randomu(seed,[n_birds,n_variable])
   
   ; Update velocities and positions (upper and lower bound check)
   birds_new_vel = inertia_adapt * birds_vel + $
                  self_behav_const * randSelf * (birds_best_pos - birds_pos) + $
                  social_behav_const * randSocial * (birds_best_pos[close_birds_ind[(best_birds_fun_eval_row) * n_birds + findgen(n_birds)],*] - birds_pos)

   ind = where(min(finite(birds_new_vel), dimension=2) eq 1)
   birds_vel[ind,*] = birds_new_vel[ind,*]
    
   swarm_new = birds_pos + birds_vel
    
   lower_bound_ind = where(swarm_new LE lower_bound)
   upper_bound_ind = where(swarm_new GE upper_bound)
   swarm_new[lower_bound_ind] = lower_bound[lower_bound_ind]
   birds_vel[lower_bound_ind] = 0. 
   swarm_new[upper_bound_ind]= upper_bound[upper_bound_ind]
   birds_vel[upper_bound_ind] = 0.

   birds_pos = swarm_new
    
   obj_fun_eval = call_function(obj_fun_name, birds_pos, extra = extra)
    
   ind_best = where(obj_fun_eval LT transpose(birds_best_fun_eval))
   birds_best_fun_eval[ind_best] = obj_fun_eval[ind_best]
   birds_best_pos[ind_best,*]    = birds_pos[ind_best,*]

   birds_best_fun_eval_iter[(iter mod n_iteration_limit)] = min(birds_best_fun_eval)
     
   ; remember improvement in best_fun_eval
   swarm_new_best = min(birds_best_fun_eval)
   
   if (finite(swarm_new_best)) and (swarm_new_best LT birds_global_best_fun_eval) then begin
      birds_global_best_fun_eval = swarm_new_best 
      intertia_adapt_count       = max([0, intertia_adapt_count-1])
      n_close_birds_adapt        = n_close_birds
    endif else begin
      intertia_adapt_count += 1
      n_close_birds_adapt  = min([n_birds, n_close_birds_adapt+n_close_birds])
    endelse  
    
    ; update inertia 
    if intertia_adapt_count LT 2. then begin
    inertia_adapt = max([inertia_min, min([inertia_max, 2 * inertia_adapt])])
    endif else begin
      if intertia_adapt_count GT 5. then begin
        inertia_adapt = max([inertia_min, min([inertia_max, inertia_adapt / 2.])])
      endif
    endelse
     
    iter_ind = (iter mod n_iteration_limit) + 1

    ; check if any stopping criteria is satisfied
    if iter GT n_iteration_limit then begin
       if iter_ind EQ n_iteration_limit then begin
          birds_max_best_fun_eval_iter = birds_best_fun_eval_iter[0]
       endif else begin
        birds_max_best_fun_eval_iter = birds_best_fun_eval_iter[iter_ind]
       endelse
       obj_fun_update = abs(birds_max_best_fun_eval_iter - birds_best_fun_eval_iter[iter_ind-1]) / max([1,abs(birds_best_fun_eval_iter[iter_ind-1])])
    endif else begin
      obj_fun_update = !VALUES.F_INFINITY  
    endelse

    if obj_fun_update LE tolerance then break
  
    fopt = min(birds_best_fun_eval, location)
    xopt = birds_best_pos[location,*]
    
  endfor
  
stop_crit = 'OK'
if iter ge maxiter then stop_crit = 'Maximum iteration reached'
 
optim = {xopt:xopt, fopt:fopt, stop_crit:stop_crit}

if ~silent then print, 'Obj fun: ', fopt, '  Exit: ', stop_crit

return, optim


end