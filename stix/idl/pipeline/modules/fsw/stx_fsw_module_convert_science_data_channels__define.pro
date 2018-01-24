;+
; :file_comments:
;    stx_fsw_module_ad_temperature_correction is part of the Flight Software Simulator Module (FSW)
;    "Calibrate Event Binning Module".
;
; :categories:
;    Flight Software Simulator, conversion, module
;
; :examples:
;    obj = stx_fsw_module_convert_science_data_channels()
;
; :history:
;    25-feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    22-apr-2014 - Richard Schwartz, read energy science bin table using rd_tfile
;     also changing downstream program because table order changed from detector, pixel, edge to edge, pixel, detector
;    9-July-2015 - ECMD (Graz), changed default in update_io_data to ad_energy_table.csv
;    
;-


;+
; :description:
;    This internal routine converts the original A/D channels to science channels
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;        this is a stx_sim_detector_eventlist object
;         
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the 
;        configuration parameters for this module
;
; :returns:
;   this function returns a stx_sim_calibrated_detector_eventlist
;-
function stx_fsw_module_convert_science_data_channels::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  self->update_io_data, conf
  
  return, stx_fsw_science_energy_application(in, (self.lut_data)["science_channel_conversion_table"])  
end

pro stx_fsw_module_convert_science_data_channels::update_io_data, conf
    

  if self->is_invalid_config("science_channel_conversion_table", conf.science_channel_conversion_table_file) then begin

    scc_file = exist(conf.science_channel_conversion_table_file) ? conf.science_channel_conversion_table_file : loc_file( 'ad_energy_table.csv', path = getenv('STX_DET') )
    if(~file_exist(scc_file)) then message, 'Could not locate science channel conversion table file: ' + scc_file
   
   tbl = stx_energy_lut_get( ad_energy_filename = scc_file, /reset, /full )
    
    (self.lut_data)["science_channel_conversion_table"] = tbl
  end
  
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
pro stx_fsw_module_convert_science_data_channels__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_convert_science_data_channels, $
    inherits ppl_module_lut }
end
