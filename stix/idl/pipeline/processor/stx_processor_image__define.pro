;---------------------------------------------------------------------------
; Document name: stx_processor_image__define.pro
; Created by:    nicky.hochmuth 29.08.2012
;---------------------------------------------------------------------------
;+
; PROJECT:    STIX
;
; NAME:       stx_processor_image
;
; PURPOSE:    sticing all modules together for a image pipeline
;       
; CATEGORY:   stix image pipeline
;
; CALLING SEQUENCE:
;                p = stx_image_processor(pxl)
;                vis = p.getVisibilities()
;                ps = p.getPixelSum()
;                p.showMap 
;
;
; HISTORY:
;       29.08.2012 nicky.hochmuth initial release
;
;-

;+
; :description:
;    init a stx_processor_image object
;
; :params:
;    data: STX_PIXEL_DATA
;
; returns 1 if succes
;-
function stx_processor_image::init, data
  self.data = PTR_NEW(data)
  
  ;register all modules for the pipeline
  self.stx_module_sum_over_pixels = stx_module_sum_over_pixels()
  self.stx_module_create_visibilities = stx_module_create_visibilities()
  self.stx_module_interval_selection = stx_module_interval_selection()
  self.stx_module_sum_over_time_energy = stx_module_sum_over_time_energy()
  self.stx_module_coarse_flare_location = stx_module_coarse_flare_location()
  self.stx_module_determine_background = stx_module_determine_background()
  self.stx_module_pixel_e_calibration = stx_module_pixel_e_calibration()
  self.stx_module_pixel_phase_calibration = stx_module_pixel_phase_calibration()
  self.stx_module_create_map = stx_module_create_map()
  
  return, 1
end

;+
; :description:
;    processes all steps in the pipeline until the pixel summary can returned 
;
; :keywords:
;    config   : modul configs
;    history  : pipeline history object 
;    _EXTRA   : additional params
;
; returns a STX_PIXEL_DATA with summed pixels
;-
function stx_processor_image::get, config=config, history=history, _EXTRA=extra
   debug = exist(!DEBUG) ? !DEBUG  : 0
  
  if(~debug) then begin
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
  
  
  history = OBJ_NEW('ppl_history')
  
  config = ppl_config_create_and_merge_extra(CONFIG=config,_EXTRA=extra)
  
  succes = self.stx_module_interval_selection->execute(*(self.data), _intervals, history, configuration=config)
  if tag_exist(extra,'intervals') then return, _intervals
  
  _pixel_data_intervals = {type:'stx_pixel_data_intervals',intervals : _intervals, pixel_data : *(self.data)}
  succes = self.stx_module_sum_over_time_energy->execute(_pixel_data_intervals, _pixel_data, history, configuration=config)
  if tag_exist(extra,'interval_compacted_pixel_data') then return, _pixel_data
  
  succes = self.stx_module_determine_background->execute(_pixel_data, _background, history, configuration=config)
  if tag_exist(extra,'background') then return, _background
  
  succes = self.stx_module_coarse_flare_location->execute(_pixel_data, _cfl, history, configuration=config)
  if tag_exist(extra,'flare_location') then return, _cfl
  
  _pixel_data_correction = {type:'stx_pixel_data_correction',pixel_data : _pixel_data, coarse_flare_location : _cfl, background : _background}
  
  succes = self.stx_module_pixel_e_calibration->execute(_pixel_data_correction, _pixel_data, history, configuration=config)
  if tag_exist(extra,'pixel_e_calibration') then return, _pixel_data
  
  _pixel_data_correction = {type:'stx_pixel_data_correction',pixel_data : _pixel_data, coarse_flare_location : _cfl, background : _background}
  
  succes = self.stx_module_pixel_phase_calibration->execute(_pixel_data_correction, _pixel_data, history, configuration=config)
  if tag_exist(extra,'pixel_phase_calibration') then return, _pixel_data
    
  succes = self.stx_module_sum_over_pixels->execute(_pixel_data, _pixel_data, history, configuration=config)
  if tag_exist(extra,'pixelsums') then return, _pixel_data
  
  succes = self.stx_module_create_visibilities->execute(_pixel_data, _visibilities, history, configuration=config)
  if tag_exist(extra,'visibilities') then return, _visibilities
  
  succes = self.stx_module_create_map->execute(_visibilities, _map, history, configuration=config)
  if tag_exist(extra,'map') then return, _map
  
  return, -1
end

;+
; :description:
;    processes all steps in the pipeline until the pixel summary can returned 
;
; :keywords:
;    config   : modul configs
;    history  : pipeline history object 
;    _EXTRA   : additional params
;
; returns a STX_PIXEL_DATA with summed pixels
;-
function stx_processor_image::getPixelSum, config=config, history=history, _EXTRA=extra
   return,  self->get(config=config, history=history, /pixelsums, _EXTRA=extra)
end

;+
; :description:
;    processes all steps in the pipeline until visibilities can return 
;
; :keywords:
;    config   : modul configs
;    history  : pipeline history object 
;    _EXTRA   : additional params
;
; returns a STX_VISIBILITY_CUBE
;-
function stx_processor_image::getVisibilities, config=config, history=history, _EXTRA=extra
  return,  self->get(config=config, history=history, /visibilities, _EXTRA=extra)
end

pro stx_processor_image::showMap, config=config, history=history, _extra=extra
  
  map = self->get(config=config, history=history, /map, _EXTRA=extra)
  plot_map, map
end


;+
; :description:
;    Sets s new set of STX_PIXEl_DATA
;
; :params:
;    data the new data
;
;-
pro stx_processor_image::setData, data
  destroy, self.data
  self.data = ptr_new(data)
end

;+
; :description:
;    
; returns the STX_PIXEL_DATA
;-
function stx_processor_image::getData
  return, *(self.data)
end


;+
; :description:
;    Cleanup of this class
;-
pro stx_processor_image::cleanup
  destroy, self.data
end

;+
; :description:
;    Constructor
;
; :hidden:
;-
pro stx_processor_image__define
  compile_opt idl2, hidden
  void = { stx_processor_image, $
            stx_module_sum_over_pixels          : obj_new(), $
            stx_module_create_visibilities      : obj_new(), $
            stx_module_interval_selection       : obj_new(), $
            stx_module_sum_over_time_energy     : obj_new(), $
            stx_module_coarse_flare_location    : obj_new(), $
            stx_module_determine_background     : obj_new(), $
            stx_module_pixel_e_calibration      : obj_new(), $
            stx_module_pixel_phase_calibration  : obj_new(), $
            stx_module_create_map               : obj_new(), $
            data : ptr_new()$
         }
end