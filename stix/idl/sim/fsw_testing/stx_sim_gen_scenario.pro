pro stx_sim_gen_scenario

n_d = 32L
n_p = 12L
n_e = 32L
duration=0.1d

inc = 2

n = n_d/inc*n_p/inc*n_e/inc

e_axis = stx_construct_energy_axis()

scenario = { $
  source_id: intarr(n) , $
  source_sub_id: intarr(n) , $
  start_time: dblarr(n) , $
  duration: dblarr(n) , $
  shape: strarr(n) , $
  xcen: strarr(n) , $
  ycen: strarr(n) , $
  flux: intarr(n) , $
  distance: strarr(n) , $
  fwhm_wd: strarr(n) , $
  fwhm_ht: strarr(n) , $
  phi: strarr(n) , $
  loop_ht: strarr(n) , $
  time_distribution: strarr(n) , $
  time_distribution_param1: strarr(n) , $
  time_distribution_param2: strarr(n) , $
  energy_spectrum_type: strarr(n) , $
  energy_spectrum_param1: intarr(n) , $
  energy_spectrum_param2: intarr(n) , $
  background_multiplier: intarr(n) , $
  background_multiplier_1: intarr(n) , $
  background_multiplier_2: intarr(n) , $
  background_multiplier_3: intarr(n) , $
  background_multiplier_4: intarr(n) , $
  background_multiplier_5: intarr(n) , $
  background_multiplier_6: intarr(n) , $
  background_multiplier_7: intarr(n) , $
  background_multiplier_8: intarr(n) , $
  background_multiplier_9: intarr(n) , $
  background_multiplier_10: intarr(n) , $
  background_multiplier_11: intarr(n) , $
  background_multiplier_12: intarr(n) , $
  background_multiplier_13: intarr(n) , $
  background_multiplier_14: intarr(n) , $
  background_multiplier_15: intarr(n) , $
  background_multiplier_16: intarr(n) , $
  background_multiplier_17: intarr(n) , $
  background_multiplier_18: intarr(n) , $
  background_multiplier_19: intarr(n) , $
  background_multiplier_20: intarr(n) , $
  background_multiplier_21: intarr(n) , $
  background_multiplier_22: intarr(n) , $
  background_multiplier_23: intarr(n) , $
  background_multiplier_24: intarr(n) , $
  background_multiplier_25: intarr(n) , $
  background_multiplier_26: intarr(n) , $
  background_multiplier_27: intarr(n) , $
  background_multiplier_28: intarr(n) , $
  background_multiplier_29: intarr(n) , $
  background_multiplier_30: intarr(n) , $
  background_multiplier_31: intarr(n) , $
  detector_override: intarr(n) , $
  pixel_override: intarr(n) $
}

n=0

for e=0, n_e-1, inc do begin
  for d=0, n_d-1, inc do begin
    for p=0, n_p-1, inc do begin
      
       scenario.source_id[n]= 0
       scenario.source_sub_id[n]= n 
       scenario.start_time[n]= n*duration
       scenario.duration[n]= duration
       scenario.flux[n]=50 
       scenario.time_distribution[n]= "uniform"
       scenario.energy_spectrum_type[n]="uniform" 
       scenario.energy_spectrum_param1[n]=e_axis.EDGES_1[e]
       scenario.energy_spectrum_param2[n]=e_axis.EDGES_1[e] 
       scenario.background_multiplier[n]= 1
       scenario.background_multiplier_1[n]=1 
       scenario.background_multiplier_2[n]=1
       scenario.background_multiplier_3[n]=1 
       scenario.background_multiplier_4[n]=1 
       scenario.background_multiplier_5[n]=1 
       scenario.background_multiplier_6[n]=1 
       scenario.background_multiplier_7[n]=1 
       scenario.background_multiplier_8[n]=1 
       scenario.background_multiplier_9[n]=1 
       scenario.background_multiplier_10[n]=1 
       scenario.background_multiplier_11[n]=1 
       scenario.background_multiplier_12[n]=1 
       scenario.background_multiplier_13[n]=1 
       scenario.background_multiplier_14[n]=1 
       scenario.background_multiplier_15[n]=1 
       scenario.background_multiplier_16[n]=1 
       scenario.background_multiplier_17[n]=1 
       scenario.background_multiplier_18[n]=1 
       scenario.background_multiplier_19[n]=1 
       scenario.background_multiplier_20[n]=1 
       scenario.background_multiplier_21[n]=1 
       scenario.background_multiplier_22[n]=1 
       scenario.background_multiplier_23[n]=1 
       scenario.background_multiplier_24[n]=1 
       scenario.background_multiplier_25[n]=1 
       scenario.background_multiplier_26[n]=1 
       scenario.background_multiplier_27[n]=1 
       scenario.background_multiplier_28[n]=1 
       scenario.background_multiplier_29[n]=1 
       scenario.background_multiplier_30[n]=1 
       scenario.background_multiplier_31[n]=1 
       scenario.detector_override[n]=d+1 
       scenario.pixel_override[n]=p+1 
          
       n++
    endfor
  endfor
endfor

  
WRITE_CSV, "D:\Projekte\Stix\STIX_IDL_GIT\stix\dbase\fsw\rnd_seq_testing\AB.csv",scenario, HEADER=STRLOWCASE(TAG_NAMES(scenario))

  
end