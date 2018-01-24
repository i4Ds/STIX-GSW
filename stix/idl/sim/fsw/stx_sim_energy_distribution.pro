;+
; :description:
;     Randomize fixed number of elements to reproduce given distribution (thermal, power).
;
; :params:
;     nofelem          : in, optional, type=integer, default=1,000,000
;                        number of elements to be randomized
;     type             : in, optional, type=string, default='thermal'
;                        type of distribution
;                        available types:
;                        'thermal'  - "thermal" distribution: F(E) = K * exp( -c * E ) ,
;                        'powerlaw' - power law distribution: F(E) = K * E^(-gamma) ,
;                        'gaussian' - gaussian distribution: F(E) = K * exp( - (E - pos)^2 / (2 * (sig^2)) )
;     param            : in, optional, type=array
;                        parameters of the distribution
;                        1) when the type is 'thermal' the param should be an array [ K, c ], default=[ 1, 0.1 ]
;                        2) when the type is 'powerlaw' the param should be single number (value of gamma), default = 3.5
;                        3) when the type is 'gaussian' the param should be an array [pos, sig], default = [6.7, 0.1]
;     energy_range     : in, optional, type=double, default=[ 4, 150 ]
;                        energy range of the distribution in keV
;
; :keywords:
;     sort          : return sorted values
;
; :returns:
;     dblarr with randomized elements of defined distribution.
;
; :examples:
;    randomize 10,000,000 events over energies from 1keV to 200keV:
;    using power law distribution with gamma=5, and constant K=1.0
;
;    distribution = stx_sim_energy_distribution( nofelem=10000000LL, type='power', param=[1.0,5], energy_range=[1,200] )
;
;
; :history:
;     26-Feb-2014 - Marek Steslicki (Wro), initial release
;     06-Aug-2014 - Laszlo I. Etesi (FHNW), code auto format, added
;                   uniform energy distribution
;     04-Dec-2014 - Aidan O'Flannagain (TCD), added gaussian energy
;                   distribution
;     04-Dec-2014 - Shaun Bloomfield (TCD), changed type from 'power'
;                   to 'powerlaw' as in stx_sim_source_structure.pro
;     22-Jan-2015 - Laszlo I. Etesi (FHNW), added a failover in case NANs are generated as output
;     05-Mar-2015 - Aidan O'Flannagain (TCD), altered 'gaussian'
;                   background type so that it expects a FWHM input
;     01-Feb-2016 - ECMD (Graz), If uniform distribution is given in a scenario with the keywords energy_spectrum_param1 and energy_spectrum_param2
;                                they are interpreted as the upper and lower energy limits
;     06-Mar-2017 - Laszlo I. Etesi (FHNW), added seed keyword
;     28-Nov-2017 - ECMD (Graz), added bkg_continuum, bkg_lines and degraded distributions 

