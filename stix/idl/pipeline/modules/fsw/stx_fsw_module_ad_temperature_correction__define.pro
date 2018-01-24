;+
; :file_comments:
;    stx_fsw_module_ad_temperature_correction is part of the Flight Software Simulator Module (FSW)
;    "Calibrate Event Binning Module".
;
; :categories:
;    Flight Software Simulator, temperature correction, module
;
; :examples:
;    obj = new_obj('stx_fsw_module_ad_temperature_correction')
;
; :history:
;    25-feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    3-July-2015 - richard.schwartz@nasa.gov, rewrote the reader for the
;     temperature correction table. Works with txt (space delimited) or csv files
;    9-July-2015 - ECMD (Graz), changed default in update_io_data to stx_temperature_correction.csv 
;-

;+
; :description:
;    This internal routine executes the actual A/D temperature correction
;    algorithm on the input data
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
;   this function returns temperature corrected stx_sim_detector_eventlist
;-
function stx_fsw_module_ad_temperature_correction::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  self->update_io_data, conf
    
  return, stx_fsw_temperature_correction(in, (self.lut_data)["temperature_correction_table"])
end


pro stx_fsw_module_ad_temperature_correction::update_io_data, conf
    
  ;read in sky vector reference table and corresponding step sizes from file  
  ;curreltly using same reference table as analysis CFL algorithm
  if self->is_invalid_config("temperature_correction_table", conf.temperature_correction_table_file) then begin

    t_file = exist(conf.temperature_correction_table_file) ? conf.temperature_correction_table_file : loc_file( 'stx_temperature_correction.csv', path = getenv('STX_DET') )
    if(~file_exist(t_file)) then message, 'Could not locate temperature correction table file: ' + t_file
;use rd_tfile and not read_col as rd_tfile is perfect for fixed columnar data tables
;works with original txt file or csv file formats
    break_file, t_file, disk, dir, filnam, ext
    delim = stregex( /boolean, /fold, ext, 'csv' ) ? ',' : ' ' ;csv or txt
    tc_table = transpose( rd_tfile( first_char=';', /auto, /conv, delim= delim, t_file ) )
    
    (self.lut_data)["temperature_correction_table"] = tc_table
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
pro stx_fsw_module_ad_temperature_correction__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_ad_temperature_correction, $
    inherits ppl_module_lut }
end
