;+
; :description:
;    This procedure writes a scenario file for the short flare detection test
;    based on stx_sim_rhessi_flares
;
; :history:
;    20-Jul-2018 - ECMD (Graz), initial release
;
;-
pro stx_write_flare_detection_scenario, counts = counts,  scenario_name=scenario_name, plot=plot

  default,  counts , stx_flare_detection_test_counts_short()
  default,scenario_name , 'stx_scenario_flare_detection.csv'

  x = where(counts lt 1./(0.8*32)) ; if less than one count will be generated don't include it in the scenario file
  counts[x] = 0

  sz = size(counts)
  flare_location = [0,0]
  entry = {f_vth_par:[8,16], f_pow_par:[25,50]}

  time_bins = sz[1]

  lines = []

  source_count = 2L

  for i=0,time_bins-1L  do begin
    thermal_counts = counts[i,0]
    non_thermal_counts = counts[i,1]
    if thermal_counts gt 0 or non_thermal_counts gt 0 then begin
      if thermal_counts gt 0.0 then begin
        lines = [lines, '0,'+string(format='(I0)', source_count)+','+string(i*4L, format='(F0)') + ',4,,,,'+string(thermal_counts, format='(F0)')+',,,,,,uniform,,,uniform,' $
          + string(entry.f_vth_par[0], format='(F0)')+','+string(entry.f_vth_par[1], format='(F0)')+',1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0']
      endif
      if non_thermal_counts gt 0.0 then begin
        lines = [lines, '0,'+string(format='(I0)', source_count)+','+string(i*4L, format='(F0)') + ',4,,,,'+string(non_thermal_counts, format='(F0)')+',,,,,,uniform,,,uniform,' $
          + string(entry.f_pow_par[0], format='(F0)')+','+string(entry.f_pow_par[1], format='(F0)')+',1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0']
      endif
      source_count++
    endif

  endfor


  if keyword_set(additional_background) then begin
    ; Add header and background souurces
    lines = ['0,1,0,' + string((i*4L), format='(I0)') + ',,,,0.9375,,,,,,uniform,,,uniform,25,50,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0', lines]
    lines = ['0,0,0,' + string((i*4L), format='(I0)') + ',,,,0.1875,,,,,,uniform,,,uniform,8,16,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0', lines]
  endif


  lines = ['source_id,source_sub_id,start_time,duration,shape,xcen,ycen,flux,distance,fwhm_wd,fwhm_ht,phi,loop_ht,time_distribution,time_distribution_param1,time_distribution_param2,energy_spectrum_type,energy_spectrum_param1,energy_spectrum_param2,background_multiplier,background_multiplier_1, background_multiplier_2,background_multiplier_3,background_multiplier_4,background_multiplier_5,background_multiplier_6,background_multiplier_7,background_multiplier_8,background_multiplier_9,background_multiplier_10,'+ $
    'background_multiplier_11,background_multiplier_12,background_multiplier_13,background_multiplier_14,background_multiplier_15,background_multiplier_16,background_multiplier_17,background_multiplier_18,background_multiplier_19,background_multiplier_20,background_multiplier_21,background_multiplier_22,background_multiplier_23,background_multiplier_24,background_multiplier_25,background_multiplier_26,background_multiplier_27,background_multiplier_28,background_multiplier_29,background_multiplier_30,background_multiplier_31,detector_override,pixel_override', lines]


  filename = concat_dir(concat_dir(getenv('STX_SIM'), 'scenarios'), scenario_name)
  openw, 1, filename
  foreach lin, lines do begin
    printf, 1, lin
  endforeach
  close, 1


end