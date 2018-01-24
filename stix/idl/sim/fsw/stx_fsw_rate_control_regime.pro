; -----------------------------------------------------------------------------
;+
; :description:
;      Rate Control Regime for STIX
;      The term "Rate Control Regime" (RCR) is used to describe the state of the attenuator
;      and the combination of pixels (if any) that have been disabled to control count rates.
;      The purpose of this algorithm is to determine whether a change to the RCR is merited
;      in order to  avoid excessive event rates that would otherwise be expected in solar flares.
;      This is accomplished by monitoring the live time accumulators and selected pixels
;      of the background detector.  If rates are too high or too low, then the attenuator
;      state is changed or selected pixels disabled.
;      There are two special cases the consider:
;      First the control of the background detector (which is not covered by the attenuator)
;      is governed by a separate algorithm, described elsewhere. This will be called
;      the "background" RCR (BRCR) as distinct from the "primary" RCR that refers to the other detectors.
;      Second, changing the attenuator from IN to OUT is a special case because it is based
;      on the validity of the expectation that this will increase count rates by an acceptable
;      amount, an expectation that depends on knowledge of the flux of low energy X-rays,
;      the very X=rays that the attenuator is blocking. For this reason, an additional
;      condition is used, based on the output, Rb, of the background detector, that depends
;      on the unattenuated low energy flux.
;
;      "primary" RCR values:
;      0 - attenuator out, all pixels
;      1 - attenuator in,  all pixels
;      2 - attenuator in,  4 large pixels
;      3 - attenuator in,  2 large pixels cycling
;      4 - attenuator in,  1 large pixel cycling
;      5 - attenuator in,  small pixels only
;      6 - attenuator in,  2 small pixels cycling
;      7 - attenuator in,  1 small pixel cycling
;
;
; :params:
;     Ai     : in, required, type="array of numbers"
;              contents of live time accumulator, i, in an integration time
;     Ab     : in, required, type="array of numbers"
;              current accumulation in an integration time in the background-detector-associated livetime accumulator.
;     RCR    : in/out, required, type=byte
;              the primary "Rate Control Regime" for the current accumulation.
;    BRCR    : in/out, required, type=byte
;              current background regime
;   skip_RCR : in/out, required, type=byte
;              if not 0 the algorithm bypass the current RCR check
;
;  :returns:
;     RCR    : in/out, type = "byte"
;              the next primary "Rate Control Regime"
;    BRCR    : in/out, type = "byte"
;              the next background regime
;   skip_RCR : in/out, type = "byte"
;              if not 0 then bypass next RCR check
;
;  :usage:
;  stx_sim_rate_control_regime, accumulator_values, background_detector_values, RCR=variable_with_RCR_value, BRCR=variable_with_BRCR_value, skip_RCR=bypass_variable
;
;  :history:
;     06-May-2014 - Marek Steslicki (Wro), initial release
;     12-Jan-2015 - Laszlo I. Etesi (FHNW), fixed a typo (boolean value was 1 should have been 0); input by Marek Steslicki
;     10-Feb-2016 - ECMD (Graz), Switched L2 and L3 to match description and recommended values
;                                Background RCR now using counts rather than triggers
;     10-May-2016 - Laszlo I. Etesi (FHNW), ensuring the returned RCR values are bytes
;     30-Jan-2017 - ECMD (Graz), Updated rate control algorithm in line with revised description in STIX-TN-0113-FHNW_I4R0
;     06-Mar-2017 - Laszlo I. Etesi (FHNW), changed RCR algorithm slightly, as the current implementation (which is in agreement with TN-0113)
;                                           seems to be faulty.
;     25-Apr-2017 - ECMD (Graz), Added condition to prevent RCR level being set to min_attenuator_level-1 if min_attenuator_level is 0                                    
;
;-
; -----------------------------------------------------------------------------
pro stx_fsw_rate_control_regime, ai, ab $
    , rcr_current = rcr_current $
    , rcr_previous = rcr_previous $
    , rcr_new = rcr_new $
    , attenuator_command = attenuator_command $
    , l0=l0 $
    , l1=l1 $
    , l2=l2 $
    , l3=l3 $
    , b0=b0 $
    , rcr_tbl_filename = rcr_tbl_filename $
    , rcr_max = rcr_max $
    , min_attenuator_level = min_attenuator_level
   
  ; thresholds:
 
  default, l0 , 2*10L^3; upper live time accumulator threshold for changing from c1 to c0 (viz, for removing attenuator)
  default, l1 , 2*10L^5; lower live time accumulator threshold for changing from c0 to c1 (viz, for inserting the attenuator
  default, l2 , 1*10L^5; lower live time accumulator threshold for lowering rcr by increasing the effective detector area.
  default, l3 , 2*10L^5; upper live time accumulator threshold for raising rcr by reducing the effective detector area
  default, b0 , 2*10L^3; upper limit on ab (from background detector) for removing attenuator
  default, rcr_current, 0 ;the rcr level that was in use for data accumulated during time interval,
  default, rcr_previous, 0 ;the rcr level that was in use for data accumulated during time interval,
  default, attenuator_command, [0,0]
  
  default, rcr_tbl_filename, concat_dir( getenv('STX_CONF'), 'rcr_states.csv' )
  rcr_struct = stx_fsw_rcr_table2struct(rcr_tbl_filename, rcr_max = rcr_max_tbl, min_attenuator_level = min_attenuator_level_tbl )
    
  default, min_attenuator_level, min_attenuator_level_tbl ;the minimum rcr level for which the attenuator is in
  default, rcr_max, rcr_max_tbl  ;the maximum allowable value of the rate control regime
  
  ;calculate median of the selected trigger accumulators 
  ;median is used to minimize sensitivity to noisy detectors
  a_med = median([ai])
  
  ;move the record of attenuator motion for the previous interval to the start of the array
  attenuator_command[0] = attenuator_command[-1]
    
  ; determine if an attenuator motion was commanded at the start of the current interval
   attenuator_command[-1] = ((rcr_current eq min_attenuator_level) and (rcr_previous eq min_attenuator_level - 1)) or $
     ((rcr_current eq min_attenuator_level - 1) and (rcr_previous eq min_attenuator_level)) ?  1b :  0b
    
  ; calculation of rate control regime
  case 1 of
  
    ;leave rcr unchanged if there was a change at the beginning of the current interval 
    ;(allows for the latency associated with the previous calculation)
    (rcr_current ne rcr_previous) : rcr_rec = rcr_current
    
    ;leave rcr unchanged if an attenuator change started at the beginning of the previous interval
    ;(allows for the latency associated with the attenuator motion)
    (attenuator_command[0]) : rcr_rec = rcr_current
    
    ;remove attenuator if both the median trigger rate and background detector trigger rate 
    ;are below their respective thresholds
    ((min_attenuator_level gt 0) and (rcr_previous eq min_attenuator_level ) and (a_med lt l0) and (ab lt b0) ) : rcr_rec = min_attenuator_level - 1
    
    ;insert attenuator if the median trigger rate is too high
    ((rcr_previous eq min_attenuator_level - 1) and (a_med gt l1)) : rcr_rec = min_attenuator_level
    
    ;if trigger rate is too low, reduce the rcr level, if possible, by increasing
    ;effective detector area. attenuator will not change
    ((rcr_previous gt min_attenuator_level) and (a_med lt l2) ) : rcr_rec = rcr_previous - 1
    
    ;if trigger rate is too high, increase rcr level, if possible, by decreasing effective
    ;detector area. attenuator will not change
    ((rcr_previous lt rcr_max) and (a_med gt l3)) : rcr_rec = rcr_previous + 1
    
  ;otherwise, no rcr change is recommended
  else : rcr_rec = rcr_previous
  
endcase

rcr_new = rcr_rec

; cast to byte
rcr_new = byte(rcr_new)

end

