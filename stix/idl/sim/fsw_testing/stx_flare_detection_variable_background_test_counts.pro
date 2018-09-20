;+
; :description:
;
;      This procedure creates counts for the testing of the flare detection routine.
;      Flares with a range of different fluxes, spectra, rising timescale and decay timescales are generated.
;
;      A randomly generated background with an baseline expectation of 0.36 counts/4s/detector for
;      the thermal band and 2.4 counts/4s/detector for the non-thermal band is created for
;      all 30 Fourier detectors and the median taken to reproduce the way the counts for
;      the flare detection are estimated by taking the median over all detectors.
;
;      To investigate the effect of a variable background a sinusoidally varying component is added to the background.
;
; :categories:
;    template, example
;
; :params:
;    param1 : in, required, type="string"
;             a required string input
;    param2 :
;
;
; :keywords:
;    keyword1 : in, type="float", default="1.0"
;               an output float value
;    keyword2 :
;
;
; :examples:
;    prosample, 10, 'hello', /verbose
;
; :history:
;    20-Jul-2018 - ECMD (Graz), initial release
;
;-
pro stx_flare_detection_variable_background_test_counts, plotting = plotting

  default, plotting, 1
  ;set the timescales in seconds
  short_timescale_s = 1200
  long_timescale_s =  60
  timescale_s = [short_timescale_s,long_timescale_s]

  ;background expectation numbers taken from
  background_expectation = [0.36,2.4]*4

  ;convert timescales to 4s quicklook time bins
  timescale = timescale_s/4

  ;before every event there is as > long time scale period of only
  ;background to ensure flare flag is reset
  preevent = timescale[0]*1.2
  preevent =10

  ;empty arrays for the count and background estimates
  full_counts  = []
  full_bg  = []


  ;the peak counts for each event for both energy bands
  aa = [100,200,300,400,500,600]*.25

  ;the location of the counts peak as a fraction of the event time
  bb=10

  cc= [5,10,15,20,25,30]

  ;some events have a slower exponential decay profile these have value exp_deacy = 1
  dd= [0.01,0.03,0.07,.1,.3,.7]

  em = findgen(96)+4.


  spth =  f_vth(em,[1,3.])
  spnt=  f_pow(em,[0.2,4])
  sp = spth+spnt
  e2 = where((em ge 6 )and(em le 14) )
  e3 = where((em ge 22 )and(em le 45) )
  rat = total(sp[e3])/total(sp[e2])

  rat = [0.1,0.05,0.02,0.01,0.007,0.005]

  ;loop over both timescales, both energy bands and all flare events
  for baseline = 0,1 do begin
    for i = 0, 5 do begin
      for j = 0, 5 do begin
        for k = 0, 5 do begin
          for l = 0, 5 do begin

            for eband = 0,1 do begin
              ;the number of bins for the event is the duration * the timescale currently under consideration
              nbins = timescale[baseline]

              ;randomly generate background counts for 31 (imaging  + background) detectors for all time
              ;bins. A Poisson distribution with expectation dependent on the energy channel currently
              ; being tested is used.
              nn = (preevent+nbins)

              phase = randomu(seed)*2*!pi
              amp = randomu(seed)
              t= findgen(nn)

              random_bg = randomu(seed, 31L*(preevent+nbins), poi=background_expectation[eband])
              random_bg  = reform(random_bg, 31, preevent+nbins)
              backvar  = amp*sin(4*(3.14*t/(nn) + phase)) +1 >0

              bvar =  transpose(rebin(backvar, (preevent+nbins),31))
              random_bg = poidev(ceil(0.5*random_bg*bvar +0.5*bvar))
              ;take the median over the imaging detectors
              background = (median(random_bg[0:29,*], dim = 1))

              ;the current counts array is given by a (2 energy bands) * (number of time bins)
              ;array initially set to the expectation values of the background for each energy band.
              ;The background for the energy band currently being tested is then replaced by the more
              ;realistic random distribution
              current_counts = rebin(transpose(background_expectation), preevent+nbins,2)
              current_counts[*, eband] = background

              ;the background estimate for the current event is taken as the remaining
              ;(1 detector * n time bins) values in the random_bg array
              current_background = rebin(transpose(background_expectation),preevent+nbins,2)
              current_background[*, eband] = reform(random_bg[30,*], preevent+nbins)

            endfor
            t= findgen(nbins)

            b = bb
            c = cc[j]
            d = dd[k]
            bc = b - 10
            a= aa[l]
            ap = rat[i]*a
            z = (2*b+c^2*d)/(2*c)
            fc = ulong(.5*sqrt(!pi)*a*c*exp(d*(b-t)+(c^2*d^2/4))*(erf(z)-erf(z - t/c)))

            ;the gaussian peak is added to the background in the relevant energy channel
            current_counts[preevent:-1, 0] =  current_counts[preevent:-1, 0]  + fc
            fd = ulong(ap*exp(-(t-bc)^2./c^2))
            current_counts[preevent:-1, 1] =  current_counts[preevent:-1, 1]  + fd
            ;if the current event has an exponential decay profile the counts after the maximum value
            ;are replaced with counts for this profile


            if plotting then begin
              fd = stx_fsw_flare_detection(current_counts, current_background,  0L*current_counts[*,0], plotting = plotting)
              wait,1

              plot, current_counts[*,0], ytitle = 'Counts in current energy band', xtitle = 'QL time bin', /ylog
              oplot, current_counts[*,1], color = 100

            endif

            ;the counts and background for the completed event are added to the full arrays
            full_counts = [full_counts, current_counts]
            full_bg = [full_bg, current_background]
          endfor
        endfor
      endfor
    endfor
  endfor

  if plotting then begin

    fd = stx_fsw_flare_detection(full_counts, full_bg,  0L*full_counts[*,0], plotting = plotting)

    det = where(fd gt 0)
    fd[det] = 1


    p1= plot(tt_jd, c2,color = reform(a[5,*]), /ylog , yrange = [min(c)*0.5,max(c)*5],/ystyle ,/xstyle, name = namearry_stix[0], $
      POSITION =[0.1,0.1,0.76,0.43], xtickunits='time' , current=1 , XTICKFORMAT='(C(CHI2.2,":",CMI2.2))')
    p2 = plot(tt_jd,c3,color = reform(a[1,*]) ,name = namearry_stix[2], /over)
    p3 = plot(tt_jd,ffs, color = reform(a[3,*]) ,name = 'STIX Flare Flag', /over)
    leg = legend(font_size=11,shadow = 0,/auto_text_color, transparency=50, position = [0.96,0.33], target = [p1,p2,p3])

    ax = p1.axes
    ax[0].title = "Start Date: " + stx_time2any((fc.ut)[0],/vms)
    p1.title = 'STIX Counts'
    p1.ytitle = 'STIX Counts'

    p.save, savename

    loadct, 39, /silent
    for i = 0, 23000,100 do begin
      plot, findgen(400)+i, total(full_counts[i:i+400,*],2),/ylog, yrange = [0.1,1d8], ytitle = 'Total counts', xtitle = 'QL time bin'
      oplot,findgen(400)+i, fd[i:i+400]*max(total(full_counts[i:i+400,*],2)/2.)+0.1, color = 25
      wait,0.5
    endfor

  endif


end

