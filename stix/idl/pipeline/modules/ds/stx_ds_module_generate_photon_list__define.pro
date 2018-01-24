;+
; :file_comments:
;    This module is part of the Data Simulation (DS) package and
;    generates a list of photon events for a given source.
;
; :categories:
;    Data Simulation, photon simulation, module
;
; :examples:
;    obj = new_obj('stx_ds_module_generate_photon_list')
;
; :history:
;    28-Feb-2014 - Laszlo I. Etesi (FHNW), initial release
;    06-May-2014 - Laszlo I. Etesi, removed routines that are inherited from ppl_module
;    28-Jul-2014 - Laszlo I. Etesi, moved background input to "in"
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
;   this function returns an array of stx_sim_photon_structure
;-
function stx_ds_module_generate_photon_list::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  subc_file = conf.subc_file
  
  ph_list = stx_sim_flare(src_struct=in.sources, bkg_flux=in.bkg_flux, bkg_duration=in.bkg_duration, subc_file=subc_file)
  
  return, ph_list
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
pro stx_ds_module_generate_photon_list__define
  compile_opt idl2, hidden
  
  void = { stx_ds_module_generate_photon_list, $
    inherits ppl_module }
end
