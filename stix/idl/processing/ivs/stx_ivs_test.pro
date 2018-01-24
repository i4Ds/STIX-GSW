;  fetch the data from richards simulated data files for stix
;+
; :description:
;   Rhessi to Stix data format converter
; :kewords:
;    histerese: threshold for switching off a shutter or pixelstate
;    plot: do some plotting
;    obj: if set, returns a ssw spectrogram object (use obj->plotman) for plotting
; :params:
;    obs_time: the time interval '2002/02/20 ' + ['11:02:00', '11:12:00']
;    max_count: the maximum number of counts per time bin (over all energies)
;    min_max_t: the minimum and maximum time bin size [0.1,4] in seconds
;
;
; :returns:
;    a hsp_spectrogram structure with total counts per time per energy
;-

pro ivs_test
  
  default, local_path,'' 
  
  plotnr = 1
  
  ;shutter and pixel reduction
  spg = stx_datafetch_rhessi2stix('2002/07/23 ' + ['00:10:00', '00:55:00'],5000, 3000,[0.1,10],histerese=0.5,/plot, local_path=local_path)
  stx_interval_plot, spg, intervals=stx_ivs(spg), plotnr=plotnr++
  
  ;shutter in and out long maximal time bin duration
  spg = stx_datafetch_rhessi2stix('2002/07/23 ' + ['00:10:00', '01:15:00'],45000,1000,[0.1,30],histerese=0.3,/plot, local_path=local_path)
  stx_interval_plot, spg, intervals=stx_ivs(spg), plotnr=plotnr++
  
  ;shutter in 
  spg = stx_datafetch_rhessi2stix('2002/07/23 ' + ['00:10:00', '00:55:00'],600000,6000,[0.1,10],histerese=0.6,/plot, local_path=local_path)
  stx_interval_plot, spg, intervals=stx_ivs(spg), plotnr=plotnr++
  
  spg_enl = stx_datafetch_rhessi2stix('2002/02/20 ' + ['10:10:00', '11:30:00'],50000, 30000,[0.1,10],histerese=0.5,/plot, local_path=local_path)
  stx_interval_plot, spg_enl, intervals=stx_ivs(spg_enl), plotnr=plotnr++
  
  spg_full = stx_datafetch_rhessi2stix('2002/02/20 ' + ['11:00:00', '11:30:00'],50000, 30000,[0.1,10],histerese=0.5,/plot, local_path=local_path)
  stx_interval_plot, spg_full, intervals=stx_ivs(spg_full), plotnr=plotnr++
  
  spg = stx_datafetch_rhessi2stix('2002/02/12 ' + ['21:30:00', '21:42:00'],600000,6000,[0.1,10],histerese=0.6,/plot, local_path=local_path)
  stx_interval_plot, spg, intervals=stx_ivs(spg), plotnr=plotnr++
  
  
  spg = stx_datafetch_rhessi2stix('2003/11/20 ' + ['01:40:00', '02:15:00'],60000, 60000,[0.1,10],histerese=0.5,/plot, local_path=local_path)
  stx_interval_plot, spg, intervals=stx_ivs(spg), plotnr=plotnr++
  
  ;resample the energy axis according to some of the flaretype scienceidx=[0..3]
  
  ;no resample
  ;spg = stx_resample_e_axis(spg,stx_get_flare_energy_class(spg,detail_mode=1))
  
  ;resample to a e-schema for a medium flare
  ;spg = stx_resample_e_axis(spg,stx_energy_axis(scienceidx=3))
  
  
  ;run the interval selection : intervals=stx_ivs(spg)
  ;and plot the result
  
end
