;+
; :file_comments:
;    this file contains the detector simulation module
;
; :categories:
;    pipeline, simulation, detector
;
; :properties:
;    module
;      
;    input_type
;    
;    configfile
;
; :examples:
;    module = stx_module_detector_simulation()
;    module->execute(in, out, history, configuration=configuration)
;
; :history:
;    07-May-2013 - Laszlo I. Etesi (FHNW), initial release
;    05-Nov-2013 - Shaun Bloomfield (TCD), modified configuration
;                  and output formats for call to stx_sim_flare.pro
;-

function stx_module_detector_simulation::init, module, input_type
  ret = self->ppl_module::init(module, input_type)
  if ret then begin  
    return, 1
  end
  return, ret
end

function stx_module_detector_simulation::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  ; bugfix for ssw compatibility, introduced v0r3, temporary
  subc_file    = conf.subc_file
  src_shape    = conf.src_shape
  src_xcen     = conf.src_xcen
  src_ycen     = conf.src_ycen
  src_duration = conf.src_duration
  src_flux     = conf.src_flux
  src_distance = conf.src_distance
  src_fwhm_wd  = conf.src_fwhm_wd
  src_fwhm_ht  = conf.src_fwhm_ht
  src_phi      = conf.src_phi
  src_loop_ht  = conf.src_loop_ht
  src_spectra  = conf.src_spectra
  bkg_flux     = conf.bkg_flux
  bkg_duration = conf.bkg_duration
  
  ph_list = stx_sim_flare( src_shape = src_shape, src_xcen = src_xcen, src_ycen = src_ycen, $
                           src_duration = src_duration, src_flux = src_flux, src_distance = src_distance, $
                           src_fwhm_wd = src_fwhm_wd, src_fwhm_ht = src_fwhm_ht, src_phi = src_phi, $
                           src_loop_ht = src_loop_ht, src_spectra = src_spectra, bkg_flux = bkg_flux, $
                           bkg_duration = bkg_duration, subc_file = subc_file, subc_label = subc_label, $
                           pixel_data = pixel_data )
  
  
  pixel_data.counts[ph_list.subc_d_n - 1, ph_list.pixel_n]++
  
  ;todo: n.h. remove hack
  ;label as pixel data before ivs 
  pixel_data.type = "stx_raw_pixel_data"
  
  return, pixel_data
end

;+
; :description:
;    This internal routine verifies the validity of the input parameter
;    It uses typename() to perform the verification. For anonymous structures
;    a tag 'type' is assumed and that type is checked against the internal input
;    type.
;
; :params:
;    in is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'in' is valid, false otherwise
;-
function stx_module_detector_simulation::_verify_input, in
  compile_opt hidden
  
  if ~self->ppl_module::_verify_input(in) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    This internal routine verifies the validity of the configuration
;    parameter
;
; :params:
;    configuration is the input parameter to be verified
;
; :hidden:
;
; :returns: true if 'configuration' is valid, false otherwise
;-
function stx_module_detector_simulation::_verify_configuration, configuration
  compile_opt hidden
  
  if ~self->ppl_module::_verify_configuration(configuration) then return, 0
  
  ;do additional checking here
  return, 1
end

;+
; :description:
;    Cleanup of this class
;-
pro stx_module_detector_simulation::cleanup
  self->ppl_module::cleanup
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
pro stx_module_detector_simulation__define
  compile_opt idl2, hidden
  
  void = { stx_module_detector_simulation, $
           inherits ppl_module }
end
