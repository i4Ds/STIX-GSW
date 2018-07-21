;+
;
; :description:
;
;      This scenario consists of 6 flare events over both energy bands and baseline durations.
;      Each event starts with a half short baseline duration of only background so at least one
;      condition is reset to 0 between events. The thermal and non-thermal conditions are tested
;      separately with the counts in the energy band not being tested set to a constant value around
;      the expected median.
;
;      The  events have a range of intensities and are also made up of a combination of short Gaussian
;      pulses and longer events with Exponential decay tails. The decay constant of the exponential
;      functions are set so that they reach 1 count per time bin at the end of the event.
;
;      The 3rd and 5th events should not trigger a flare detection. The 3rd as the pre event
;      baseline as the peak is enhanced to a significant fraction of the peak and the 5th
;      counts will not meet the minimum threshold and the
;
;      Table of relevant parameters for each event:
;
;    Event                             Peak Counts         Decay profile     Energy band      Event duration   Peak location
;                                       (/cm2/s)                                                    (s)
;
;    Short Duration Moderate Event       12.00             Exponential       Thermal                36            0.5
;    Long Duration Moderate Event        12.00             Exponential       Non-thermal           180            0.1
;    High Baseline                        1.80             Gaussian          Thermal                72            0.9
;    Standard Duration Weak Event         1.80             Gaussian          Thermal                24            0.5
;    Low Counts                           1.25             Gaussian          Non-thermal            24            0.5
;    Standard Duration Moderate Even      6.00             Exponential       Non-thermal           120            0.1
;
;
; :keywords:
;
;    plotting            : in, optional
;                         if keyword is set lightcurves will be plotted
;    short_timescale_s   : in, optional, default = 24
;                         the short baseline timescale in units of seconds
;    long_timescale_s    : in, optional, default = 120
;                         the long baseline timescale in units of seconds
;
;
; :returns:
;    full_counts an array of counts in the two flare detection energy bands for all 36 simulated events
;
; :examples:
;    fd_counts = stx_flare_detection_test_counts( /plotting)
;
; :history:
;    20-Jul-2018 - ECMD (Graz), initial release
;
;-
function stx_flare_detection_test_counts_short,short_timescale_s =short_timescale_s, long_timescale_s = long_timescale_s, $
  plotting = plotting, save_plots = save_plots
  ;set the timescales in seconds
  default, long_timescale_s,  120l
  default, short_timescale_s,   24l
  default, plotting, 0
  default, save_plots, 0

  timescale_s = [long_timescale_s, short_timescale_s]

  ;convert timescales to 4s quicklook time bins
  timescale = timescale_s/4l

  ;before every event there is a > short time scale / 2 period of only
  ;background to ensure at least one flare flag condition is reset
  preevents = [timescale[0], timescale[1]/2 , timescale[0]/2+timescale[1]/2, timescale[1]/2+4, timescale[1]/2, 4]

  ;empty arrays for the count and background estimates
  full_counts  = []
  full_bg  = []
  offset = [0]

  ;the peak counts for each event in the relevant energy band
  peak_counts = [2e2*0.06, 2e2*0.06,  3e1*0.06,3e1*0.06,1.25, 1e2*0.06]

  length=  [1.5*timescale[1], 1.5*timescale[0],timescale[1]/2+timescale[0]/2, timescale[1] , timescale[1], timescale[0]]

  use_long_timescale = [0,1,0,0,0,1]

  index_timescale = fltarr(n_elements(length))
  index_timescale[use_long_timescale] = 1

  tnt = [0,1,0,0,1,1]


  ;the location of the counts peak as a fraction of the event time
  max_location =[0.5,0.1,0.9,0.5,0.5,0.1]

  ;some events have a slower exponential decay profile these have value exp_deacy = 1
  exp_deacy    = [1,1,0,0,0,1]

  title_timescale = ['Short Timescale','Long Timescale']
  title_eband = ['Thermal', 'Non-thermal']
  title_event = ['Short Duration Moderate Event','Long Duration Moderate Event', $
    'High Baseline','Standard Duration Weak Event','Low Counts', 'Standard Duration Moderate Event']

  ;loop over all flare events
  for event = 0,5 do begin
    eband = tnt[event]
    baseline    = index_timescale[event]
    ;the number of bins for the event is the duration * the timescale currently under consideration
    nbins = long(length[event])
    preevent = preevents[event]
    ;the current counts array is given by a (2 energy bands) * (number of time bins)
    ;array initially set to the expectation values of the background for each energy band.
    ;the background for the energy band currently being tested is then replaced by the more
    ;realistic random distribution
    current_counts = fltarr(preevent+nbins,2)

    ;the characteristics of the current event are determined
    current_max = long(nbins*max_location[event])
    sigma = timescale[baseline]/5.
    current_peak = peak_counts[event]
    gaussian_pulse = gaussian(findgen(nbins), [current_peak,current_max,sigma] )

    ;the gaussian peak is added to the background in the relevant energy channel
    current_counts[preevent:preevent+nbins-1, eband] += gaussian_pulse

    ;if the current event has an exponential decay profile the counts after the maximum value
    ;are replaced with
    if exp_deacy[event] then begin
      exar = findgen(nbins - current_max)
      exp_constant = -max(exar)/alog(0.033/current_peak)
      decay_counts = current_peak*exp(-exar/exp_constant)
      current_counts[preevent+current_max:-1,eband] = decay_counts
    endif

    ;for the event with high baseline the counts before the gaussian peak reaches
    ;half its maximum value are replaced
    if event eq 2 then begin
      mm = min(where(current_counts[*,eband] gt current_peak/2))
      current_counts[0:mm-1,eband] = current_peak/(2l)
    endif

    ;if plotting keyword is set plot the lightcurve for the current event
    if keyword_set(plotting) then begin
      ;if isa(p) then p.erase
      w = window()
      full_title = title_event[event] +': '+ title_eband[eband] +' (' +title_timescale[baseline]+')'
      p = plot(findgen(preevent+nbins), current_counts[preevent:preevent+nbins-1,eband], title = full_title, $
        ytitle = 'Counts in Current Energy Band', xtitle = 'QL Time Bin', /histogram, /current  )
      if keyword_set(save_plots) then begin
        file_title = title_event[event] +'_' + title_eband[eband] +'_'+title_timescale[baseline]
        filename = strjoin(strsplit(file_title, /extract), '_')+'.png'
        p.save,  filename
      endif
      ;  wait,2
    endif

    ;the counts and background for the complete event are added to the full arrays
    full_counts = [full_counts, current_counts]
    current_offset = offset[-1] + preevent+nbins
    offset  = [offset, current_offset ]


  endfor

  full_counts=full_counts[0:-15,*]
  ;if plotting keyword is set the flare flag will be calculated for the full time range and
  ;the total counts will be plotted along with whether a flare was determined to be present in chunks of 400
  ;quicklook time bins
  if keyword_set(plotting) then begin
    ;sd = reform(sd)
    usedflares = findgen(6)
    flare_flag = stx_fsw_flare_detection(full_counts*64, full_counts*0.01,  0l, kb = 30,nbl = timescale_s, plotting = plotting,thermal_cfmin = [36,36], $
      nonthermal_cfmin = [180,180],thermal_kdk =[0.2,0.2],nonthermal_kdk = [0.2,0.2],thermal_krel_rise = [1.5,1.5],nonthermal_krel_rise = [1.,1], $
      thermal_krel_decay = [0.5,0.5],nonthermal_krel_decay =[0.5,0.5])
    det = where(flare_flag gt 0)
    ; flare_flag[det] = 1
    loadct, 39, /silent
    q = window()

  endif

  therm_lon_base_sim = (flare_flag and 3B)
  therm_short_base =(ishft(flare_flag,-2)and 3B)
  nontherm_long_base_sim =(ishft(flare_flag,-4)and 3B)
  nontherm_short_base_sim =(ishft(flare_flag,-6)and 3B)


  return, full_counts
end

