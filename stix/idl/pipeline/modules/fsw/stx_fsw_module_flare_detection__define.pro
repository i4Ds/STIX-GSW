;+
; :file_comments:
;    This module is part of the Flight Software Simulator Module (FSW) and
;    generates a flag for each accumulation bin whether a flare is in progress or not
;
; :categories:
;    Flight Software Simulator, module, flare flag
;
; :examples:
;    obj = stx_fsw_module_flare_detection()
;
; :history:
;    06-Jul-2014 - Nicky hochmuth (FHNW), initial release
;    06-Mar-2015 - Laszlo I. Etesi (FHNW), update execute, see comment below
;    10-May-2016 - Laszlo I. Etesi (FHNW), updated structure names
;-

;+
; :description:
;    This internal routine determines if a flare is in progress or not
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
;   30-Mar-2015 - Laszlo I. Etesi, added code to allow for non-contiguous energy ranges
;   08-Feb-2016 - ECMS (Graz), thermal_krel and nonthermal_krel parameters replaced with thermal_krel_rise, nonthermal_krel_rise, 
;                              thermal_krel_decay and nonthermal_krel_decay
;-
function stx_fsw_module_flare_detection::_execute, in, configuration
  compile_opt hidden

  conf = *configuration->get(module=self.module)

  self->update_io_data, conf

  nbl = conf.nbl
  thermal_cfmin = conf.thermal_cfmin
  nonthermal_cfmin = conf.nonthermal_cfmin
  thermal_kdk = conf.thermal_kdk
  nonthermal_kdk = conf.nonthermal_kdk
  thermal_krel_rise = conf.thermal_krel_rise 
  nonthermal_krel_rise = conf.nonthermal_krel_rise 
  thermal_krel_decay = conf.thermal_krel_decay 
  nonthermal_krel_decay = conf.nonthermal_krel_decay 
  kb = conf.kb

  context = isa(in.context,/array) ? in.context : !NULL

  ; extracting the ql counts for easier selection below
  ql_counts = reform(in.ql_counts.accumulated_counts)

  ; failover, only accepting two or three entries in ql_counts
  if(n_elements(ql_counts) lt 2 || n_elements(ql_counts) gt 3) then message, 'stx_fsw_ql_flare_detection.accumulated_counts must have 2 or 3 elements.'

  ; due to the current framework setup, an energy axis in the QL definition file
  ; cannot have discontinuities (e.g. two energy ranges 6-12 and 25-50).
  ; the QL product for the flare detection can be generateed with two distinct ranges.
  ; to work around this issue, the QL product for the flare detection can be configured with three
  ; contiguous energy ranges, where the middle range is ignored and only the outer two are read and
  ; passed in to the flare detection

  ; generate time profile
  flare_flag = stx_fsw_flare_detection(transpose([ql_counts[0],ql_counts[-1]]), in.background, in.rcr $
    , nbl = nbl $
    , kb = kb $
    , thermal_kdk = thermal_kdk $
    , nonthermal_kdk = nonthermal_kdk $
    , thermal_krel_rise = thermal_krel_rise $
    , nonthermal_krel_rise = nonthermal_krel_rise $
    , thermal_krel_decay = thermal_krel_decay $
    , nonthermal_krel_decay = nonthermal_krel_decay $
    , thermal_cfmin = thermal_cfmin $
    , nonthermal_cfmin = nonthermal_cfmin $
    , context = context $
    , flare_intensity_lut = (self.lut_data)["flare_intensity_lut"] $
    , int_time = in.int_time $
    , plotting = conf.plotting $
    )

  return, stx_fsw_m_flare_flag(flare_flag=flare_flag, context=context)
end

pro stx_fsw_module_flare_detection::update_io_data, conf


  if self->is_invalid_config("flare_intensity_lut_file", conf.flare_intensity_lut_file) then begin
    ;read the flare intensity LUT
    flare_intensity_lut = read_csv(exist(conf.flare_intensity_lut_file) ? conf.flare_intensity_lut_file : loc_file( 'stx_fsw_flare_intensity.csv', path = getenv('STX_CONF') ), n_table_header=1)

    (self.lut_data)["flare_intensity_lut"] = [[flare_intensity_lut.field1],[flare_intensity_lut.field2],[flare_intensity_lut.field3],[flare_intensity_lut.field4]]
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
pro stx_fsw_module_flare_detection__define
  compile_opt idl2, hidden

  void = { stx_fsw_module_flare_detection, $
    inherits ppl_module_lut }
end
