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
;   08-Feb-2016 - ECMD (Graz), thermal_krel and nonthermal_krel parameters replaced with thermal_krel_rise, nonthermal_krel_rise,
;                              thermal_krel_decay and nonthermal_krel_decay
;   08-Feb-2019 - ECMD (Graz), updated input parameters to match ICD
;                              input counts are no longer summed over detectors
;-
function stx_fsw_module_flare_detection::_execute, in, configuration
  compile_opt hidden

  conf = *configuration->get(module=self.module)

  self->update_io_data, conf

  nbl = conf.nbl
  cfmin = conf.cfmin
  kdk = conf.kdk
  krel_rise = conf.krel_rise
  krel_decay = conf.krel_decay
  kb = conf.kb

  context = isa(in.context,/array) ? in.context : !NULL

  ; extracting the ql counts for easier selection below
  ql_counts = reform(in.ql_counts.accumulated_counts)

  sz = size(ql_counts)
  ; failover, only accepting two or three entries in ql_counts
  if( sz[1] lt 2 || sz[1] gt 3) then message, 'stx_fsw_ql_flare_detection.accumulated_counts must have 2 or 3 elements.'

  ; due to the current framework setup, an energy axis in the QL definition file
  ; cannot have discontinuities (e.g. two energy ranges 6-12 and 25-50).
  ; the QL product for the flare detection can be generateed with two distinct ranges.
  ; to work around this issue, the QL product for the flare detection can be configured with three
  ; contiguous energy ranges, where the middle range is ignored and only the outer two are read and
  ; passed in to the flare detection

  ; generate time profile
  flare_flag = stx_fsw_flare_detection(reform(transpose([ql_counts[0,*],ql_counts[-1,*]]),1, sz[2], 2), in.background, in.rcr $
    , nbl = nbl $
    , kb = kb $
    , kdk = kdk $
    , krel_rise = krel_rise $
    , krel_decay = krel_decay $
    , cfmin = cfmin $
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

    (self.lut_data)["flare_intensity_lut"] = [[flare_intensity_lut.field1],[flare_intensity_lut.field2],[flare_intensity_lut.field3]]
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
