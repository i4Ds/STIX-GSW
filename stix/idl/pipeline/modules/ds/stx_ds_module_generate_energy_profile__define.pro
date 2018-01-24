;+
; :file_comments:
;    This module is part of the Data Simulation (DS) package and
;    generate an energy profile.
;
; :categories:
;    Data Simulation, photon simulation, module
;
; :examples:
;    obj = new_obj('stx_ds_module_generate_energy_profile')
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
;   this function returns an array of energies
;-
function stx_ds_module_generate_energy_profile::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  energy_profile_type = conf.energy_profile_type
  
  if(ppl_typeof(in, compareto='long')) then nofelem=in $
  else nofelem = n_elements(in)
  
  ; generate energy profile
  return, stx_sim_energy_distribution(nofelem=nofelem, type=energy_profile_type) 
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
pro stx_ds_module_generate_energy_profile__define
  compile_opt idl2, hidden
  
  void = { stx_ds_module_generate_energy_profile, $
    inherits ppl_module }
end
