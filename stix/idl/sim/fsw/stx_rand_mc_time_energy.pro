; Document name: stx_rand_mc_time_energy.pro
; Created by:    Nicky Hochmuth, 2014/01/29
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_rand_mc_time_energy
;
; PURPOSE:
;       helper method to generate a number of random time energy points for a given distribution with a Monte Carlo approach
;
; CATEGORY:
;       Simulation Rhessi2Stix FSW
;
; CALLING SEQUENCE:
;
;       a = stx_rand_mc_time_energy(10000L)
;       simulates 100000 random time energy points for a default distribution 
;
; HISTORY:
;       2014/01/29 - Nicky Hochmuth (FHNW), initial release
;-

;+
; :description:
;    runs and visualizes the grid response simulation by Shaun Bloomfield .
;    a gaussian point source is simulated
;
; :keywords:
;    seed:        in, type="long", default="SYSTIME(/seconds)"
;                 the seed for the random number generator
;
;    max_time:    in, type="double", default="1"
;                 the time span for the simulated distribution 
;
;    spectrogram: in, type="double(time,energy)", default="(dist(100,n_e*2))[*,n_e:*]^4d"
;                 the given distribution (shape of an event) as a spectrogram
;
;    energy_range: in, type="float(2)", default="[4,150]"
;                  the energy range
;                  
;    energy_axis:  in, type="stx_energy_axis", default="stx_construct_energy_axis()"
;                  the energy axis of the given spectrogram 
 
;
;    plotting:    in, type="flag", default="off"
;                 create some charts
;
;    debug:       in, type="flag", default="off"
;                 print out time and monte carlo loops required
;
; :returns:
;-
function stx_rand_mc_time_energy, n, seed=seed, max_time=max_time, spectrogram=spectrogram, energy_range=energy_range, energy_axis=energy_axis, plotting=plotting, debug=debug
  default, seed, SYSTIME(/seconds)
  default, min, 0d
  default, max_time, 1d
  default, spectrogram, (dist(100,32*2))[*,32:*]^4d
  default, energy_axis, stx_construct_energy_axis()
  
  dim = double(size(spectrogram))
  n_e = dim[2]
  n_t = dim[1]
  
  
  max_time = double(max_time)
  rand_n = 10000L
  
  bin_size_time=1d/(n_t-1)
  
  spectrogram = abs(spectrogram)/double(max(spectrogram))
  
  energy_distribution = total(spectrogram,1,/double)
  energy_distribution = energy_distribution/max(energy_distribution)
  
  min_energy_axis = energy_axis.LOW[0]
  range_energy_axis = energy_axis.HIGH[n_elements(energy_axis.high)-1]-min_energy_axis
  
  rand_idx = rand_n
  
  result = dblarr(n,2)
  
  start=systime(/seconds)
  
  nc=n-1
  counter = ulong(0)
  while nc ge 0 do begin
    counter++
    ;generate the next chunk of random numbers
    if rand_idx+4 ge rand_n then begin
      numbers = randomu(seed,rand_n,/double)
      rand_idx = 0
    endif
    
    e = double(numbers[rand_idx++])
    ee = min_energy_axis + e * range_energy_axis 
    el=max(where(energy_axis.high le ee,count_min))
    if count_min eq 0 then el = 0
    if el eq n_elements(energy_axis.mean)-1 then el--
    
    er=el+1
    
    bin_size_energy = energy_axis.width[el]
    
    slope_energy = (energy_distribution[el]-energy_distribution[er])/bin_size_energy
    
    if energy_distribution[el]+((energy_axis.high[el]-ee)*slope_energy) ge numbers[rand_idx++] then begin
      result[nc,0] = ee
    end else begin
      continue
    end
    
    t=double(numbers[rand_idx++])
    tl=floor(t*(n_t-1))
    tr=tl+1
    
    slope_l = (spectrogram[tr,el]-spectrogram[tl,el])/bin_size_time
    slope_r = (spectrogram[tr,er]-spectrogram[tl,er])/bin_size_time
    
    slope_time = ((ee-el)*slope_l + (er-ee)*slope_r)
    
    if spectrogram[tl,el]+((t-(tl*bin_size_time))*slope_time) ge numbers[rand_idx++] then begin
      result[nc--,1] = t*max_time
    end   
  end 
  
  endtime=systime(/seconds)
  
  if keyword_set(plotting) then begin
      window, /free
      !P.multi = [0,3]
      !X.margin = [0,0]
      contour, spectrogram
      plot, result[*,1], result[*,0],  psym=3, /ystyle, /xstyle
      contour, hist_2d(result[*,1],result[*,0], bin1=0.01,bin2=1)
      !P.multi = -1
      !X.margin = -1
  endif
  
  if keyword_set(debug) then print, counter, " trys in ", trim(endtime-start), " seconds"
  
  
  return, result
  
end
