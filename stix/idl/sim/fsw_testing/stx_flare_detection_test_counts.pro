;+
;
; :description:
;
;      This scenario consists of 9 flare events each repeated 4 times, once for each combination
;      of energy band and baseline duration. Each event starts with a long baseline duration
;      of only background so the flare flag should be reset to 0 between events. The thermal
;      and non-thermal conditions are tested separately with the counts in the energy band
;      not being tested set to a constant value around the expected median. As the conditions
;      between the thermal and non-thermal  bands are expected to be quite different a different
;      set of peak counts is used for each energy band.
;
;      The first 6 events have a range of intensities very roughly corresponding to the
;      flare classifications B1 to X1 and are also made up of a combination of short Gaussian
;      pulses and longer events with Exponential decay tails. The decay constant of the exponential
;      functions are set so that they reach 1 count per time bin at the end of the event.
;
;      The 7th and 8th events should not trigger a flare detection. The 7th as the peak
;      counts will not meet the minimum threshold and the 8th as the pre event baseline
;      is enhanced to a significant fraction of the peak.
;
;      The 9th event consists of a double Gaussian peak with each peak separated by the
;      relevant baseline under consideration.
;
;      A randomly generated background with an expectation of 0.6 counts/4s/detector for
;      the thermal band and 3 counts/4s/detector for the non-thermal band is created for
;      all 30 Fourier detectors and the median taken to reproduce the way the counts for
;      the flare detection are estimated by taking the median over all detectors. A constant
;      seed is used for reproducibility.
;
;      Table of relevant parameters for each event:
;
;    Event    Decay profile     Thermal peak    Equivalent Class    Non-thermal Peak     Event duration  Peak location
;                               (Counts)                            (Counts)             (x baseline)    (fraction of event duration)
;      1        Gaussian        1x10^4           C1                 160                  1               0.5
;      2        Gaussian        1x10^3           B1                 160                  1               0.5
;      3        Exponential     1x10^4           C1                 260                  6               0.1
;      4        Gaussian        2x10^7           X1                 2600                 1               0.5
;      5        Gaussian        1x10^5           M1                 2600                 1               0.5
;      6        Exponential     2x10^7           X1                 500                  6               0.1
;      7        Gaussian        4                N/A                20                   1               0.5
;      8        Gaussian        12               N/A                40                   1               0.5
;      9        Gaussian        1x10^3, 1x10^3   B1                 300, 300             2               0.25, 0.75
;
;
; :keywords:
;    background          : out, optional
;                         The background counts corresponding to the output flare  detection counts array
;    plotting            : in, optional
;                         if keyword is set lightcurves will be plotted
;    short_timescale_s   : in, optional, default = 60
;                         the short baseline timescale in units of seconds
;    long_timescale_s    : in, optional, default = 1200
;                         the long baseline timescale in units of seconds
;
;
; :returns:
;    full_counts an array of counts in the two flare detection energy bands for all 36 simulated events
;
; :examples:
;    fd_counts = stx_flare_detection_test_counts(background = background, /plotting)
;
; :history:
;    20-Jul-2018 - ECMD (Graz), initial release
;
;-
function stx_flare_detection_test_counts, background = background, total_background = total_background, combine = combine, short_timescale_s =short_timescale_s, long_timescale_s = long_timescale_s, $
  plotting = plotting, save_plots = save_plots
  ;set the timescales in seconds
  default, long_timescale_s,  1200l
  default, short_timescale_s,   60l
  default, plotting, 0
  default, save_plots, 0
  default, combine, 0

  timescale_s = [short_timescale_s,long_timescale_s]

  ;background expectation numbers taken from
  background_expectation = [0.6,3.]

  ;convert timescales to 4s quicklook time bins
  timescale = timescale_s/4l

  ;before every event there is as > long time scale period of only
  ;background to ensure flare flag is rest
  preevent = long(timescale[1]*1.2)

  ;empty arrays for the count and background estimates
  full_counts  = []
  full_bg  = []
  total_background =[]
  offset = [0]

  ;the peak counts for each event for both energy bands
  peak_counts = [[1e4,1e3,1e4,2e7,1e5,2e7,4,12,1e3],$
    [260,160,260,2600,2600,500,20,40,300]]

  ;the location of the counts peak as a fraction of the event time
  max_location = [0.5,0.5,0.1,0.5,0.5,0.1,0.5,0.5,0.25]

  ;the duration of the event in units of the current baseline under consideration
  length       = [1,1,6,1,1,6,1,1,2]

  ;some events have a slower exponential decay profile these have value exp_deacy = 1
  exp_deacy    = [0,0,1,0,0,1,0,0,0]

  title_timescale = ['Short Timescale','Long Timescale']
  title_eband = ['Thermal', 'Non-thermal']
  title_event = ['Standard Duration Moderate Event','Standard Duration Weak Event','Long Duration Moderate Event', $
    'Standard Duration Strong Event','Standard Duration Intense Event','Long Duration Strong Event', $
    'Low Counts','High Baseline','Double peak']

  ;loop over both timescales, both energy bands and all flare events
  for baseline = 0,1 do begin
    for eband = 0,1 do begin
      for event = 0,8 do begin

        ;the number of bins for the event is the duration * the timescale currently under consideration
        nbins = timescale[baseline]*length[event]

        ;randomly generate background counts for 31 (imaging  + background) detectors for all time
        ;bins. a Poisson distribution with expectation dependent on the energy channel currently
        ; being tested is used.
        seed = 1000l
        random_bg = long(randomu(seed, 32l*(preevent+nbins), poisson=background_expectation[eband]))
        random_bg = reform(random_bg, 32, preevent+nbins)

        ;take the median over the imaging detectors
        median_background = long(median(random_bg[0:29,*], dim = 1))


        ;the current counts array is given by a (2 energy bands) * (number of time bins)
        ;array initially set to the expectation values of the background for each energy band.
        ;the background for the energy band currently being tested is then replaced by the more
        ;realistic random distribution
        current_counts = long(rebin(transpose(background_expectation), preevent+nbins,2))
        current_counts[*, eband] = median_background*combine

        total_background =[total_background, median_background/4]

        ;the background estimate for the current event is taken as the remaining
        ;(1 detector * n time bins) values in the random_bg array
        current_background = rebin(transpose(background_expectation),preevent+nbins,2)
        current_background[*, eband] = reform(random_bg[30,*], preevent+nbins)

        ;the characteristics of the current event are determined
        current_max = nbins*max_location[event]
        sigma = timescale[baseline]/10.
        current_peak = peak_counts[event, eband]
        gaussian_pulse = gaussian(findgen(nbins), [current_peak,current_max,sigma] )

        ;the gaussian peak is added to the background in the relevant energy channel
        current_counts[preevent:preevent+nbins-1, eband] += long(gaussian_pulse)

        ;if the current event has an exponential decay profile the counts after the maximum value
        ;are replaced with
        if exp_deacy[event] then begin
          exar = findgen(nbins - current_max)
          exp_constant = -max(exar)/alog(1./current_peak)
          decay_counts = current_peak*exp(-exar/exp_constant) + median_background[preevent+current_max:-1]
          current_counts[preevent+current_max:-1,eband] = long(decay_counts)
        endif

        ;for the event with high baseline the counts before the gaussian peak reaches
        ;half its maximum value are replaced
        if event eq 7 then begin
          mm = min(where(current_counts[*,eband] gt current_peak/2))
          current_counts[0:mm-1,eband] = current_peak/(2l) + median_background[0:mm-1]
        endif

        ;for the event with a double peak the second peak is added using the same parameters as
        ;the first one
        if event eq 8 then begin
          current_max = nbins*0.25
          gaussian_pulse = gaussian(findgen(nbins/2), [current_peak, current_max, sigma] )
          current_counts[preevent + nbins/2: -1, eband] += long(gaussian_pulse)
        endif

        ;if plotting keyword is set plot the lightcurve for the current event
        if keyword_set(plotting) then begin
          if isa(p) then p.erase
          full_title = title_event[event] +': '+ title_eband[eband] +' (' +title_timescale[baseline]+')'
          p = plot(findgen(preevent+nbins), current_counts[preevent:preevent+nbins-1,eband], title = full_title, $
            ytitle = 'Counts in Current Energy Band', xtitle = 'QL Time Bin', /histogram, /current  )
          if keyword_set(save_plots) then begin
            file_title = title_event[event] +'_' + title_eband[eband] +'_'+title_timescale[baseline]
            filename = strjoin(strsplit(file_title, /extract), '_')+'.png'
            p.save,  filename
          endif
          wait,1
        endif

        ;the counts and background for the completed event are added to the full arrays
        full_counts = [full_counts, current_counts]
        full_bg = [full_bg, current_background]
        current_offset = offset[-1] + preevent+nbins
        offset  = [offset, current_offset ]
      endfor
    endfor
  endfor


  ;if plotting keyword is set the flare flag will be calculated for the full time range and
  ;the total counts will be plotted along with whether a flare was determined to be present in chunks of 400
  ;quicklook time bins
  if keyword_set(plotting) then begin
    fd = stx_fsw_flare_detection(full_counts, full_bg,  0l*full_counts[*,0], plotting = plotting)
    det = where(fd gt 0)
    fd[det] = 1
    loadct, 39, /silent
    q = window()

    for baseline = 0,1 do begin
      for eband = 0,1 do begin
        for event = 0,8 do begin
          full_title = title_event[event] +': '+ title_eband[eband] +' (' +title_timescale[baseline]+')'
          i = event + (eband)*9 + (baseline)*18 + 1
          q.erase
          q = plot(findgen(offset[i] - offset[i-1] ) + offset[i-1] +1 , total(full_counts[offset[i-1]+1:offset[i]-1,*],2),/ylog,$
            title = full_title, yrange = [0.1,1d8], ytitle = 'Total Counts', xtitle = 'QL Time Bin' ,/current , xstyle= 1,/histogram  )
          q = plot(findgen(offset[i] - offset[i-1] ) + offset[i-1]+1, fd[offset[i-1]+1:offset[i]-1]*max(total(full_counts[offset[i-1]:offset[i]-1,*],2)/2.)+0.1 $
            , color = 'red', /over, /current ,/histogram )
          if keyword_set(save_plots) then begin
            file_title = title_event[event] +'_'+ title_eband[eband] +'_'+title_timescale[baseline]
            filename = strjoin(strsplit(file_title, /extract), '_')+'_with_detection.png'
            q.save,  filename
          endif
          wait,1
        endfor
      endfor
    endfor

  endif

  background = full_bg
  return, full_counts
end

