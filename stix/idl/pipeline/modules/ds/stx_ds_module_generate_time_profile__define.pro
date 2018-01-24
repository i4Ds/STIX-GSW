;+
; :file_comments:
;    This module is part of the Data Simulation (DS) package and
;    generate a time profile.
;
; :categories:
;    Data Simulation, photon simulation, time profile, module
;
; :examples:
;    obj = new_obj('stx_ds_module_generate_time_profile')
;
; :history:
;    01-apr-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi, removed routines that are inherited from ppl_module
;-

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
;   this function returns an array of relative times (double)
;   
; :history:
;   06-May-2014 - Laszlo I. Etesi, removed option to input anything else than long
;-
function stx_ds_module_generate_time_profile::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  time_profile_type = conf.time_profile_type
  time_profile_type_parameter = conf.time_profile_type_parameter
  duration = conf.duration
  
  ; generate time profile
  return, stx_sim_time_distribution(data_granulation=data_granulation, nofelem=in, type=time_profile_type, $
                                    length=duration, param=time_profile_type_parameter) * data_granulation
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
pro stx_ds_module_generate_time_profile__define
  compile_opt idl2, hidden
  
  void = { stx_ds_module_generate_time_profile, $
    inherits ppl_module }
end