;     
;-
function stx_sim_energy_distribution, nofelem=nofelem, type=type, energy_range=energy_range, param=param, sort=sort, seed=seed

  if not keyword_set(energy_range) then begin
    if type eq 'uniform' and keyword_set(param) then energy_range=[param[0],param[1]] $
    else energy_range=[4.d,150.d] ; default energy range in keV
    message,'Energy range: [ '+trim(string(energy_range[0]))+', '+trim(string(energy_range[1]))+' ]',/inf
  endif
  energy_range=double(energy_range)

  if not keyword_set(nofelem) then nofelem=1000000   ; default number of elements
  if not keyword_set(type) then begin
    message,'Type of distribution not set: assume thermal',/inf
    type='thermal'
  endif

  K=1
  gamma=4
  c=0.1

  case type of
    'uniform': begin
      distribution = randomu(seed, nofelem, /double)
      distribution = energy_range[0]+(distribution/max(distribution))*(energy_range[1]-energy_range[0])
    end
    'powerlaw': begin
      if not keyword_set(param) then param=3.5   ; default distribution parameter
      K=0.1
      gamma=param
      ;                distribution = energy_range[0]+randomu( seed, NofElem, /double)*(energy_range[1]-energy_range[0])
      distribution = randomu(seed, NofElem, /double)
      distribution = ((distribution)/(double(K)/double(gamma-1)))^(gamma-1)
      distribution = energy_range[0]+(distribution/max(distribution))*(energy_range[1]-energy_range[0])

      ;; events which are outside given time period are randomized again
      ;                missed_elems=where(distribution lt energy_range[0] or distribution gt energy_range[1]) ; events which are outside given energy window
      ;                while size(missed_elems,/n_dimensions) gt 0 do begin
      ;                  n=n_elements(missed_elems)
      ;;                  message, trim(string(n))+' missed',/inf
      ;                  addtodistribution = energy_range[0]+randomu( seed, n, /double)*(energy_range[1]-energy_range[0])
      ;                  addtodistribution = ((addtodistribution)/(double(K)/double(gamma-1)))^(gamma-1)
      ;                  ok_elems=where(addtodistribution ge energy_range[0] and distribution le energy_range[1])
      ;                  if size(ok_elems,/n_dimensions) gt 0 then distribution[missed_elems[0:n_elements(ok_elems)-1]]=addtodistribution[ok_elems]
      ;                  missed_elems=where(distribution lt energy_range[0] or distribution gt energy_range[1])
      ;                endwhile

    end
    'thermal': begin
      if not keyword_set(param) then param=[1,0.1]   ; default distribution parameters
      K=param[0]
      c=param[1]
      distribution = energy_range[0]+randomu(seed, NofElem, /double)*(energy_range[1]-energy_range[0])
      distribution=alog(K/(c*distribution))/c

      ;                distribution-=min(distribution)
      ;                distribution = energy_range[1]-(distribution/max(distribution))*(energy_range[1]-energy_range[0])
      ; events which are outside given time period are randomized again
      missed_elems=where(distribution lt energy_range[0] or distribution gt energy_range[1]) ; events which are outside given energy window
      while size(missed_elems,/n_dimensions) gt 0 do begin
        n=n_elements(missed_elems)
        ;                  message, trim(string(n))+' missed',/inf
        addtodistribution = energy_range[0]+randomu(seed, n, /double)*(energy_range[1]-energy_range[0])
        addtodistribution=alog(K/(addtodistribution*c))/c
        ok_elems=where(addtodistribution ge energy_range[0] and distribution le energy_range[1])
        if size(ok_elems,/n_dimensions) gt 0 then distribution[missed_elems[0:n_elements(ok_elems)-1]]=addtodistribution[ok_elems]
        missed_elems=where(distribution lt energy_range[0] or distribution gt energy_range[1])
      endwhile
    end
    ;Gaussian energy distribution
    ;param[0] - central energy
    ;param[1] - standard deviation
    ;If the full Gaussian does not lie within the energy range (default [4, 150]), a cumulative sum of the 'clipped' Gaussian
    ;is calculated and inverted. The distribution is then randomly sampled from this sum.
    'gaussian': begin
      if not keyword_set(param) then param=[6.7,0.1]   ; default distribution parameters (Fe line complex)
      pos = param[0]  ;central position
      sig = param[1]/(2.*sqrt(2.*alog(2.)))  ;standard deviation, converted from FWHM input
      distribution = (randomu(seed, nofelem, /double, /normal)*sig) + pos
      ;if any of the randomly selected points lie outside of the energy range, a cumulative distribution is generated instead
      if min(distribution) lt energy_range[0] or max(distribution) gt energy_range[1] then begin
        ;define integral limits and energy array
        limit0 = max([energy_range[0], pos - 5*sig])
        limit1 = min([energy_range[1], pos + 5*sig])
        energy = dindgen(nofelem)/nofelem*(limit1-limit0)+limit0
        ;calculate cumulative distribution function
        cumul_dist = total(gaussian(energy, [1., pos, sig, 0]), /cumulative, /double)
        cumul_dist = cumul_dist/last_item(cumul_dist)
        ;find the energy values at which the randomu photons land on cumul_dist
        ninterp = 100000L
        x = interpol( energy, cumul_dist, dindgen( ninterp + 1 ) / ninterp )
        distribution = x[randomu(seed, nofelem, /double)*ninterp]
      endif
    end
    'bkg_continuum': begin
      stx_bkg_continuum_mdl, edg2, continuum
      edge_products, edg2, width = width, edges_1=edg1
      use = where(edg1 gt 1.0)
      dstr = stx_build_drm(edg1[use], /back, /tail)
      phm  = dstr.pls_ht_mat
      bkg =  phm#continuum[use[0:-2]]
      cumulative_counts = total( /cum, /double, bkg)
      integral_counts = cumulative_counts / last_item( cumulative_counts )
      ninterp = 100000L
      emean = edg1[use[0:-2]]
      x = interpol( emean, integral_counts, dindgen( ninterp + 1 ) / ninterp )
      distribution = x[ randomu( seed, nofelem ) * ninterp ]
    end
    'bkg_lines': begin
      stx_bkg_continuum_mdl, edg2, continuum
      lines = stx_bkg_lines_mdl( edg2) ;counts per bin
      edge_products, edg2, width = width, edges_1=edg1
      use = where(edg1 gt 1.0)
      dstr = stx_build_drm(edg1[use], /back, /tail)
      phm  = dstr.pls_ht_mat
      bkg =  phm#lines[use[0:-2]]
      cumulative_counts = total( /cum, /double, bkg)
      integral_counts = cumulative_counts / last_item( cumulative_counts )
      ninterp = 100000L
      emean = edg1[use[0:-2]]
      x = interpol( emean, integral_counts, dindgen( ninterp + 1 ) / ninterp )
      distribution = x[ randomu( seed, nofelem ) * ninterp ]
    end
    'degraded': begin
      if not keyword_set(param) then param=[0.]
      stx_bkg_continuum_mdl, edg2, continuum
      edge_products, edg2, width = width, edges_1=edg1
      bkg = degraded_sim(param[0])
      cumulative_counts = total( /cum, /double, bkg)
      use = where(edg1 gt 1.0)
      integral_counts = cumulative_counts / last_item( cumulative_counts )
      ninterp = 100000L
      emean = edg1[use[0:-2]]
      x = interpol( emean, integral_counts, dindgen( ninterp + 1 ) / ninterp )
      distribution = x[ randomu( seed, nofelem ) * ninterp ]
    end
    else    : begin
      distribution = energy_range[0] + randomu(seed, NofElem, /double)*(energy_range[1]-energy_range[0])
    end
  endcase

  if keyword_set(reverse) then distribution=length-distribution

  if keyword_set(sort) then distribution=distribution(sort(distribution))

  ; histogram calculation (idl function histogram does not work well with this data)
  if keyword_set(histogram) then begin
    t=ulong64(0)
    step=ulong64(1.d/data_granulation)
    length_sec=length*data_granulation
    histogram=ulon64arr(round(length_sec+1.d))
    i=0
    while t lt length do begin
      histogram[i]=n_elements(where(distribution ge t and distribution le t+step))
      i++
      t+=step
    endwhile
  endif

  if keyword_set(sort) then distribution=distribution(sort(distribution))

  if(max(where(finite(distribution) ne 1)) ne -1) then message, "There are NAN in the distribution. Please check your input parameters"

  return,distribution

end


