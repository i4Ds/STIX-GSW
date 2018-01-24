; -----------------------------------------------------------------------------
;+
; :description:
;     HK data reader. Currently generates fake HK data.
;
; :params:
;     none
;
; :keywords:
;instrument mode
;PSU temperature
;IDPU temperature 1
;IDPU temperature 2
;Essential digital 3.3V current
;Essential digital 2.5V current
;Essential digital 1.5V current
;Aspect temperature 1
;Aspect temperature 2
;Aspect temperature 3
;Aspect temperature 4
;Aspect temperature 5
;Aspect temperature 6
;Aspect temperature 7
;Aspect temperature 8
;Aspect temperature 9
;Aspect temperature 10
;Attenuator voltage
;HV PSU voltage 1
;HV PSU voltage 2
;Detectors temperature quarter 1
;Detectors temperature quarter 2
;Detectors temperature quarter 3
;Detectors temperature quarter 4
;Detectors current quarter 1
;Detectors current quarter 2
;Detectors current quarter 3
;Detectors current quarter 4
;IDPU Nominal or Redundant
;Median and Maximum values of live time accumulators, average since last HK packed
;HV regulators on/off
;Summed attenuator currents
;Total motions of attenuator motions
;Currently flagged detectors
;
; modification history:
;     25-Nov-2014 - Marek Steslicki (Wro), initial release
;
;-
; -----------------------------------------------------------------------------
function stx_hk_read_test_data, t_start, t_end, time=time, rcr=rcr, data=data


  

  n_points=1000 ; number of points
  sim_data=fltarr(n_points)
  
  data_lenght=t_end-t_start
  
  characteristic_time=5.d
  
  n_of_functions=(round(abs(randomn(seed,1))*10+1))[0]
  for i=0,n_of_functions-1 do begin
    phase=(randomn(seed,1))[0]*characteristic_time
    period=((randomn(seed,1))[0]+1)*characteristic_time
    while period lt characteristic_time/2. do period=((randomn(seed,1))[0]+1)*characteristic_time
    ;    print,n_elements(sim_data)
    sim_data+=sin(2*!PI*((indgen(n_points)*1.0/n_points)/period+phase))
  endfor
  
  
  if keyword_set(rcr) then begin
    sim_data=7.9*(sim_data-min(sim_data))/(max(sim_data)-min(sim_data))
    sim_data=floor(sim_data)
  endif

  time=((1.d*indgen(n_points))/n_points)*data_lenght+t_start
  
  return,sim_data
  
end


