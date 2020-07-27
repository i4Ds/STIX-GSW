;+
; :description:
;    This procedure creates a scenario file from an OSPEX object containing f_vth+f_1pow fits to RHESSI data
;    based on stx_sim_rhessi_flares
;
; :categories:
;    data simulation, spectrogram
;
; :keywords:
;
;
; :examples:
;
;   stx_sim_rhessi_fit
;
; :history:
;
;       03-Dec-2018 – ECMD (Graz), initial release
;
;-
pro stx_sim_rhessi_fit, fit_results,  rhessi_flare_id=rhessi_flare_id, plot=plot, no_write=no_write, spec=spec, scenario_name = scenario_name, $
  all_params =all_params, utvals =utvals, tntmask = tntmask, flare_start=flare_start, preflare= preflare

  default, no_write, 0
  default, rhessi_flare_id, 2021213
  default, plot, 0
  default, preflare, 64
  default, postflare, 64

  !p.multi = 0
  ut = fit_results.spex_summ_time_interval

  if plot eq 1 then begin
    orig_pmulti = !P.multi
    set_plot,'x'
    window, /free, xs=400, ys=600
    windex = !d.window
    wdelete,windex
    !P.multi=[0, 1, 2]
    data = findgen(2, 2)
    data[*,*]=0.01
    map = make_map(data)
  endif

  ; Find corresponding flare location
  flare_location = fit_results.SPEX_SUMM_SOURCE_XY
  flare_start = ut[0,0]


  ; Extract match times from DB
  current_indexs = where(fit_results.SPEX_SUMM_CHISQ lt 50l)

  powll = where((fit_results.spex_summ_params)[3,*] - 3.*(fit_results.spex_summ_sigmas)[3,*] gt 1e-5    and fit_results.spex_summ_free_mask[3,*] eq 1  )

  pomask = fltarr(n_elements((fit_results.SPEX_SUMM_PARAMS)[3,*]))

  pomask[powll] = 1

  ; STIX energy range
  energy_edges = stx_science_energy_channels(/edges_2)
  energy_mean = stx_science_energy_channels(/mean)


  spectrum = fltarr(n_elements(current_indexs), 146)
  tntmask = fltarr(n_elements(current_indexs), 2)
  utu = ut[*,current_indexs]


  ; Output text array
  lines = []

  ; Background source is 0 so start from 1
  source_count = 1

  ; Total thermal and power law fluxes for each time step
  thermal_tots = []
  non_thermal_tots = []
  all_params = []

  for i=0,n_elements(current_indexs) -1  do begin
    par =  [(fit_results.SPEX_SUMM_PARAMS)[*, current_indexs[i]]]
    ; Calculate thermal and non-thermal compnents
    ee = findgen(147)+4
    thermal = f_vth(ee, par[0:1])
    thermal[where(thermal le 1e-20)] = 0.0
    thermal_flux =  total(thermal)
    non_thermal = f_pow(ee, par[3:4])

    non_thermal_flux = total(non_thermal)
    if pomask[current_indexs[i]] eq 0 then non_thermal_flux = 0

    current_params = [transpose([par[0:1],par[3:4]] )]

    all_params = [all_params, current_params]
    thermal_tots = [thermal_tots, thermal_flux]
    non_thermal_tots = [non_thermal_tots, non_thermal_flux]

    spectrum[i,*] = thermal + non_thermal

    ; Create STIX scenario format for current time interval
    if thermal_flux gt 1 or non_thermal_flux gt 1 then begin
      ; Common for both thermal and powerlaw
      lines = [lines, string(format='(I0)', source_count)+',0,'+string(i*12+preflare, format='(F0)') + ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      ; Thermal source
      if thermal_flux gt 1 then begin
        tntmask[i,0]=1
        lines = [lines, string(format='(I0)', source_count)+',1,,12,gaussian,' + string(flare_location[0], format='(F0)') + ',' $
          + string(flare_location[1], format='(F0)') + ',' +string(thermal_flux, format='(F0)')+',1,40,20,,,uniform,,,thermal,' $
          + string(par[0], format='(F0)')+','+string(par[1], format='(F0)')+',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      endif
      ; Non-thermal (power law)
      if non_thermal_flux gt 1 then begin
        tntmask[i,1]=1
        lines = [lines, string(format='(I0)', source_count)+',2,,12,gaussian,' + string(flare_location[0], format='(F0)') + ',' $
          + string(flare_location[1], format='(F0)') + ','+string(non_thermal_flux, format='(F0)')+',1,20,10,,,uniform,,,powerlaw,' $
          + string(par[3], format='(F0)')+','+string(par[4], format='(F0)')+',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      endif
      source_count ++
    endif else begin
      print, 'No source at all for this time'
    endelse

  endfor

  ; Add header and background souurce
  lines = ['0,0,0,' + string((i*12+preflare+postflare), format='(I0)') + ',,,,4,,,,,,uniform,,,bkg_continuum,,,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0', lines]
  lines = ['source_id,source_sub_id,start_time,duration,shape,xcen,ycen,flux,distance,fwhm_wd,fwhm_ht,phi,loop_ht,time_distribution,time_distribution_param1,time_distribution_param2,energy_spectrum_type,energy_spectrum_param1,energy_spectrum_param2,background_multiplier,background_multiplier_1, background_multiplier_2,background_multiplier_3,background_multiplier_4,background_multiplier_5,background_multiplier_6,background_multiplier_7,background_multiplier_8,background_multiplier_9,background_multiplier_10,background_multiplier_11,background_multiplier_12,background_multiplier_13,background_multiplier_14,background_multiplier_15,background_multiplier_16,background_multiplier_17,background_multiplier_18,background_multiplier_19,background_multiplier_20,background_multiplier_21,background_multiplier_22,background_multiplier_23,background_multiplier_24,background_multiplier_25,background_multiplier_26,background_multiplier_27,background_multiplier_28,background_multiplier_29,background_multiplier_30,background_multiplier_31,detector_override,pixel_override', lines]

  ; Save to scenario file
  close, 1
  scenario_name = 'stx_rhessi_' + string(rhessi_flare_id, format='(I0)')
  filename = concat_dir(concat_dir(getenv('STX_SIM'), 'scenarios'), scenario_name+ '.csv')
  if ~no_write then begin
    openw, 1, filename
    foreach lin, lines do begin
      printf, 1, lin
    endforeach
    close, 1
  endif

  edges = [4, 7, 11, 16, 40, 150]
  a = value_locate(ee, edges)
  sp = fltarr(i, 5)
  for k = 0, 4 do sp[*, k] = total(spectrum[*, a[k]:a[k+1]-1],2)

  thermal_tots[where(thermal_tots lt 1)]  = 0
  non_thermal_tots[where(non_thermal_tots lt 1)]  = 0

  if plot eq 1 then begin
    filename = scenario_name + '_input_flare.eps'
    !p.thick = 4
    !x.thick = 4
    !y.thick = 4
    !p.charthick = 2
    ps_on, filename=filename
    loadct, 12
    utplot, ut[0,current_indexs]-ut[0,current_indexs[0]], thermal_tots, anytim(ut[0,current_indexs[0]], /ccs), $
      title='Total Photons', ytitle='photons s!U-1!N cm!U-2!N', /ylog, yrange=[1,1e6], psym = 10, /xst
    outplot, ut[0,current_indexs]-ut[0,current_indexs[0]], non_thermal_tots, color=16*11, psym = 10

    map.time = anytim(ut[0,current_indexs[0]], /ccsds)
    plot_map, map, /LIMB_PLOT, fov=[40]
    plots, flare_location[0], flare_location[1], psym=1
    !P.multi=orig_pmulti
    !p.thick = 1
    device, /close

    !p.thick = 6
    !x.thick = 6
    !y.thick = 6
    !p.charthick = 3
    linecolors
    filename = scenario_name + '_input_lightcurve.eps'
    device, filename=filename, xsize=20,ysize=12,/color,/encapsulated,/AVANTGARDE,/bold,/ISOLATIN1

    utplot, ut[0,current_indexs]-ut[0,current_indexs[0]], sp[*,0],  anytim(ut[0,current_indexs[0]], /ccs), $
      title='Total Photons', ytitle='photons s!U-1!N cm!U-2!N', /ylog, yrange=[1e-2,1e8],  XMARGIN = [11, 3], psym = 10, /xst
    for k = 0, 4 do outplot,ut[0,current_indexs]-ut[0,current_indexs[0]], sp[*,k], color=k, psym = 10
    device, /close

    ps_off
    !p.thick = 1
    !x.thick = 1
    !y.thick = 1
    !p.charthick = 1

  endif

  utvals = ut[0,current_indexs]-ut[0,current_indexs[0]]+preflare


  spec = spectrum

end
