function stx_analysis_software::init, configuration_manager
  default, configuration_manager, stx_configuration_manager(application_name='stx_analysis_software')
  ; asw is not yet state ready, temporary workaround
  ; TODO: introduce state
    internal_state = { $
    type: 'stx_asw_internal_state' $
    }
  success = self->ppl_processor::init(configuration_manager, internal_state)
  self.data_collection = stx_time_energy_bin_collection()
  return, 1 && success
end

pro stx_analysis_software::cleanup
  self->ppl_processor::cleanup
  destroy, self.data_collection
end

pro stx_analysis_software::set, _extra=extra
  self->ppl_processor::set, _extra=extra
end

function stx_analysis_software::get, _extra=extra
  return, self->ppl_processor::get(_extra=extra)
end

pro stx_analysis_software::setdata, input_data, replace=replace, _extra=extra
  default, replace, 1b

  input_data_type = ppl_typeof(input_data,/raw)
  
  if replace then self.data_collection->remove, /all, type=input_data_type
  
  self.data_collection->add, input_data
end

function stx_analysis_software::getdata, input_data=input_data, out_type=out_type, reprocess=reprocess, time=time, energy=energy, skip_ivs=skip_ivs, _extra=extra
  ; setting defaults
  default, reprocess, 0
  default, debug, 0
  default, all_bins, 1
  default, skip_ivs, 0
  
  if(reprocess && keyword_set(out_type)) then begin
    self.data_collection->remove, /all, type=out_type
  endif 
;TODO: n.h check this again
;  else begin
;    if(reprocess || keyword_set(input_data)) then begin
;      destroy, self.image
;      destroy, self.pixel_data
;      destroy, self.raw_pixel_data
;      destroy, self.pixel_data_summed
;      destroy, self.visibility
;    endif
;  endelse
  
  if keyword_set(input_data) then self->setdata, input_data
  
  max_reprocess_level = (self->get(module="global")).max_reprocess_level

  _history = ppl_history()
  
  switch (out_type) of ; 
    'range': begin ; 
        return, self.data_collection->get_boundingbox()
        break
      end
    'stx_raw_pixel_data': begin ; fake for now
      stx_raw_pixel_data = self.data_collection->select(time=time,energy=energy, type="stx_raw_pixel_data",count_matches=count_matches)
      if(count_matches eq 0 AND max_reprocess_level le 2) then begin
        sim_mod = stx_module_detector_simulation()
        success = sim_mod->execute(0, stx_raw_pixel_data, _history, (*(self.internal_state)).configuration_manager)
        if(~success) then begin
          message, 'The detector simulation failed. Please try again', continue=~debug
          return, !NULL
        endif
        ; assign data
        input_data = stx_raw_pixel_data ; quickfix
        self.data_collection->add, stx_raw_pixel_data      
      endif
      return, stx_raw_pixel_data
      break
    end
    'stx_pixel_data': begin
      ;todo is it valid to run the inv only on a subset of raw bins?
      stx_pixel_data = self.data_collection->select(time=time,energy=energy, type="stx_pixel_data", count_matches=count_matches)
      if(count_matches eq 0  AND max_reprocess_level le 3) then begin
        ; go get or calculate raw data if necessary (simulated for now)
        stx_raw_pixel_data = self->getdata(out_type='stx_raw_pixel_data',time=time,energy=energy, /all, _extra=extra)
        
        if n_elements(stx_raw_pixel_data) gt 1 then begin
          isa_mod = stx_module_interval_selection()
          success = isa_mod->execute(stx_raw_pixel_data, _intervals, _history, (*(self.internal_state)).configuration_manager)
          image_intervals = where(_intervals.SPECTROSCOPY eq 0, count_image_intervals)
          if count_image_intervals gt 0 then  _intervals = _intervals[image_intervals] 
         
          if(~success) then begin
            message, 'The interval selection failed. Please try again', continue=~debug
            return, !NULL
          endif
          
          _pixel_data_intervals = { $
            type : 'stx_pixel_data_intervals', $
            intervals : _intervals, $
            raw_pixel_data : stx_raw_pixel_data $
          }
          
          sote_mod = stx_module_sum_over_time_energy()
          success = sote_mod->execute(_pixel_data_intervals, stx_pixel_data, _history, (*(self.internal_state)).configuration_manager)
          if(~success) then begin
            message, 'The sum over time and energy failed. Please try again', continue=~debug
            return, !NULL
          endif
        end else begin
          ;TODO: nh resolve quickfix for skipping the interval selection if we only have a single pixel data
          if ~skip_ivs then return, !NULL
          stx_pixel_data = stx_raw_pixel_data
          stx_pixel_data.type = "stx_pixel_data"
        end  
        ;store the result
        self.data_collection->add, stx_pixel_data
        
      endif
      return, stx_pixel_data
      break
    end
    'stx_pixel_data_summed': begin
       stx_pixel_data_summed = self.data_collection->select(time=time,energy=energy, type="stx_pixel_data_summed",count_matches=count_matches)
       if(count_matches eq 0  AND max_reprocess_level le 4) then begin
        ; go get or calculate pixel data if necessary
        stx_pixel_data = self->getdata(out_type='stx_pixel_data',  time=time, energy=energy, skip_ivs=skip_ivs, _extra=extra)
        
        if ~isa(stx_pixel_data) then return, !NULL
               
