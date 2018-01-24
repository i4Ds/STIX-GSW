;+
; :file_comments:
;    This module is part of the flight software (FSW) package and
;    determines the current rate control regime
;
; :categories:
;    flight software, rate control regime, quicklook accumulated data , module
;
; :examples:
;    obj = stx_fsw_module_rate_control_regime()
;
; :history:
;    27-jun-2014 - Nicky Hochmuth (FHNW), initial release
;    10-Feb-2016 - ECMD (Graz), Background RCR now using counts rather than triggers
;    10-May-2016 - Laszlo I. Etesi (FHNW), minor updates and updates to accomodate new structure types
;    01-Feb-2017 - ECMD (Graz), Updated to reflect changes in rcr routine - now using added previous_rcr and 
;                               attenuator_command keywords in rcr structure and b0 and rcr_tbl_filename in 
;                               configuration structure 
;    06-Mar-2017 - Laszlo I. Etesi (FHNW), bugfixing: now using proper output RCR value for "previous"
;
;-

;+
; :description:
;    This internal routine calibrates the accumulator data
;
; :params:
;    in : in, required, type="defined in 'factory function'"
;       ;
;    configuration : in, required, type="stx_configuration_manager"
;        this is the configuration manager object containing the
;        configuration parameters for this module
;
; :returns:
; {
;   RCR       : out, type = "byte"
;               the next primary "Rate Control Regime"
;   BRCR      : out, type = "byte"
;               the next background regime
;   skip_RCR  : out, type = "byte"   
;               if not 0 then bypass next RCR check
; }              
;   
;-
function stx_fsw_module_rate_control_regime::_execute, in, configuration
  compile_opt hidden
  
  conf = *configuration->get(module=self.module)
  
  rcr = in.rcr.rcr
  rcr_previous = in.rcr.previous_rcr
  attenuator_command  = in.rcr.attenuator_command 
  
stx_fsw_rate_control_regime, reform(in.live_time.accumulated_counts),  reform(total(in.live_time_bkgd.accumulated_counts,1)) $
    , rcr_current = rcr $
    , rcr_previous = rcr_previous $
    , rcr_new = rcr_new $
    , attenuator_command = attenuator_command $
    , l0 = conf.l0 $
    , l1 = conf.l1 $
    , l2 = conf.l2 $
    , l3 = conf.l3 $
    , b0 = conf.b0 $
    , rcr_tbl_filename = conf.rcr_tbl_filename 
 
  return, stx_fsw_m_rate_control_regime(rcr = rcr_new, previous_rcr = rcr, attenuator_command = attenuator_command) 
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
pro stx_fsw_module_rate_control_regime__define
  compile_opt idl2, hidden
  
  void = { stx_fsw_module_rate_control_regime, $
    inherits ppl_module }
end
