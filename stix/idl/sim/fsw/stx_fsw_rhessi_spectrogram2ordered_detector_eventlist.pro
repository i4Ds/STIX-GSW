;+
; :description:
;    This function takes an flare source structure and a time interval.
;    It runs the grid simulation with the source structure and adds time and energy informations to the photon list.
;
;    The time energy distribution is taken from the rhessi2stix data archive at the given obs_time
;
; :returns: a time ordered stx_sim_detector_eventlist
;
; :keywords:
;    obs_time:     in, optional, type="double(2)", default="anytim('20-Feb-2002 '+['11:04:08','11:15:00'])"
;                  observing time interval for the rhessi2Stix data archive
;
;    src_struct    in, optional, type="stx_sim_source_structure", default=" tx_sim_source_structure()"
;                  the constant flare struct for the event to simulate
;
;    plotting      in, optional, type=flar, default=0
;                  do some plotting
;                  
; :author:
;    ??-???-???? - ???, initial release
;    28-Jul-2014 - Laszlo I. Etesi (FHNW), using new __define for named structures
;
;-
function stx_fsw_rhessi_spectrogram2ordered_detector_eventlist, $
    obs_time = obs_time, $
    src_struct = src_struct, $
    photoncount=photoncount, $
    plotting=plotting, $
    dist_out = dist_out
    
    
    
  default, plotting, 0
  default, obs_time, anytim('20-Feb-2002 '+['11:04:08','11:15:00'])
  default, src_struct, stx_sim_source_structure()
  
  ph_list = stx_sim_flare( src_struct = src_struct)
  
  spg = stx_datafetch_rhessi2stix(obs_time,500000000L, 300000000L,[4,4], histerese=0.5, plotting=plotting)
  spg_data = spg->get(/spectro)
  
  dist_out = spg_data
  
  default, photoncount, n_elements(ph_list)
  
  energy_times = stx_rand_mc_time_energy(photoncount, spectrogram=spg_data, max_time=src_struct.duration, plotting=plotting)
  
  ;expand the photon list
  if  photoncount gt n_elements(ph_list) then begin
    ph_list = reproduce(ph_list,ceil(photoncount/float(n_elements(ph_list))))
    ph_list = reform(ph_list,n_elements(ph_list))
  end
  
  ph_list = ph_list[0:photoncount-1]
  
  ph_list.time = energy_times[*,1]
  ph_list.energy = energy_times[*,0]
  
  ph_list = ph_list[sort(ph_list.time)]
  
  ph_hits = stx_sim_detector_hit(ph_list)
  
  events = replicate({stx_sim_detector_event},n_elements(ph_hits))
  
  events.relative_time = ph_hits.time
  events.detector_index = ph_hits.subc_d_n
  events.pixel_index = ph_hits.pixel_n
  events.energy_ad_channel = stx_sim_energy2ad_channel(ph_hits.energy)
  
  return, stx_construct_sim_detector_eventlist(start_time=0, detector_events=events, sources=src_struct)
  
end