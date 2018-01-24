;+
; :description:
;    This procedure creates a scenario file for the given RHESSI flare ID using DB RAS developed
;
; :categories:
;    data simulation, software
;
; :keywords:
;    rhessi_flare_id : in, optional, type="long", default="2021213"
;             RHESSI flare id number
;    plot : in, type="boolean", default="0"
;             Create plots
;    no_write : in, type="boolean", default="0"
;             Do not write out scenario file
;             
; :examples:
;    stx_sim_rhessi_flares, rhessi_flare_id=2021213
;
; :history:
;    15-Feb-2017 - Shane Maloney (TCD), initial release
;    13-Mar-2017 - Shane Maloney (TCD), fixed bug
;
; :todo:
; 
;-

pro stx_sim_rhessi_flares, rhessi_flare_id=rhessi_flare_id, plot=plot, no_write=no_write, spec=spec
  default, no_write, 0
  default, rhessi_flare_id, 2021213
  default, plot, 0

  ; Restore DB info and read in RHESSI flare data
  restore, concat_dir(getenv('STX_SIM'), 'stx_counts.sav'), /verbose
  flare_data = hsi_read_flarelist(info=info)

  if plot eq 1 then begin
    orig_pmulti = !P.multi
    window, /free, xs=400, ys=600
    !P.multi=[0, 1, 2]
    data = findgen(2, 2)
    data[*,*]=0.01
    map = make_map(data)
  endif
  
  ; Find corresponding flare location
  flare_index = where(flare_data.id_number eq rhessi_flare_id)
  ;    flare_index = where(flare_data.start_time le entry.ut and flare_data.end_time ge entry.ut)
  if size(flare_index, /n_elements) eq 1  then begin
    flare_location = [flare_data[flare_index].x_position, flare_data[flare_index].y_position]
    flare_start = flare_data[flare_index].start_time
  endif else begin
    multi_flare.add, flare_data[flare_index].id_number
    print, "Error multiple flares found"
  endelse

  ; Extract match times from DB
  current_indexs = where(all.ut ge flare_data[flare_index].start_time and all.ut le flare_data[flare_index].end_time)

  ; STIX energy range
  energy_edges = stx_science_energy_channels(/edges_2)
  energy_mean = stx_science_energy_channels(/mean)

  spectrum = fltarr(n_elements(current_indexs), n_elements(energy_mean))
  ; Output text array
  lines = []

  ; Backgound souce is 0 so start from 1
  source_count = 1

  ; Total termal and power law fluxes for each time step
  thermal_tots = []
  non_thermal_tots = []

  for i=0,n_elements(current_indexs) -1  do begin
    entry = all[current_indexs[i]]
    ; Calculate thermal and non-thermal compnents
    thermal = f_vth(energy_edges, entry.f_vth_par)
    thermal[where(thermal le 1e-20)] = 0.0
    thermal_flux = int_tabulated(energy_mean, thermal)
    non_thermal = f_pow(energy_edges, entry.f_pow_par)
    non_thermal_flux = int_tabulated(energy_mean, non_thermal)

    thermal_tots = [thermal_tots, thermal_flux]
    non_thermal_tots = [non_thermal_tots, non_thermal_flux]

    spectrum[i,*] = thermal + non_thermal

    ; Create STIX scenario format for current time interval
    if thermal_flux gt 0 or non_thermal_flux gt 0 then begin
      ; Common for both thermal and powerlaw
      lines = [lines, string(format='(I0)', source_count)+',0,'+string(i*4, format='(F0)') + ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      ; Thermal source
      if thermal_flux gt 0.0 then begin
        lines = [lines, string(format='(I0)', source_count)+',1,,4,gaussian,' + string(flare_location[0], format='(F0)') + ',' $
          + string(flare_location[1], format='(F0)') + ',' +string(thermal_flux, format='(F0)')+',1,40,20,,,uniform,,,thermal,' $
          + string(entry.f_vth_par[0], format='(F0)')+','+string(entry.f_vth_par[1], format='(F0)')+',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      endif
      ; Non-thermal (power law)
      if non_thermal_flux gt 0.0 then begin
        lines = [lines, string(format='(I0)', source_count)+',2,,4,gaussian,' + string(flare_location[0], format='(F0)') + ',' $
          + string(flare_location[1], format='(F0)') + ','+string(non_thermal_flux, format='(F0)')+',1,20,10,,,uniform,,,powerlaw,' $
          + string(entry.f_pow_par[0], format='(F0)')+','+string(entry.f_pow_par[1], format='(F0)')+',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,']
      endif
      source_count ++
    endif else begin
      print, 'No source at all for this time'
    endelse

  endfor

  ; Add header and background souurce
  lines = ['0,0,0,' + string((i*4), format='(I0)') + ',,,,10,,,,,,uniform,,,uniform,,,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0', lines]
  lines = ['source_id,source_sub_id,start_time,duration,shape,xcen,ycen,flux,distance,fwhm_wd,fwhm_ht,phi,loop_ht,time_distribution,time_distribution_param1,time_distribution_param2,energy_spectrum_type,energy_spectrum_param1,energy_spectrum_param2,background_multiplier,background_multiplier_1, background_multiplier_2,background_multiplier_3,background_multiplier_4,background_multiplier_5,background_multiplier_6,background_multiplier_7,background_multiplier_8,background_multiplier_9,background_multiplier_10,background_multiplier_11,background_multiplier_12,background_multiplier_13,background_multiplier_14,background_multiplier_15,background_multiplier_16,background_multiplier_17,background_multiplier_18,background_multiplier_19,background_multiplier_20,background_multiplier_21,background_multiplier_22,background_multiplier_23,background_multiplier_24,background_multiplier_25,background_multiplier_26,background_multiplier_27,background_multiplier_28,background_multiplier_29,background_multiplier_30,background_multiplier_31,detector_override,pixel_override', lines]

  ; Save to scenario file
  close, 1
  filename = concat_dir(concat_dir(getenv('STX_SIM'), 'scenarios'), 'stx_rhessi_' + string(flare_data[flare_index].id_number, format='(I0)') + '.csv')
  if ~no_write then begin
    openw, 1, filename
    foreach lin, lines do begin
      printf, 1, lin
    endforeach
    close, 1
  endif

  if plot eq 1 then begin
    loadct, 12
    utplot, all[current_indexs].ut-all[current_indexs[0]].ut, thermal_tots, anytim(all[current_indexs[0]].ut, /ccs), $
       title='Total Photons', ytitle='photons s!U-1!N cm!U-2!N', /ylog, yrange=[1, 1e6]
    outplot, all[current_indexs].ut-all[current_indexs[0]].ut, power_tots, color=16*11
    map.time = anytim(all[current_indexs[0]].ut, /ccsds)
    plot_map, map, /LIMB_PLOT, fov=[40]
    plots, flare_location[0], flare_location[1], psym=1
    !P.multi=orig_pmulti
  endif
  
  spec = spectrum

end