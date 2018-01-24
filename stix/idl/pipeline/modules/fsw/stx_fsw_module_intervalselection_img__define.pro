;+
; :file_comments:
;    This module is part of the Flight Software Simulation (FSW) package and 
;    performs the interval selection on the archive buffer
;
; :categories:
;    Flight Software, interval selection, module
;
; :examples:
;    obj = new_obj('stx_fsw_module_intervalselection_img')
;
; :history:
;    20-Mar-2014 - Nicky Hochmuth (FHNW), initial release
;    10-Jul-2014 - Nicky Hochmuth (FHNW), alter super class to ppl_module_lut and store all  LUT internal until invalidation 
;-


pro stx_fsw_module_intervalselection_img::update_io_data, conf
    ;read the thermal boundary LUT
    
  if self->is_invalid_config("thermal_boundary_lut_file", conf.thermal_boundary_lut_file) then begin  
    thermal_boundary_lut = read_csv(exist(conf.thermal_boundary_lut_file) ? conf.thermal_boundary_lut_file : loc_file( 'stx_ivs_thermal_boundary.lut', path = getenv('STX_IVS') ), n_table_header=3)
    (self.lut_data)["thermal_boundary_lut"] = thermal_boundary_lut.FIELD2
  end
  
  ;read the flare magnitude index LUT
  if self->is_invalid_config("flare_magnitude_index_lut_file", conf.flare_magnitude_index_lut_file) then begin
    flare_magnitude_index_lut = read_csv(exist(conf.flare_magnitude_index_lut_file) ? conf.flare_magnitude_index_lut_file : loc_file( 'stx_ivs_flare_magnitude_index.lut', path = getenv('STX_IVS') ))
    (self.lut_data)["total_flare_magnitude_index_lut"]       = flare_magnitude_index_lut.field2
    (self.lut_data)["thermal_flare_magnitude_index_lut"]     = flare_magnitude_index_lut.field3
    (self.lut_data)["nonthermal_flare_magnitude_index_lut"]  = flare_magnitude_index_lut.field4
  end
  
  ;read the min count LUT
  if self->is_invalid_config("min_count_lut_file", conf.min_count_lut_file) then begin
    min_count_lut = read_csv(exist(conf.min_count_lut_file) ? conf.min_count_lut_file : loc_file( 'stx_ivs_min_count.lut', path = getenv('STX_IVS') ))
    (self.lut_data)["thermal_min_count_lut"]                 = [transpose(min_count_lut.field2), transpose(min_count_lut.field3)]
    (self.lut_data)["nonthermal_min_count_lut"]              = [transpose(min_count_lut.field4), transpose(min_count_lut.field5)]
  end
    
  ;read the min time LUT
  if self->is_invalid_config("min_time_lut_file", conf.min_time_lut_file) then begin
    min_time_lut = read_csv(exist(conf.min_time_lut_file) ? conf.min_time_lut_file : loc_file( 'stx_ivs_min_time.lut', path = getenv('STX_IVS') ))
    (self.lut_data)["thermal_min_time_lut"]                 = min_time_lut.field2
    (self.lut_data)["nonthermal_min_time_lut"]              = min_time_lut.field3
  end
    
  ;read the energy binning LUT
  if self->is_invalid_config("energy_binning_lut_file", conf.energy_binning_lut_file) then begin
    energy_binning_lut = read_csv(exist(conf.energy_binning_lut_file) ? conf.energy_binning_lut_file : loc_file( 'stx_ivs_energy_binning.lut', path = getenv('STX_IVS')),header=col_names)
    (self.lut_data)["energy_binning_lut"] = CREATE_STRUCT(["type",col_names], "stx_ivs_energy_binning_lut" , energy_binning_lut.FIELD1,energy_binning_lut.FIELD2,energy_binning_lut.FIELD3,energy_binning_lut.FIELD4,energy_binning_lut.FIELD5)
  end
    
end

;+
; :description:
;    This internal routine calibrates the accumulator data
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_source_structure object
;         
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the 
;        configuration parameters for this module
;
; :returns:
;   this function returns an array of stx_sim_photon_structure
;-
function stx_fsw_module_intervalselection_img::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  self->update_io_data, conf
  
  ;combine detector mask from config with list of active detectors
  detectors_used = in.active_detectors AND conf.detector_mask 
  
  conf.plotting = 1
  
  return, stx_fsw_ivs_img(in.archive_buffer,  in.start_time, in.rcr, in.rcr_time_axis, $
    total_flare_magnitude_index_lut         = (self.lut_data)["total_flare_magnitude_index_lut"], $
    thermal_flare_magnitude_index_lut       = (self.lut_data)["thermal_flare_magnitude_index_lut"], $
    nonthermal_flare_magnitude_index_lut    = (self.lut_data)["nonthermal_flare_magnitude_index_lut"], $
    thermal_min_count_lut                   = (self.lut_data)["thermal_min_count_lut"], $
    nonthermal_min_count_lut                = (self.lut_data)["nonthermal_min_count_lut"], $
    thermal_min_time_lut                    = (self.lut_data)["thermal_min_time_lut"], $
    nonthermal_min_time_lut                 = (self.lut_data)["nonthermal_min_time_lut"], $
    energy_binning_lut                      = (self.lut_data)["energy_binning_lut"], $
    thermal_boundary_lut                    = (self.lut_data)["thermal_boundary_lut"], $
    detector_mask                           = detectors_used, $
    remove_background                       = conf.remove_background, $
    background                              = in.background, $
    energy_axis_background                  = in.background_energy_axis , $  
    plotting                                = conf.plotting, $
    split_into_rcr_blocks                   = conf.split_into_rcr_blocks, $
    trimming_max_loss                       = conf.trimming_max_loss $
    )
end

;+
; :description:
;    Constructor
;
; :inherits:
;    hsp_module
;
; :hidden:
;-
pro stx_fsw_module_intervalselection_img__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_intervalselection_img, inherits ppl_module_lut }
end
