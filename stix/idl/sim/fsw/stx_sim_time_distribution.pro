;+
; :description:
;     Randomize fixed number of elements to reproduce given distribution (uniform, linear, gaussian, exponent).
;
; :params:
;     nofelem          : in, optional, type=integer, default=1,000,000
;                        number of elements to be randomized
;     length           : in, optional, type=double, default=100.d ( 100 seconds )
;                        length of data set in seconds
;     type             : in, optional, type=string, default='uniform'
;                        type of distribution
;                        available types:
;                        'uniform' - uniform distribution,
;                        'linear'  - linear rising of the elements density beginning from 0,
;                        'gaussian'- gaussian distribution with defined mean and FWHM (those paramiters are given by param value),
;                        'exp'     - exponent rising of the elements density beginning from 0, the base of exponent can be given by param value
;     param            : in, optional, type=double or dblarr
;                        parameters of the distribution
;                        used only when type 'gauss' or 'exp' is set:
;                        1) when the type is 'gauss' the param should be a signe number: FWHM of the gaussian distribution (in seconds), default=0.25*length
;                        2) when the type is 'exp' the param should be a signe number which will be the base of the exponent, default=e ( exp(1) )
;     data_granulation : in, optional, type=double, default=20e-9  (20 nanoseconds)
;                        the units in which data will be returned by this function
;     histogram        : out, optional, type=ulon64arr
;                        returns histogram of the distribution in 1 second bins
;
; :keywords:
;     sort          : return sorted values
;     reverse       : reverse the returned array
;                     descending distribution in case of 'exp' and 'linear' type (default: increasing)
;     seed          : seed for randomu(n) generator. For same number of events and the same input seed the
;                     output will be identical
;
; :returns:
;     ulon64arr with randomized elements of defined distribution.
;     Units of the returned values are the same as given in the data_granulation parameter (default = 20 nanoseconds)
;
; :examples:
;    randomize 10,000,000 events over 80 seconds period with
;    a gaussian distribution with the mean value = 30 seconds and FWHM = 10 seconds:
;
;    gaussian_distrubution = stx_sim_time_distribution( nofelem=10000000LL, type='gauss', param=[30,10], length=80 )
;
;
; :modification history:
;     25-Feb-2014 - Marek Steslicki (Wro), initial release
;     07-Mar-2014 - Marek Steslicki (Wro), default values of gaussian function changed from fixed numbers to relative points nad spans
;     11-Mar-2014 - Marek Steslicki (Wro), mean value of gaussian distribution changed to the fixed number (cannot be parameterized): 25% of the duration time
;     05-Dec-2014 - Shaun Bloomfield (TCD), changed 'gauss' to
;                   'gaussian' to be consistent with other source
;                   distribution formats
;     22-feb-2016 - richard schwartz rschwartz70@gmail.com, added keyword SEED for reproducibility
;     25-Sep-2017 - ECMD (Graz), Reverse and sort keywords can now also be included in the string for the type keyword so they can be specified directly in the scenario files. 
;    
;-
function stx_sim_time_distribution, nofelem=nofelem, type=type, length=length, param=param, data_granulation=data_granulation, sort=sort, reverse=reverse, histogram=histogram, $
    seed = seed
    
  if not keyword_set(data_granulation) then data_granulation=double(20e-9) ; default data granulation (20 nanoseconds)
  
  if not keyword_set(length) then length=100.d ; default duration (100 seconds)
  length_sec=length
  length=length/data_granulation   ; conversion to a given data granulation
  if not keyword_set(nofelem) then nofelem=1000000   ; default number of events
  if not keyword_set(type) then begin
    message,'Type of distribution not set: assume uniform',/inf
    type='uniform'
  endif
  
  type = strsplit(type,'_', /ex)
  reverse = n_elements(where( strlowcase(type) eq 'reverse',/null))
  sort = n_elements(where( strlowcase(type) eq 'sort',/null))
  
  case type[0] of
    'linear': begin
      distribution = randomu( seed, NofElem, /double) * length + 0.5d
      distribution=ulong64(sqrt(distribution)*length/sqrt(length))
    end
    ;    'square': distribution=ulong64((sqrt(sqrt(distribution)))*length/sqrt(sqrt(length)))
    'exp'   : begin
      distribution = randomu( seed, NofElem, /double) * length + 0.5d
      if not keyword_set(param) then begin
        logarithm_base=exp(1.d)
      endif else begin
        if size(param,/n_dimensions) gt 0 then param=param[0]
        logarithm_base=param
      endelse
      distribution=alog(double(distribution)*alog(logarithm_base))/alog(logarithm_base)+1.d
      distribution/=max(distribution)
      distribution=ulong64(distribution*length)
    ;                distribution+=ulong((1-max(distribution)+min(distribution))/2.0)
      
    end
    'gaussian' : begin
      mean_sec =length_sec*0.50d ;50.d
      if not keyword_set(param) then begin
        FWHM_sec=length_sec*0.25d ;20.d
        ;                     mean_sec =length_sec*0.50d ;50.d
        ;                     message, "Assumed gaussian mean = "+trim(string(mean_sec))+" seconds",/inf
        message, "Assumed gaussian FWHM = "+trim(string(FWHM_sec))+" seconds",/inf
      endif else begin
        if size(param,/n_dimensions) gt 0 then param=param[0]
        ;                     mean_sec=double(param[0])
        FWHM_sec=double(param)
      endelse
      FWHM=FWHM_sec/data_granulation
      sigma = FWHM / ( 2.d * sqrt(2.d* alog(2.d)) )
      mean = mean_sec/data_granulation
      distribution =  randomn(seed, NofElem, /double)
      distribution = distribution * sigma + mean
      below_zero = where(distribution lt 0)
      distribution[below_zero] = length-distribution[below_zero] ; putting negative numbers above time range (sign would be lost in the next step - ulong64)
      distribution = ulong64( distribution + 0.5d )
      ; events which are outside given time period are randomized again
      missed_elems=where(distribution lt 0 or distribution gt length) ; events which are outside given time period
      if size(missed_elems,/n_dimensions) gt 0 then begin
        if n_elements(missed_elems) gt 0.5d*nofelem then begin
          message, "Large number of elements was randomized outside given time interval due to selected distribution parameters. Iteration process may take a long time.", /inf
          message, "Time interval = [ 0, "+trim(string(length_sec))+" ]", /inf
          message, "mean = "+trim(string(mean_sec))+" sec", /inf
          message, "FWHM = "+trim(string(FWHM_sec))+" sec", /inf
        endif
      endif
      while size(missed_elems,/n_dimensions) gt 0 do begin
        n=n_elements(missed_elems)
        ;                     message, trim(string(n))+' missed',/inf
        addtodistribution = randomn(seed, n, /double)
        addtodistribution = addtodistribution * sigma + mean
        below_zero = where(addtodistribution lt 0)
        addtodistribution[below_zero] = length-addtodistribution[below_zero] ; putting negative numbers above time range (sign would be lost in the next step - ulong64)
        addtodistribution = ulong64( addtodistribution + 0.5d )
        ok_elems=where(addtodistribution ge 0 and addtodistribution le length)
        distribution[missed_elems[0:n_elements(ok_elems)-1]]=addtodistribution[ok_elems]
        missed_elems=where(distribution lt 0 or distribution gt length)
      endwhile
    end
  else    : begin
    distribution = ulong64( randomu( seed, NofElem, /double) * length + 0.5d )
  end
endcase

if keyword_set(reverse) then distribution=length-distribution

if keyword_set(sort) then distribution=distribution(sort(distribution))

; histogram calculation (idl function histogram does not work well with this data)
if arg_present(histogram) then begin
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


return,distribution

end