;        bg_mod = stx_module_determine_background()
;        success = bg_mod->execute(stx_pixel_data, _background, _history, (*(self.internal_state)).configuration_manager)
;        if(~success) then begin
;          message, 'The background determination failed. Please try again', continue=~debug
;          return, !NULL
;        endif        
        
;        cfl_mod = stx_module_coarse_flare_location()
;        success = cfl_mod->execute(stx_pixel_data, _cfl, _history, (*(self.internal_state)).configuration_manager)
;        if(~success) then begin
;          message, 'The coarse flare location failed. Please try again', continue=~debug
;          return, !NULL
;        endif
                
;        pec_mod = stx_module_pixel_e_calibration()
;        success = pec_mod->execute(_pixel_data_correction, _pixel_data, _history, (*(self.internal_state)).configuration_manager)
;        if(~success) then begin
;          message, 'The pixel energy calibration failed. Please try again', continue=~debug
;          return, !NULL
;        endif

;        ppc_mod = stx_module_pixel_phase_calibration()
;        success = ppc_mod->execute(_pixel_data_correction, _pixel_data, _history, (*(self.internal_state)).configuration_manager)
;        if(~success) then begin
;          message, 'The pixel phase calibration failed. Please try again', continue=~debug
;          return, !NULL
;        endif
        
        sop_mod = stx_module_sum_over_pixels()
        success = sop_mod->execute(stx_pixel_data, stx_pixel_data_summed, _history, (*(self.internal_state)).configuration_manager)
        if(~success) then begin
          message, 'The summation over pixels failed. Please try again', continue=~debug
          return, !NULL
        endif 
        
        ;stx_pixel_data_summed.coarse_flare_location = _cfl
        ;stx_pixel_data_summed.background = _background
       
                 
        ;store the result
        self.data_collection->add, stx_pixel_data_summed
      endif
      return, stx_pixel_data_summed
      break
    end
    'stx_visibility': begin
      stx_visibility = self.data_collection->select(time=time,energy=energy, type="stx_visibility_bag",count_matches=count_matches)
      if(count_matches eq 0  AND max_reprocess_level le 5) then begin
        ; go get or calculate summed pixels if necessary
         stx_pixel_data_summed = self->getdata(out_type='stx_pixel_data_summed',  time=time, energy=energy, skip_ivs=skip_ivs, _extra=extra)
        
        if ~isa(stx_pixel_data_summed) then return, !NULL
        
        cv_mod = stx_module_create_visibilities()
        success = cv_mod->execute(stx_pixel_data_summed, _visibilities, _history, (*(self.internal_state)).configuration_manager)
        
        if(~success) then begin
          message, 'The visibility calculation failed. Please try again', continue=~debug
          return, !NULL
        endif
        
        calib_mod = stx_module_calibrate_visibilities()
        success = calib_mod->execute(_visibilities, stx_visibility, _history, (*(self.internal_state)).configuration_manager)

        if(~success) then begin
          message, 'The visibility calibration failed. Please try again', continue=~debug
          return, !NULL
        endif
        
        ;store the result
        self.data_collection->add, stx_visibility
      endif
      return, stx_visibility
      break
    end
    'stx_spectrogram': begin
      message, 'Not yet implemented', continue=~debug
      return, !NULL
      break
    end
    'stx_spectra': begin
      message, 'Not yet implemented', continue=~debug
      return, !NULL
      break
    end
    'stx_image': begin
       stx_image = self.data_collection->select(time=time,energy=energy, type="stx_image",count_matches=count_matches)
      if(count_matches eq 0  AND max_reprocess_level ge 0) then begin
        ; go get or calculate the visibility if necessary
         stx_visibility = self->getdata(out_type='stx_visibility', time=time, energy=energy, skip_ivs=skip_ivs, _extra=extra)
        
        if ~isa(stx_visibility) then return, !NULL
        
        cm_mod = stx_module_create_map()
        success = cm_mod->execute(stx_visibility, stx_image, _history, (*(self.internal_state)).configuration_manager)
        
        if(~success) then begin
          message, 'The image reconstruction failed. Please try again', continue=~debug
          return, !NULL
        endif
        
        ;store the result
        self.data_collection->add, stx_image
      endif
      return, stx_image
      break
    end
    else: begin
      message, 'Unrecognized type', continue=~debug
    end
  endswitch
end

pro stx_analysis_software::display, data=data
  switch (ppl_typeof(data)) of
    'stx_pixel_data': begin
    
      break
    end ; etc.
    else: begin
    end
  endswitch
  
end

pro stx_analysis_software__define
  void = { stx_analysis_software, $
    data_collection : obj_new(), $ ; internal data collection object
    inherits ppl_processor $
  }
end

