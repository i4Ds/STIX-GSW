;---------------------------------------------------------------------------
; Document name: hsp_spectrogram.pro
; Created by:    Laszlo I. Etesi, 2011/02/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       Stix spectrogram structure
;
; PURPOSE:
;       Data exchange structure for the imaging pipeline "from pixel to image"
;
; CATEGORY:
;       Stix data exchange
;
; CALLING SEQUENCE:
;       structure = stx_pixel_data(keywords...)
;
; HISTORY:
;       2012/07/20, nicky.hochmuth@fhnw.ch, initial release

;-

;+
; :description:
;    This helper method creates a structure 'stx_pixel_data'
;    containing the pixel data with its time, live_time and energy axis
;
; :params:
;-
function stx_construct_pixel_data, live_time=live_time, time_range=time_range, energy_range=energy_range, counts=counts, attenuator_state=attenuator_state, from_stx_fsw_pixel_data=from_stx_fsw_pixel_data
  
  ;grouped input
  if isa(from_stx_fsw_pixel_data, "list") then begin
    all_intervals = list()
    foreach groupe, from_stx_fsw_pixel_data, index do all_intervals->add, groupe.intervals, /extract, /no_copy 
    from_stx_fsw_pixel_data = all_intervals.toarray()
  end
  
  if keyword_set(from_stx_fsw_pixel_data) AND ppl_typeof(from_stx_fsw_pixel_data, compareto="stx_fsw_pixel_data", /raw) then begin
    
    pixel_data = replicate(stx_pixel_data(),n_elements(from_stx_fsw_pixel_data))
    
    ;TODO N.H. handle live_time
    ;pixel_data.live_time = live_time
    ;TODO N.H. handle attenuator state
    ;pixel_data.attenuator_state = attenuator_state
    
    pixel_data.time_range[0] = stx_time_add(time_range,  seconds=from_stx_fsw_pixel_data.RELATIVE_TIME_RANGE[0])
    pixel_data.time_range[1] = stx_time_add(time_range,  seconds=from_stx_fsw_pixel_data.RELATIVE_TIME_RANGE[1])
    
    e_axis = stx_construct_energy_axis()
    
    pixel_data.energy_range[0] = e_axis.low[from_stx_fsw_pixel_data.ENERGY_SCIENCE_CHANNEL_RANGE[0]]
    pixel_data.energy_range[1] = e_axis.low[from_stx_fsw_pixel_data.ENERGY_SCIENCE_CHANNEL_RANGE[1]]
     
    
    ;todo hack change sort order
    dim = size(pixel_data.counts)
    
    for d=0L, dim[1]-1 do $
      for e=0L, dim[2]-1 do $
        for t=0L, dim[3]-1 do pixel_data[t].counts[d,e] = from_stx_fsw_pixel_data[t].counts[e,d]
    
    ;pixel_data.counts = from_stx_fsw_pixel_data.counts
    
    return, pixel_data
  end  
  
  
  
  
  pixel_data = stx_pixel_data()
  
  if keyword_set(live_time) then pixel_data.live_time = live_time
  if keyword_set(time_range) then pixel_data.time_range = time_range
  if keyword_set(energy_range) then pixel_data.energy_range = energy_range
  if keyword_set(counts) then pixel_data.counts = counts
  if keyword_set(attenuator_state) then pixel_data.attenuator_state = attenuator_state
  
  return, pixel_data
end

