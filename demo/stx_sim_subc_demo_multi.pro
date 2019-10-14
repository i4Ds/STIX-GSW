; Document name: stx_sim_subc_demo_multi.pro
; Created by:    Nicky Hochmuth, 2013/11/05
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_sim_subc_demo_multi
;
; PURPOSE:
;       helper method to run and visualise the grid response simulation by Shaun Bloomfield for multible times and energies
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;       stx_sim_subc_demo_multi
;       
; KEYWORDS:
;       add_attenuator  : flag to add a attenuator state change in the middle of the event
;       time_axis       : a user defined time axis  
;       energy_axis     : a user defined energy axis
; HISTORY:
;       2013/11/05 - Nicky Hochmuth (FHNW), initial release
;       05-nov-2014 - Laszlo I. Etesi (FHNW), fixed spelling
;-

;+
; :description:
;    runs and visualizes the grid response simulation by Shaun Bloomfield .
;    a gaussian point source is simulated with variation in energy and time
;
pro stx_sim_subc_demo_multi, time_axis=time_axis, energy_axis=energy_axis, add_attenuator=add_attenuator, n_time=n_time,  _EXTRA=EXTRA
  default, add_attenuator, 1
  default, n_time, 70
  
  if keyword_set( help ) then begin
    stx_help_doc, 'stx_sim_subc_demo_multi'
    return
  endif
  
  default, time_axis, stx_construct_time_axis(anytim('2013-11-11 11:00')+findgen(n_time)*20)
  ;default, energy_axis, stx_construct_energy_axis(energy_edges=[4,5,6,8,10,15,20,50])
  default, energy_axis, stx_construct_energy_axis()
  
  n_time = n_elements(time_axis.duration)
  n_energy = n_elements(energy_axis.low)
  
  sas = obj_new('stx_analysis_software', stx_configuration_manager(application_name='stx_analysis_software'))
  sas->set, _extra=extra            
  pixeldata = sas->getdata(out_type='stx_raw_pixel_data')          
  
  destroy, sas
  
  spectrogram = replicate(pixeldata,n_time,n_energy)
  
  time_distribution = findgen(n_time)
  time_distribution = (1.2-(abs(time_distribution - n_time/2.)/(n_time/2.)))/10.0
  plot, time_distribution
  
  energy_distribution = alog(40./(findgen(n_energy)+1))
  ;energy_distribution = 10.0 / (findgen(n_energy)+1)
  plot, energy_distribution
  
  for t=0L, n_time-1 do begin
    attenuator  = add_attenuator && t gt n_time*0.35 && t lt n_time*0.65 ? 1 : 0 
    spectrogram[t,*].attenuator_state = attenuator
    for e=0L, n_energy-1 do begin
      spectrogram[t,e].time_range = [time_axis.time_start[t],time_axis.time_end[t]]
      spectrogram[t,e].energy_range = [energy_axis.low[e],energy_axis.high[e]]
      e_correction = attenuator && e lt 15 ? 0.1 : 1.0  
      spectrogram[t,e].counts = (pixeldata.counts * time_distribution[t] * energy_distribution[e]) * e_correction
    endfor
  endfor
  
  sas = obj_new('stx_analysis_software', stx_configuration_manager(application_name='stx_analysis_software'))
  sas->setdata, spectrogram  
  stx_pixel_data_viewer, sas , title='multi sim'
  
end