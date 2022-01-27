function swarmintelligence, fun_name, Nvars, lbRow, ubRow, numParticles,TolFun, maxiter, extra = extra, $
                            silent = silent, cSelf = cSelf, cSocial = cSocial, minNeighborhoodSize = minNeighborhoodSize, $
                            minInertia = minInertia, maxInertia = maxInertia
  
  default, silent, 0
  default, cSelf, 1.4900
  default, cSocial, 1.4900
  default, minNeighborhoodSize, max([2.,floor(numParticles*0.2500)])
  default, minInertia, 0.1000
  default, maxInertia, 1.1000

  
  lbMatrix = cmreplicate(lbRow, numParticles)
  ubMatrix = cmreplicate(ubRow, numParticles)

  lbMatrix = transpose(lbMatrix)
  ubMatrix = transpose(ubMatrix)
  
  
  StallIterLimit = 20
  InitialSwarmSpan = numParticles*(fltarr(1,Nvars)+1)
  Iteration = -1
  StopFlag = 0

  FunEval = numParticles
  
  Positions = lbMatrix+randomu(seed,[numParticles,Nvars])*(ubMatrix-lbMatrix)
  
  InitialSpan = transpose([InitialSwarmSpan])
  vmax = min([[ubRow-lbRow],[InitialSpan]], dimension=2)
  

  ones = fltarr(numParticles,1)
  vmax = reform(vmax, [1,nvars])
  Velocities_aux = ones # vmax
  Velocities_aux1 = 2.*Velocities_aux*randomu(seed,[nvars,numParticles])
  Velocities = -Velocities_aux+Velocities_aux1
  
  Fvals = call_function(fun_name, Positions, extra = extra)

  IndividualBestFvals = Fvals;
  IndividualBestPositions = Positions;

  bestFvals = min(Fvals)
  bestFvalsWindow = (fltarr(20,1)+1)*!values.f_nan
  
  adaptiveInertiaCounter = 0.
  adaptiveInertia = maxInertia
  adaptiveNeighborhoodSize = minNeighborhoodSize

  ExitFlag = 'Null'
  
  WHILE ExitFlag EQ 'Null' do begin
    
    Iteration ++

    neighborIndex = fltarr(numParticles, adaptiveNeighborhoodSize)
    neighborIndex[*,0] = indgen(numParticles)
    
    for i = 0,numParticles-1 do begin
      x_p = LINDGEN(numParticles-1)
      y_p = RANDOMU(dseed, numParticles-1)
      z = x_p[SORT(y_p)]
      neighbors = z[0:adaptiveNeighborhoodSize-2]
      iShift = where([neighbors GE i])
      neighbors[iShift] = neighbors[iShift] + 1.
      neighborIndex[i,1:-1] = neighbors
    endfor
    
   arr = IndividualBestFvals(neighborIndex)
   dummy = min(arr,bestrowindex, dimension=2)
   bestrowindex = ARRAY_INDICES(arr, bestrowindex)
   bestrowindex = bestrowindex[1, *]
    
   bestLinearIndex = (bestrowindex)*numParticles + findgen(numParticles);
   bestNeighborIndex = neighborIndex(bestLinearIndex)
 
   randSelf = randomu(seed,[numParticles,nvars])
   randSocial = randomu(seed,[numParticles,nvars])
        
   newVelocities = (adaptiveInertia*Velocities) + $
                    cSelf*randSelf*(IndividualBestPositions-Positions) +    $
                    cSocial*randSocial*(IndividualBestPositions[bestNeighborIndex,*]-Positions);

    ind = where(min(finite(newVelocities), dimension=2) eq 1)
    Velocities[ind,*] = newVelocities[ind,*]
    
    newPopulation = Positions + Velocities;
    
    LB_ind = where((newPopulation) LE lbMatrix)
    UB_ind = where((newPopulation) GE ubMatrix)
    newPopulation(LB_ind)= lbMatrix(LB_ind)
    Velocities(LB_ind) = 0. 
    newPopulation(UB_ind)= ubMatrix(UB_ind)
    Velocities(UB_ind) = 0.

    
    Positions = newPopulation
    
    Fvals = call_function(fun_name, Positions, extra = extra)
    
    FunEval = FunEval + numParticles
    
    ind_best = where(Fvals LT transpose(IndividualBestFvals))
    IndividualBestFvals[ind_best] = Fvals[ind_best]
    IndividualBestPositions[ind_best,*] = Positions[ind_best,*]

    bestFvalsWindow[(Iteration mod StallIterLimit)] = min(IndividualBestFvals);
     
    newBest = min(IndividualBestFvals);
   
   if (finite(newBest)) and (newBest LT bestFvals) then begin
      bestFvals = newBest; 
      adaptiveInertiaCounter = max([0, adaptiveInertiaCounter-1])
      adaptiveNeighborhoodSize = minNeighborhoodSize
    endif else begin
      adaptiveInertiaCounter = adaptiveInertiaCounter+1;
      adaptiveNeighborhoodSize = min([numParticles, adaptiveNeighborhoodSize+minNeighborhoodSize]);
    endelse  
    
    if adaptiveInertiaCounter LT 2. then begin
    adaptiveInertia = max([minInertia, min([maxInertia, 2*adaptiveInertia])])
    endif else begin
      if adaptiveInertiaCounter GT 5. then begin
        adaptiveInertia = max([minInertia, min([maxInertia, 0.5*adaptiveInertia])])
      endif
    endelse
     
    iterationIndex = (Iteration mod StallIterLimit)+1
    bestFval = bestFvalsWindow[iterationIndex-1]

    if Iteration GT StallIterLimit then begin
       if iterationIndex EQ StallIterLimit then begin
          maxBestFvalsWindow = bestFvalsWindow[0]
       endif else begin
        maxBestFvalsWindow = bestFvalsWindow[IterationIndex]
       endelse
       funChange = abs(maxBestFvalsWindow-bestFval)/max([1,abs(bestFval)])
    endif else begin
      funChange = !VALUES.F_INFINITY  
    endelse


    if Iteration GT maxiter then begin
    exitFlag = 'MaxIter'
    endif
    if funChange LE TolFun then begin
    exitFlag = 'OK'
    endif
  
    fopt = min(IndividualBestFvals, location)
    xopt = IndividualBestPositions[location,*]
    
  ENDWHILE
  
 
optim = {xopt:xopt, fopt:fopt, ExitFlag:ExitFlag}

if ~silent then print, 'Obj fun: ', fopt, '  Exit: ', ExitFlag

return, optim


end