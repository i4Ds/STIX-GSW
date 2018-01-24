function stx_image::init
  modules = ptrarr(10)
  modules[0] = ptr_new(stx_module_sum_over_pixels())
  modules[1] = ptr_new(stx_module_create_visibilities())
  modules[2] = ptr_new(stx_module_interval_selection())
  modules[3] = ptr_new(stx_module_sum_over_time_energy())
  modules[4] = ptr_new(stx_module_coarse_flare_location())
  modules[5] = ptr_new(stx_module_determine_background())
  modules[6] = ptr_new(stx_module_pixel_e_calibration())
  modules[7] = ptr_new(stx_module_pixel_phase_calibration())
  modules[8] = ptr_new(stx_module_create_map())
  modules[9] = ptr_new(stx_module_detector_simulation())
  return, self->ppl_processor::init(modules, stx_configuration_manager())
end

pro stx_image::cleanup
  self->ppl_processor::cleanup
end

function stx_image::get, _extra=extra
  return, self->ppl_processor::get(_extra=extra)
end

pro stx_image::set, time_interval=time_interval, pixel_data=pixel_data, visibilities=visibilities, sim=sim, _extra=extra
  ; get the number of set input parameter
  no_input = keyword_set(time_interval) + keyword_set(pixel_data) + keyword_set(visibilities) + keyword_set(sim)
  
  ; only allow zero or one input parameter
  if(no_input gt 0) then begin
    if(no_input gt 1) then begin
      message, 'You are only allowed to specify one input parameter: a time interval, pixel data, or visibilities', /continue
      return
    endif else begin
      if(keyword_set(time_interval) && ppl_typeof(time_interval, compareto='string_array')) then self.input_data = ptr_new(time_interval) $
      else if (keyword_set(pixel_data) && ppl_typeof(pixel_data, compareto='stx_pixel_data')) then self.input_data = ptr_new(pixel_data) $
      else if (keyword_set(visibilities) && ppl_typeof(visibilities, compareto='stx_visibility')) then self.input_data = ptr_new(visibilities) $
      else if (keyword_set(sim)) then self.input_data = ptr_new(sim) $
      else begin
        message, 'Input data is invalid, must be one of the following: time interval, pixel data, or visibilities', /continue
        return
      endelse
    endelse
  endif
  
  self->ppl_processor::set, _extra=extra
end

function stx_image::getaxis
  return, self->ppl_processor::getaxis()
end

function stx_image::getdata, visibility=visibility, pixel_data=pixel_data
  ;return, self->ppl_processor::getdata()
  if(~self->get(/debug)) then begin
    ; Do some error handling
    error = 0
    catch, error
    if (error ne 0)then begin
      catch, /cancel
      err = err_state()
      message, err, continue=~debug
      ; DO MANUAL CLEANUP
      return, 0
    endif
  endif
  
  if(~ptr_valid(self.input_data)) then begin
    message, "Could not find any valid input data. Please run 'set' first and give one of the following: time interval, pixel data, or visibilities as input.", /continue
    return, 0
  endif
  
  history = obj_new('ppl_history')
  
  input_data = (*self.input_data)
  
  switch (ppl_typeof(input_data)) of
    'string_array': begin
    
      break
    end
    'int': begin
      success = *(*self.modules)[9]->execute(0, _pixel_data, history, self.configuration)
      pixel_data = _pixel_data
      input_data = _pixel_data
    end
    'stx_pixel_data': begin
      succes = *(*self.modules)[2]->execute(input_data, _intervals, history, self.configuration)
      _pixel_data_intervals = {type:'stx_pixel_data_intervals',intervals : _intervals, pixel_data : input_data}
      succes = *(*self.modules)[3]->execute(_pixel_data_intervals, _pixel_data, history, self.configuration)
      succes = *(*self.modules)[5]->execute(_pixel_data, _background, history, self.configuration)
      succes = *(*self.modules)[4]->execute(_pixel_data, _cfl, history, self.configuration)
      _pixel_data_correction = {type:'stx_pixel_data_correction',pixel_data : _pixel_data, coarse_flare_location : _cfl, background : _background}
      succes = *(*self.modules)[6]->execute(_pixel_data_correction, _pixel_data, history, self.configuration)
      _pixel_data_correction = {type:'stx_pixel_data_correction',pixel_data : _pixel_data, coarse_flare_location : _cfl, background : _background}
      succes = *(*self.modules)[7]->execute(_pixel_data_correction, _pixel_data, history, self.configuration)
      succes = *(*self.modules)[0]->execute(_pixel_data, _pixel_data, history, self.configuration)
      succes = *(*self.modules)[1]->execute(_pixel_data, _visibilities, history, self.configuration)
      visibility = _visibilities
      input_data = _visibilities
    end
    'stx_visibility': begin
      succes = *(*self.modules)[8]->execute(input_data, _map, history, self.configuration)
      break
    end
    else: begin ; TODO change error message
      message, 'A processing error occurred'
    end
  endswitch
  
  return, _map
end

pro stx_image__define
  void = { stx_image, $
    inherits ppl_processor $
  }
end